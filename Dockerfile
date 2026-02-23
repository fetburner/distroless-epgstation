ARG NODE_VERSION
ARG DEBIAN_VERSION
ARG BUSYBOX_VERSION
ARG EPGSTATION_VERSION
ARG DEBIAN_VERSION_NUMBER

# addgroup 及び mkdir を実行するために busybox を使っている
# busybox が使う glibc のバージョンを distroless に入っている glibc と揃える必要がある
FROM busybox:${BUSYBOX_VERSION} AS busybox

FROM l3tnun/epgstation:${EPGSTATION_VERSION} AS epgstation

FROM node:${NODE_VERSION}-${DEBIAN_VERSION} AS base

WORKDIR /app

# docker stop の際の終了時間を短縮するために tini を導入しておく
# hadolint ignore=DL3009
RUN --mount=type=cache,id=apt,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,id=apt,target=/var/apt/lists,sharing=locked \
    apt-get update && \
    apt-get install -y --no-upgrade --no-install-recommends tini

FROM base AS prod-deps

COPY --from=epgstation /app/package*.json .

# 公式イメージの node_modules には devDependencies まで含まれているので除外する
RUN --mount=type=cache,id=prod-deps,target=~/.npm,sharing=locked \
    --mount=type=cache,id=prod-deps,target=./node_modules/.cache,sharing=locked \
    npm install --omit=dev --no-save --loglevel=info

# hadolint ignore=DL3006
FROM gcr.io/distroless/nodejs${NODE_VERSION}-debian${DEBIAN_VERSION_NUMBER}

WORKDIR /app

# 折角の distroless が台無しだが、child_process.spawn で /bin/sh が使われるのでシェルを入れておく必要がある
# https://nodejs.org/api/child_process.html#child_processspawncommand-args-options
COPY --from=base /usr/bin/dash /bin/sh
COPY --parents --from=base /usr/bin/tini /

COPY --parents --from=epgstation /app/api.yml /app/img /app/ormconfig.js /app/package.json /app/dist /app/client/dist /

COPY --parents --from=prod-deps /app/node_modules /

RUN --mount=type=bind,from=busybox,source=/bin,target=/bin \
    # 試しに動かした感じ、ユーザーグループ video が必要みたいなので公式イメージと同じ GID で追加しておく
    addgroup -g 44 video && \
    # 空のディレクトリとかはいちいち COPY せず mkdir で作ってしまう
    mkdir -p drop config recorded thumbnail data/key data/streamfiles logs/EPGUpdater logs/Operator logs/Service

LABEL maintainer="fetburner"

EXPOSE 8888

# docker stop の際の終了時間を短縮するために tini を使う
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/nodejs/bin/node", "/app/dist/index.js"]
