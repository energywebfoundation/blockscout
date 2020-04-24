FROM elixir:1.9.1-alpine

LABEL MAINTAINER="TSH DEVOPS <devops@tsh.io>"

RUN apk --no-cache --update add alpine-sdk gmp-dev automake libtool inotify-tools autoconf python git

RUN \
    mkdir -p /opt/app && \
    chmod -R 777 /opt/app && \
    apk update && \
    apk --no-cache --update add \
      make \
      g++ \
      wget \
      curl \
      inotify-tools \
      nodejs \
      nodejs-npm && \
    npm install npm -g --no-progress && \
    update-ca-certificates --fresh && \
    rm -rf /var/cache/apk/*
ENV PATH=./node_modules/.bin:$PATH

WORKDIR /opt/app
EXPOSE 4000
ENV PORT=4000 \
    BLOCKSCOUT_VERSION="v3.1.1-beta" \
    NETWORK="Energy Web Foundation" \
    SUBNETWORK="Example network" \
    COIN=VT \
    COIN_DISPLAY_SYMBOL=VT \
    ETHEREUM_JSONRPC_HTTP_URL="http://parity:8545" \
    ETHEREUM_JSONRPC_TRACE_URL="http://parity:8545" \
    ETHEREUM_JSONRPC_WS_URL="ws://parity:8546" \
    LOGO="/images/ewf_logo.svg" \
    ETHEREUM_JSONRPC_VARIANT=parity \
    LINK_TO_OTHER_EXPLORERS="false" \
    BLOCKSCOUT_PROTOCOL=https \
    BLOCKSCOUT_HOST=example.com \
    VALIDATORS_CONTRACT="" \
    SHOW_ADDRESS_MARKETCAP_PERCENTAGE=false \
    API_URL="https://example.com" \
    WEBAPP_URL="https://example.com" \
    SUPPORTED_CHAINS="" \
    DATABASE_URL="postgresql://postgres:secretpassword@localhost:5432/explorer_dev" \
    SECRET_KEY_BASE="RMgI4C1HSkxsEjdhtGMfwAHfyT6CKWXOgzCboJflfSm4jeAlic52io05KB6mqzc5"

ADD . .

RUN mix do local.hex --force, deps.get, local.rebar --force, deps.compile, compile

# Add blockscout npm deps
RUN cd apps/block_scout_web/assets && \
    npm install && \
    node_modules/webpack/bin/webpack.js --mode production

RUN cd apps/explorer/ && \
    npm install

# Dummy cert
RUN cd apps/block_scout_web && \
    mix phx.gen.cert blockscout blockscout.local

# Build static assets for deployment
RUN mix phx.digest

CMD ["mix", "phx.server"]
