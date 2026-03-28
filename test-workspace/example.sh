#!/usr/bin/env bash
# Yozakura - Shell example
# These files are all gibberish, do not attempt to run them
set -euo pipefail
IFS=$'\n\t'

#  Constants & Variables 
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"
readonly VERSION="1.0.0"
readonly LOG_LEVEL="${LOG_LEVEL:-info}"

APP_NAME="yozakura"
declare -i MAX_RETRIES=3
declare -a SUPPORTED_LANGS=("js" "ts" "py" "rs" "go" "java" "cpp")
declare -A COLOR_MAP=(
  ["keyword"]="#c792ea"
  ["function"]="#82aaff"
  ["string"]="#c3e88d"
  ["number"]="#f78c6c"
)

#  Colors for output 
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

#  Logging 
log() {
  local level="$1"; shift
  local message="$*"
  local timestamp
  timestamp="$(date '+%Y-%m-%dT%H:%M:%S')"

  case "$level" in
    info)  echo -e "${BLUE}[${timestamp}] INFO${NC}  ${message}" ;;
    warn)  echo -e "${YELLOW}[${timestamp}] WARN${NC}  ${message}" >&2 ;;
    error) echo -e "${RED}[${timestamp}] ERROR${NC} ${message}" >&2 ;;
    debug)
      [[ "${LOG_LEVEL}" == "debug" ]] && \
        echo -e "${CYAN}[${timestamp}] DEBUG${NC} ${message}"
      ;;
  esac
}

info()  { log info  "$@"; }
warn()  { log warn  "$@"; }
error() { log error "$@"; }
debug() { log debug "$@"; }

#  Error Handling & Traps 
cleanup() {
  local exit_code=$?
  debug "Cleanup called with exit code: ${exit_code}"
  # Remove temp files
  [[ -d "${TMPDIR:-/tmp}/yozakura-$$" ]] && rm -rf "${TMPDIR:-/tmp}/yozakura-$$"
  exit "$exit_code"
}

handle_error() {
  local exit_code=$?
  local line_number=${1:-$LINENO}
  error "Error on line ${line_number}: exit code ${exit_code}"
}

trap 'cleanup' EXIT
trap 'handle_error $LINENO' ERR
trap 'warn "Interrupted by user"; exit 130' INT TERM

#  Functions 
usage() {
  cat <<EOF
${BOLD}Usage:${NC} ${SCRIPT_NAME} [OPTIONS] <command>

${BOLD}Commands:${NC}
  build     Build the project
  test      Run tests
  deploy    Deploy to environment

${BOLD}Options:${NC}
  -e, --env ENV     Target environment (default: staging)
  -v, --verbose     Enable verbose output
  -h, --help        Show this help message
  --version         Show version

${BOLD}Examples:${NC}
  ${SCRIPT_NAME} build
  ${SCRIPT_NAME} --env production deploy
  ${SCRIPT_NAME} -v test
EOF
}

version() {
  echo "${APP_NAME} v${VERSION}"
}

# Function with default parameters and local variables
setup_environment() {
  local env="${1:-staging}"
  local verbose="${2:-false}"
  local config_file="${SCRIPT_DIR}/config/${env}.env"

  debug "Setting up environment: ${env}"

  if [[ ! -f "${config_file}" ]]; then
    warn "Config file not found: ${config_file}, using defaults"
    return 0
  fi

  # Source environment file
  # shellcheck source=/dev/null
  source "${config_file}"

  if [[ "${verbose}" == "true" ]]; then
    info "Environment '${env}' loaded from ${config_file}"
  fi
}

# Function with return value via echo
get_timestamp() {
  date '+%Y%m%d_%H%M%S'
}

# Recursive function
factorial() {
  local n="${1:?factorial requires an argument}"
  if (( n <= 1 )); then
    echo 1
  else
    local sub
    sub=$(factorial $(( n - 1 )))
    echo $(( n * sub ))
  fi
}

#  String Operations 
string_demos() {
  local str="Hello, World!"

  # Length
  echo "Length: ${#str}"

  # Substring
  echo "Substring: ${str:7:5}"

  # Uppercase / lowercase
  echo "Upper: ${str^^}"
  echo "Lower: ${str,,}"

  # Replace
  echo "Replace: ${str/World/Yozakura}"
  echo "Replace all: ${str//l/L}"

  # Trim prefix/suffix
  local path="/usr/local/bin/bash"
  echo "No prefix: ${path#*/}"
  echo "No long prefix: ${path##*/}"
  echo "No suffix: ${path%/*}"
  echo "No long suffix: ${path%%/*}"

  # Default values
  local unset_var
  echo "Default: ${unset_var:-default_value}"
  echo "Assign if unset: ${unset_var:=assigned}"
  echo "Error if unset: ${str:?variable must be set}"
}

#  Arrays 
array_demos() {
  # Indexed array
  local -a fruits=("apple" "banana" "cherry" "date" "elderberry")

  echo "All: ${fruits[*]}"
  echo "First: ${fruits[0]}"
  echo "Last: ${fruits[-1]}"
  echo "Length: ${#fruits[@]}"
  echo "Slice: ${fruits[@]:1:3}"

  # Append & delete
  fruits+=("fig")
  unset 'fruits[2]'

  # Iterate
  for fruit in "${fruits[@]}"; do
    echo "  - ${fruit}"
  done

  # Associative array
  declare -A capitals=(
    ["portugal"]="Lisbon"
    ["spain"]="Madrid"
    ["france"]="Paris"
  )

  for country in "${!capitals[@]}"; do
    echo "${country}: ${capitals[$country]}"
  done
}

