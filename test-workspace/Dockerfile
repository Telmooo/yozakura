# Yozakura - Dockerfile example
# These files are all gibberish, do not attempt to run them
FROM node:22-alpine AS base

# Environment variables
ENV NODE_ENV=${NODE_ENV} \
    PORT=${APP_PORT} \
    PNPM_HOME="/pnpm" \
    PATH="$PNPM_HOME:$PATH" \
    # Prevents interactive prompts during apt install
    DEBIAN_FRONTEND=noninteractive \
    # Node.js tuning
    NODE_OPTIONS="--max-old-space-size=2048" \
    NPM_CONFIG_LOGLEVEL=warn

# Install packages
RUN apk add --no-cache \
        curl \
        tini \
        tzdata \
    && cp /usr/share/zoneinfo/Region/Subregion /etc/localtime \
    && echo "Region/Subregion" > /etc/timezone \
    && apk del tzdata

# Enable corepack / pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

COPY . .

RUN pnpm run build

# Healthcheck
HEALTHCHECK \
    --interval=30s \
    --timeout=10s \
    --start-period=15s \
    --retries=3 \
    CMD curl -f http://localhost:${PORT}/api/health || exit 1

EXPOSE ${APP_PORT}

RUN mkdir -p /app/logs /app/uploads /tmp/app \
    && chown -R ${APP_USER}:${APP_USER} /app/logs /app/uploads /tmp/app

USER ${APP_USER}

CMD ["node", "server.js"]
