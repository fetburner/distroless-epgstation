ARG NODE_VERSION
ARG DEBIAN_VERSION
ARG BUSYBOX_VERSION
ARG EPGSTATION_VERSION
ARG DEBIAN_VERSION_NUMBER

FROM busybox:${BUSYBOX_VERSION} AS busybox

FROM l3tnun/epgstation:${EPGSTATION_VERSION} AS epgstation

FROM node:${NODE_VERSION}-${DEBIAN_VERSION} AS base

WORKDIR /app

# hadolint ignore=DL3009
RUN --mount=type=cache,id=apt,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,id=apt,target=/var/apt/lists,sharing=locked \
    apt-get update && \
    apt-get install -y --no-upgrade --no-install-recommends tini

FROM base AS prod-deps

COPY --from=epgstation /app/package*.json .

RUN --mount=type=cache,id=prod-deps,target=~/.npm,sharing=locked \
    --mount=type=cache,id=prod-deps,target=./node_modules/.cache,sharing=locked \
    npm install --omit=dev --no-save --loglevel=info

# hadolint ignore=DL3006
FROM gcr.io/distroless/nodejs${NODE_VERSION}-debian${DEBIAN_VERSION_NUMBER}

WORKDIR /app

COPY --from=base /usr/bin/dash /bin/sh
COPY --parents --from=base /usr/bin/tini /

COPY --parents --from=epgstation /app/api.yml /app/img /app/ormconfig.js /app/package.json /app/dist /app/client/dist /

COPY --parents --from=prod-deps /app/node_modules /

RUN --mount=type=bind,from=busybox,source=/bin,target=/bin \
    addgroup -g 44 video && \
    mkdir -p drop config recorded thumbnail data/key data/streamfiles logs/EPGUpdater logs/Operator logs/Service

LABEL maintainer="fetburner"

EXPOSE 8888

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/nodejs/bin/node", "/app/dist/index.js"]
