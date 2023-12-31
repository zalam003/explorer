FROM bitwalker/alpine-elixir-phoenix:1.14 AS builder

WORKDIR /app

ENV MIX_ENV="prod"

RUN apk --no-cache --update add alpine-sdk gmp-dev automake libtool inotify-tools autoconf python3 file libstdc++ curl ca-certificates

# Defaults
ENV DISABLE_INDEXER=false
ENV DISABLE_WEBAPP=false
ENV API_V1_READ_METHODS_DISABLED=false
ENV API_V1_WRITE_METHODS_DISABLED=false

# Change via ENV variables
ENV DISABLE_EXCHANGE_RATES=false
# coin_gecko, coin_market_cap
ENV EXCHANGE_RATES_MARKET_CAP_SOURCE=coin_gecko
# crypto_compare, coin_gecko and coin_market_cap
ENV EXCHANGE_RATES_PRICE_SOURCE=coin_gecko
# EXCHANGE_RATES_COINGECKO_API_KEY=
# EXCHANGE_RATES_COINMARKETCAP_API_KEY=

# wobserver interface
ARG WOBSERVER_ENABLED=false

ARG CACHE_EXCHANGE_RATES_PERIOD
ARG CACHE_TOTAL_GAS_USAGE_COUNTER_ENABLED
ARG ADMIN_PANEL_ENABLED
ARG CACHE_ADDRESS_WITH_BALANCES_UPDATE_INTERVAL
ARG SESSION_COOKIE_DOMAIN
ARG MIXPANEL_TOKEN
ARG MIXPANEL_URL
ARG AMPLITUDE_API_KEY
ARG AMPLITUDE_URL

# Energi Specific
ARG BLOCKSCOUT_PROTOCOL=https
ARG BLOCK_TRANSFORMER=base
#ARG GAS_PRICE=11
ARG ETHEREUM_JSONRPC_TRANSPORT=http
ARG COIN=NRG
ARG ENABLE_TXS_STATS=true
ARG SHOW_TXS_CHART=true
ARG ALLOWED_EVM_VERSIONS=petersburg
ARG ETHEREUM_JSONRPC_VARIANT=geth
ARG COINGECKO_COIN_ID=energi
ARG EXCHANGE_RATES_COINGECKO_COIN_ID=energi
# ARG EXCHANGE_RATES_COINMARKETCAP_COIN_ID=energi
ARG EMISSION_FORMAT=MNRG
ARG MAX_SKIPPING_DISTANCE=2
ARG CHECK_ORIGIN=true
ARG LOGO=/images/EnergiLogoLight.png
ARG LOGO_FOOTER=/images/EnergiLogoLight.png
ARG RELEASE_LINK=https://github.com/energicryptocurrency/energi3-blockscout

# Cache elixir deps
ADD mix.exs mix.lock ./
ADD apps/block_scout_web/mix.exs ./apps/block_scout_web/
ADD apps/explorer/mix.exs ./apps/explorer/
ADD apps/ethereum_jsonrpc/mix.exs ./apps/ethereum_jsonrpc/
ADD apps/indexer/mix.exs ./apps/indexer/

ENV MIX_HOME=/opt/mix
RUN mix local.hex --force
RUN mix do deps.get, local.rebar --force, deps.compile

ADD apps ./apps
ADD config ./config
ADD rel ./rel
ADD *.exs ./

# create directory
RUN if [[ ! -d apps/block_scout_web/priv/static ]]; then mkdir -p apps/block_scout_web/priv/static; fi
RUN if [[ ! -d apps/ethereum_jsonrpc/priv/static ]]; then mkdir -p apps/ethereum_jsonrpc/priv/static; fi
RUN if [[ ! -d apps/explorer/priv/static ]]; then mkdir -p apps/explorer/priv/static; fi
RUN if [[ ! -d apps/indexer/priv/static ]]; then mkdir -p apps/indexer/priv/static; fi

RUN apk add --update nodejs-current npm
# Upgrade to nodejs 18.x
RUN apk add nodejs-current

# Run build and phoenix digest
RUN mix compile

# Add npm deps
RUN npm install npm@9
RUN cd apps/block_scout_web/assets/ && \
        npm install && \
        npm run deploy && \
    cd /app/apps/explorer/ && \
        npm install

# Build secp256k1 package
RUN export "CFLAGS=-I/usr/local/include -L/usr/local/lib" && \
    cd deps/ex_secp256k1 && \
    mix deps.get && \
    mix compile

# Remove dev packages
RUN apk update && apk del --force-broken-world alpine-sdk make gcc gmp-dev automake libtool inotify-tools autoconf python3
RUN rm -rf /opt/hex
RUN rm -rf /var/cache/apk/*

RUN mix phx.digest

# RUN mkdir -p /opt/release \
#   && mix release blockscout \
#   && mv _build/${MIX_ENV}/rel/blockscout /opt/release

##############################################################
# FROM bitwalker/alpine-elixir-phoenix:1.14

# ARG RELEASE_VERSION
# ENV RELEASE_VERSION=${RELEASE_VERSION}
# ARG BLOCKSCOUT_VERSION
# ENV BLOCKSCOUT_VERSION=${BLOCKSCOUT_VERSION}

# RUN apk --no-cache --update add jq curl

# WORKDIR /app

# COPY --from=builder /opt/release/blockscout .
# COPY --from=builder /app/apps/explorer/node_modules ./node_modules
# COPY --from=builder /app/config/config_helper.exs ./config/config_helper.exs
# COPY --from=builder /app/config/config_helper.exs /app/releases/${RELEASE_VERSION}/config_helper.exs
