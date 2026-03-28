#!/usr/bin/env fish
# Yozakura - Fish example
# These files are all gibberish, do not attempt to run them

#  Variables
set app_name    "yozakura"
set version     "1.0.0"
set max_retries 3
set is_debug    false

# Universal (persistent) variable
set -U yozakura_theme dark

# Exported variable
set -x NODE_ENV production

# Scoped variable
set -l local_var "only in this scope"

# List variable
set languages JavaScript TypeScript Python Rust Go Java "C++"
set colors "#c792ea" "#82aaff" "#c3e88d" "#f78c6c" "#ffcb6b"

#  String Expansion
echo "App: $app_name v$version"
echo "Languages: $languages"           # prints all elements
echo "First: $languages[1]"            # 1-indexed
echo "Last: $languages[-1]"
echo "Slice: $languages[2..4]"
echo "Count: "(count $languages)

#  Command Substitution
set current_dir (pwd)
set file_count  (ls | count)
set git_branch  (git rev-parse --abbrev-ref HEAD 2>/dev/null; or echo "not a repo")
set timestamp   (date "+%Y-%m-%dT%H:%M:%S")

#  Functions
function log
    set level $argv[1]
    set message $argv[2..]
    set ts (date "+%H:%M:%S")

    switch $level
        case info
            set_color blue
            echo -n "[$ts] INFO  "
        case warn
            set_color yellow
            echo -n "[$ts] WARN  "
        case error
            set_color red
            echo -n "[$ts] ERROR "
        case debug
            set_color cyan
            echo -n "[$ts] DEBUG "
        case '*'
            echo -n "[$ts] $level "
    end

    set_color normal
    echo $message
end

# Function with flags (argparse)
function deploy
    argparse \
        'h/help' \
        'e/env=' \
        'v/verbose' \
        'n/dry-run' \
        -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: deploy [-e ENV] [-v] [-n]"
        return 0
    end

    set env    (set -q _flag_env;     and echo $_flag_env;     or echo "staging")
    set verbose (set -q _flag_verbose; and echo true;           or echo false)
    set dry_run (set -q _flag_dry_run; and echo true;           or echo false)

    log info "Deploying to $env (dry-run: $dry_run)"

    if test $dry_run = true
        log warn "Dry run - no changes made"
        return 0
    end

    # Actual deploy steps
    log info "Building..."
    and log info "Running tests..."
    and log info "Deploying..."
    and log info "Done."
end

# Recursive function
function factorial
    set n $argv[1]
    if test $n -le 1
        echo 1
    else
        set sub (factorial (math $n - 1))
        math $n \* $sub
    end
end

# Function returning multiple values via list
function split_path
    set full_path $argv[1]
    set dir  (dirname $full_path)
    set base (basename $full_path)
    set ext  (string match -r '\.[^.]+$' -- $base; or echo "")
    echo $dir $base $ext
end

#  Control Flow
function demo_control_flow
    set value 42

    # if / else if / else
    if test $value -lt 0
        echo "negative"
    else if test $value -eq 0
        echo "zero"
    else if test $value -lt 100
        echo "small positive: $value"
    else
        echo "large: $value"
    end

    # String tests
    set name "yozakura"
    if string match -q "yoza*" -- $name
        echo "starts with yoza"
    end

    if test -f ~/.config/fish/config.fish
        log info "fish config found"
    end

    # switch
    set ext "ts"
    switch $ext
        case js mjs cjs
            echo "JavaScript"
        case ts tsx
            echo "TypeScript"
        case py
            echo "Python"
        case rs
            echo "Rust"
        case go
            echo "Go"
        case '*'
            echo "Unknown: $ext"
    end
end

#  Loops
function demo_loops
    # for-in
    for lang in $languages
        echo "  lang: $lang"
    end

    # for-in with range
    for i in (seq 1 5)
        echo "  i=$i"
    end

    # for-in with step
    for n in (seq 0 2 10)
        echo "  even: $n"
    end

    # while
    set count 0
    while test $count -lt 3
        echo "  count: $count"
        set count (math $count + 1)
    end

    # break / continue
    for i in (seq 1 10)
        if test $i -eq 3
            continue
        end
        if test $i -eq 7
            break
        end
        echo "  $i"
    end
