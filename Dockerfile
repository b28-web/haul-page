# Dockerfile for haul-page Phoenix release
# Version pins — keep in sync with mise.toml and .github/workflows/ci.yml
ARG ELIXIR_VERSION=1.19.3
ARG OTP_VERSION=28.4
ARG DEBIAN_VERSION=bookworm-20260223-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

# ==============================================================================
# Stage 1: deps — fetch and compile dependencies
# ==============================================================================
FROM ${BUILDER_IMAGE} AS deps

RUN apt-get update -y && \
    apt-get install -y build-essential git && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
COPY config/config.exs config/prod.exs config/

RUN mix deps.get --only prod && \
    mix deps.compile

# ==============================================================================
# Stage 2: build — compile app, build assets, create release
# ==============================================================================
FROM deps AS build

COPY lib lib
COPY priv priv
COPY assets assets
COPY config/runtime.exs config/
COPY rel rel

# Compile application first (generates colocated hooks for esbuild)
RUN mix compile

# Build assets (fetches tailwind + esbuild standalone binaries, then runs them)
RUN mix assets.deploy

# Create release (strip_beams: true is the default)
RUN mix release

# ==============================================================================
# Stage 3: runtime — minimal image with just the release
# ==============================================================================
FROM ${RUNNER_IMAGE} AS runtime

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
      libstdc++6 openssl libncurses5 locales ca-certificates && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR /app

# Only copy the release from the build stage
COPY --from=build /app/_build/prod/rel/haul ./

# Ensure scripts are executable
RUN chmod +x bin/migrate bin/server bin/migrate_and_start

# Default environment for Phoenix server
ENV PHX_SERVER=true

CMD ["bin/migrate_and_start"]
