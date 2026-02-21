FROM node:18-bookworm AS base

WORKDIR /app

# hadolint ignore=DL3009
RUN --mount=type=cache,id=apt,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,id=apt,target=/var/apt/lists,sharing=locked \
    apt-get update && \
    apt-get install -y --no-upgrade --no-install-recommends tini

FROM base AS prod-deps

COPY --from=l3tnun/epgstation:v2.10.0 /app/package*.json .

RUN --mount=type=cache,id=prod-deps,target=~/.npm,sharing=locked \
    --mount=type=cache,id=prod-deps,target=./node_modules/.cache,sharing=locked \
    npm install --omit=dev --no-save --loglevel=info

# hadolint ignore=DL3006
FROM gcr.io/distroless/nodejs18-debian12

WORKDIR /app

COPY --from=base /usr/bin/dash /bin/sh
COPY --parents --from=base /usr/bin/tini /

COPY --parents --from=l3tnun/epgstation:v2.10.0 /app/api.yml /app/img /app/ormconfig.js /app/package.json /app/dist /app/client/dist /

COPY --parents --from=prod-deps /app/node_modules /

RUN --mount=type=bind,from=busybox:1.35.0-glibc,source=/bin,target=/bin \
    addgroup -g 44 video && \
    mkdir -p drop config recorded thumbnail data/key data/streamfiles logs/EPGUpdater logs/Operator logs/Service

LABEL maintainer="fetburner"

EXPOSE 8888

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/nodejs/bin/node", "/app/dist/index.js"]