end

#  String Operations
function demo_strings
    set str "Hello, World! Hello, Fish!"

    # Length
    echo "Length: "(string length -- $str)

    # Upper/lower
    echo "Upper: "(string upper -- $str)
    echo "Lower: "(string lower -- $str)

    # Replace
    echo "Replace: "(string replace -- "Hello" "Hi" $str)
    echo "Replace all: "(string replace -a -- "Hello" "Hi" $str)

    # Split
    set parts (string split -- ", " $str)
    for part in $parts
        echo "  part: $part"
    end

    # Match (regex)
    set emails "user@example.com and admin@site.org"
    string match -ra '[a-z]+@[a-z]+\.[a-z]+' -- $emails

    # Trim
    set padded "   trimmed   "
    echo "Trimmed: '"(string trim -- $padded)"'"
    echo "Left:    '"(string trim --left -- $padded)"'"
    echo "Right:   '"(string trim --right -- $padded)"'"

    # Pad
    echo "Padded right: '"(string pad --width 20 -- "hello")"'"
    echo "Padded left:  '"(string pad --width 20 --right -- "hello")"'"

    # Repeat
    echo (string repeat --count 3 -- "ab")

    # Contains
    if string match -q '*World*' -- $str
        echo "Contains 'World'"
    end
end

#  Math
function demo_math
    echo (math 1 + 2)
    echo (math 10 / 3)
    echo (math "10 % 3")
    echo (math "2 ^ 10")
    echo (math --scale=4 "pi * 5^2")
    echo (math "floor(3.7)")
    echo (math "ceil(3.2)")
    echo (math "round(3.5)")
    echo (math "abs(-42)")
    echo (math "sqrt(144)")
    echo (math "log(e)")
    echo (math "sin(pi / 2)")
end

#  Piping & Redirection
function demo_pipes
    # Basic pipe
    echo "one two three" | string split " " | sort

    # Multiple pipes
    cat /etc/passwd 2>/dev/null \
        | string match -r '^[^:]+' \
        | sort \
        | head -5

    # Process substitution
    diff (echo "a\nb\nc" | psub) (echo "a\nB\nc" | psub)

    # stderr redirection
    command_that_might_fail 2>/dev/null
    or log warn "command failed (ignored)"
end

#  Events
function on_variable_set --on-variable fish_greeting
    log debug "fish_greeting was changed"
end

function on_job_exit --on-job-exit %last
    log debug "Last background job exited"
end

#  Completions (would go in completions/yozakura.fish)
function demo_completions
    # This shows how completions are structured
    complete -c deploy -s e -l env -d "Target environment" -r -a "staging production"
    complete -c deploy -s v -l verbose -d "Enable verbose output"
    complete -c deploy -s n -l dry-run -d "Dry run (no changes)"
    complete -c deploy -s h -l help -d "Show help"
end

#  Configuration
# These would typically be in ~/.config/fish/config.fish
function fish_greeting
    log info "Welcome to fish, $USER!"
    echo "Today: "(date "+%A, %B %d %Y")
end

function fish_prompt
    set last_status $status
    set branch (git rev-parse --abbrev-ref HEAD 2>/dev/null)

    set_color purple
    echo -n (whoami)
    set_color normal
    echo -n "@"
    set_color blue
    echo -n (hostname -s)
    set_color normal
    echo -n ":"
    set_color green
    echo -n (prompt_pwd)

    if test -n "$branch"
        set_color yellow
        echo -n " ($branch)"
    end

    if test $last_status -ne 0
        set_color red
        echo -n " [$last_status]"
    end

    set_color normal
    echo -n "> "
end

#  Main
function main
    log info "Starting $app_name v$version"

    demo_control_flow
    demo_loops
    demo_strings
    demo_math

    set result (factorial 10)
    log info "10! = $result"

    for lang in $languages
        set -l upper (string upper -- $lang)
        echo "  $upper"
    end
end

# Only run main if executed directly (not sourced)
if status is-login
    or status --is-interactive
    main
end