#  Control Flow 
control_flow() {
  local value=42

  # if / elif / else
  if (( value < 0 )); then
    echo "negative"
  elif (( value == 0 )); then
    echo "zero"
  elif (( value < 100 )); then
    echo "small positive"
  else
    echo "large positive"
  fi

  # String comparisons
  local name="yozakura"
  if [[ "${name}" == "yozakura" ]]; then
    echo "Correct name"
  elif [[ "${name}" =~ ^y[a-z]+$ ]]; then
    echo "Starts with y"
  fi

  # File tests
  if [[ -f "${SCRIPT_DIR}/package.json" ]]; then
    info "package.json found"
  elif [[ -d "${SCRIPT_DIR}" ]]; then
    info "Script dir exists"
  fi

  # Case statement
  local ext="ts"
  case "${ext}" in
    js|mjs|cjs) echo "JavaScript" ;;
    ts|tsx)     echo "TypeScript" ;;
    py)         echo "Python" ;;
    rs)         echo "Rust" ;;
    go)         echo "Go" ;;
    *)          echo "Unknown: ${ext}" ;;
  esac
}

#  Loops 
loop_demos() {
  # C-style for loop
  for (( i = 0; i < 5; i++ )); do
    printf "  i=%d\n" "$i"
  done

  # For-in with brace expansion
  for n in {1..5}; do
    echo "  n=${n}"
  done

  # For-in with seq
  for n in $(seq 0 2 10); do
    echo "  even=${n}"
  done

  # While loop
  local count=0
  while (( count < 3 )); do
    echo "  count=${count}"
    (( count++ ))
  done

  # Until loop
  local x=10
  until (( x <= 0 )); do
    echo "  x=${x}"
    (( x -= 3 ))
  done

  # Loop control
  for i in {1..10}; do
    (( i == 3 )) && continue
    (( i == 7 )) && break
    echo "  ${i}"
  done

  # Read lines from file / heredoc
  while IFS=',' read -r lang typing gc; do
    printf "  %-15s %-10s %s\n" "$lang" "$typing" "$gc"
  done <<'EOF'
JavaScript,Dynamic,Yes
TypeScript,Static,Yes
Rust,Static,No
Go,Static,Yes
EOF
}

#  Process Substitution & Command Substitution 
advanced_demos() {
  # Command substitution
  local current_date
  current_date="$(date '+%Y-%m-%d')"
  local file_count
  file_count="$(find "${SCRIPT_DIR}" -name "*.json" | wc -l | tr -d ' ')"

  # Arithmetic
  local a=15 b=7
  echo "Sum: $(( a + b ))"
  echo "Div: $(( a / b ))"
  echo "Mod: $(( a % b ))"
  echo "Pow: $(( a ** 2 ))"

  # Process substitution
  diff <(echo "line1"; echo "line2") <(echo "line1"; echo "line3") || true

  # Piping & redirection
  echo "one two three" | tr ' ' '\n' | sort | while read -r word; do
    echo "  word: ${word}"
  done

  # Here-string
  grep -c "o" <<< "hello world foobar"

  # Subshell
  local outer="parent"
  (
    local inner="child"
    echo "In subshell: outer=${outer}, inner=${inner}"
  )
  # inner is not accessible here
}

#  getopts Argument Parsing 
parse_args() {
  local env="staging"
  local verbose=false
  local -a args=()

  while getopts ":e:vh-:" opt; do
    case "${opt}" in
      e) env="${OPTARG}" ;;
      v) verbose=true ;;
      h) usage; exit 0 ;;
      -)
        case "${OPTARG}" in
          env=*)   env="${OPTARG#*=}" ;;
          verbose) verbose=true ;;
          help)    usage; exit 0 ;;
          version) version; exit 0 ;;
          *)       error "Unknown option: --${OPTARG}"; exit 1 ;;
        esac
        ;;
      :) error "Option -${OPTARG} requires an argument"; exit 1 ;;
      \?) error "Invalid option: -${OPTARG}"; exit 1 ;;
    esac
  done

  shift $(( OPTIND - 1 ))
  args=("$@")

  echo "env=${env} verbose=${verbose} args=${args[*]:-none}"
}

#  Main Entry Point 
main() {
  info "Starting ${APP_NAME} v${VERSION}"

  local command="${1:-help}"
  shift || true

  case "${command}" in
    build)
      info "Building..."
      setup_environment "${1:-staging}"
      ;;
    test)
      info "Running tests..."
      for lang in "${SUPPORTED_LANGS[@]}"; do
        debug "Testing: ${lang}"
      done
      ;;
    demo)
      string_demos
      array_demos
      control_flow
      loop_demos
      advanced_demos
      ;;
    help|--help|-h)
      usage
      ;;
    version|--version)
      version
      ;;
    *)
      error "Unknown command: ${command}"
      usage
      exit 1
      ;;
  esac
}

main "$@"
