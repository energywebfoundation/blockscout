FROM bitwalker/alpine-elixir-phoenix:1.10.3

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
ARG MIX_ENV

ARG MIX_ENV=dev
ENV MIX_ENV=$MIX_ENV
ENV PORT=4000 \
    BLOCKSCOUT_VERSION="v3.3.3-beta" \
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
    SECRET_KEY_BASE="RMgI4C1HSkxsEjdhtGMfwAHfyT6CKWXOgzCboJflfSm4jeAlic52io05KB6mqzc5" \
    ENABLE_TX_STATS=false \
    SHOW_PRICE_CHART=true \
    SHOW_TXS_CHART=false \
    HISTORY_FETCH_INTERVAL=60 \
    TXS_HISTORIAN_INIT_LAG=0 \
    TXS_STATS_DAYS_TO_COMPILE_AT_INIT=365 \
    COIN_BALANCE_HISTORY_DAYS=10

# Cache elixir deps
ADD mix.exs mix.lock ./
ADD apps/block_scout_web/mix.exs ./apps/block_scout_web/
ADD apps/explorer/mix.exs ./apps/explorer/
ADD apps/ethereum_jsonrpc/mix.exs ./apps/ethereum_jsonrpc/
ADD apps/indexer/mix.exs ./apps/indexer/

RUN mix do local.hex --force, deps.get, local.rebar --force, deps.compile, compile

ADD . .

ARG COIN
RUN if [ "$COIN" != "" ]; then sed -i s/"POA"/"${COIN}"/g apps/block_scout_web/priv/gettext/en/LC_MESSAGES/default.po; fi

# Run forderground build and phoenix digest
RUN mix compile

# Add blockscout npm deps
RUN cd apps/block_scout_web/assets/ && \
    npm install && \
    npm run deploy && \
    cd -

RUN cd apps/explorer/ && \
    npm install && \
    apk update && apk del --force-broken-world alpine-sdk gmp-dev automake libtool inotify-tools autoconf python

# RUN mix do ecto.drop --force, ecto.create, ecto.migrate


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

#CMD ["mix", "phx.server"]