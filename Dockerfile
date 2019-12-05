FROM elixir:1.9.1-alpine

MAINTAINER TSH DEVOPS <devops@tsh.io>

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
# ONBUILD RUN mix do local.hex --force, local.rebar --force
ENV PATH=./node_modules/.bin:$PATH

WORKDIR /opt/app
EXPOSE 4000
ENV PORT=4000 \
    MIX_ENV="prod" \
    SECRET_KEY_BASE="RMgI4C1HSkxsEjdhtGMfwAHfyT6CKWXOgzCboJflfSm4jeAlic52io05KB6mqzc5"
# Cache elixir deps
ADD mix.exs mix.lock ./
ADD apps/block_scout_web/mix.exs ./apps/block_scout_web/
ADD apps/explorer/mix.exs ./apps/explorer/
ADD apps/ethereum_jsonrpc/mix.exs ./apps/ethereum_jsonrpc/
ADD apps/indexer/mix.exs ./apps/indexer/

RUN mix do local.hex --force, local.rebar --force, deps.get, deps.compile

ADD . .
RUN mix compile && \
    mix phx.digest

# Add blockscout npm deps
RUN cd apps/block_scout_web/assets/ && \
    npm install && \
    npm run deploy && \
    cd -

RUN cd apps/explorer/ && \
    npm install && \
    apk update && apk del --force-broken-world alpine-sdk gmp-dev automake libtool inotify-tools autoconf python



# RUN mix do ecto.drop --force, ecto.create, ecto.migrate

# CMD ["mix", "phx.server"]
