# syntax=docker/dockerfile:1

# As versões de Elixir e OTP são explícitas para manter CI e imagem alinhadas.
ARG ELIXIR_VERSION=1.20.4
ARG OTP_VERSION=29

FROM elixir:${ELIXIR_VERSION}-otp-${OTP_VERSION}-slim AS build

ENV MIX_ENV=prod
WORKDIR /app

RUN apt-get update \
    && apt-get install --yes --no-install-recommends build-essential ca-certificates git \
    && rm -rf /var/lib/apt/lists/* \
    && mix local.hex --force \
    && mix local.rebar --force

# Copia os manifestos antes do código para preservar o cache de dependências.
COPY mix.* ./
RUN mix deps.get --only prod
RUN mix deps.compile

COPY . .

RUN mix compile \
    && mix release

# A mesma imagem-base evita incompatibilidade de glibc/OpenSSL entre o ambiente
# que gera o release e o runtime do OTP. Ela é maior que Debian puro, mas torna
# o experimento previsível enquanto a base oficial do Erlang evolui.
FROM elixir:${ELIXIR_VERSION}-otp-${OTP_VERSION}-slim AS runtime

# The release must trust public certificate authorities for outbound HTTPS
# requests to OpenRouter and Formspree.
RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV HOME=/app \
    LANG=C.UTF-8 \
    PHX_SERVER=true

WORKDIR /app
COPY --from=build --chown=nobody:nogroup /app/_build/prod/rel/relay ./

USER nobody
EXPOSE 4000

CMD ["bin/relay", "start"]
