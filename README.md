# distroless-epgstation

[![Docker build](https://github.com/fetburner/distroless-epgstation/actions/workflows/build.yml/badge.svg)](https://github.com/fetburner/distroless-epgstation/actions/workflows/build.yml)
[![Dockerfile lint](https://github.com/fetburner/distroless-epgstation/actions/workflows/lint.yml/badge.svg)](https://github.com/fetburner/distroless-epgstation/actions/workflows/lint.yml)

[Distroless](https://github.com/GoogleContainerTools/distroless) をベースイメージとして用いた録画管理ソフト [EPGStation](https://github.com/l3tnun/EPGStation) の非公式ビルドです。
[EPGStation](https://github.com/l3tnun/EPGStation) の動作に必要な最小限のファイルのみ含むよう実装されているため軽量であり、v2.10.0 時点で公式イメージのおよそ半分に相当する 85MB 程度に収まっています。

## サポートされているタグ一覧

[EPGStation](https://github.com/l3tnun/EPGStation) のバージョン、[EPGStation](https://github.com/l3tnun/EPGStation) の実行に用いる Node.js のバージョン、及び [Distroless](https://github.com/GoogleContainerTools/distroless) がベースにしている Debian のバージョンをハイフンで繋げてタグを打っており、現在次のバージョンをサポートしています。

- v2.10.0-18-bookworm
- v2.9.1-18-bookworm
- v2.8.0-18-bookworm
- v2.7.3-18-bookworm

ビルドに用いた Dockerfile は [GitHub](https://github.com/fetburner/distroless-epgstation) のリポジトリ上にあります。

## 利用例

ライセンスの都合で公式イメージ同様 FFmpeg は同梱していないため、利用にあたっては自分でビルドした FFmpeg を配置する必要があります。
ここで、distroless-epgstation には FFmpeg の実行に必要な共有ライブラリの殆どが同梱されていないため、静的リンクを行うか共有ライブラリも FFmpeg と一緒にコピーする必要がある事に注意して下さい。

参考として、[extlibcp](https://github.com/kurukurumaware/extlibcp) を使って FFmpeg の実行に必要な共有ライブラリのコピーを行う場合の Dockerfile を示します。

```Dockerfile
FROM debian:bookworm AS ffmpeg-build

WORKDIR /app

ENV FFMPEG_VERSION=7.0

RUN --mount=type=cache,id=apt,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,id=apt,target=/var/apt/lists,sharing=locked \
    apt-get update && \
    apt-get install -y \
      make gcc git g++ automake curl wget autoconf build-essential libass-dev libfreetype6-dev \
      libsdl1.2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev \
      libxcb-shm0-dev libxcb-xfixes0-dev pkg-config texinfo zlib1g-dev \
      yasm libx264-dev libmp3lame-dev libopus-dev libvpx-dev \
      libx265-dev libnuma-dev \
      libasound2 libass9 libvdpau1 libva-x11-2 libva-drm2 libxcb-shm0 libxcb-xfixes0 \
      libxcb-shape0 libvorbisenc2 libtheora0 libaribb24-dev

# FFmpeg のビルド
# ここでのビルド設定は
# [docker-mirakurun-epgstation](https://github.com/l3tnun/docker-mirakurun-epgstation) を参考としたもの
RUN curl -fsSL http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.bz2 | tar -xj --strip-components=1

RUN ./configure \
      --prefix=/usr/local \
      --disable-shared \
      --pkg-config-flags=--static \
      --enable-gpl \
      --enable-libass \
      --enable-libfreetype \
      --enable-libmp3lame \
      --enable-libopus \
      --enable-libtheora \
      --enable-libvorbis \
      --enable-libvpx \
      --enable-libx264 \
      --enable-libx265 \
      --enable-version3 \
      --enable-libaribb24 \
      --enable-nonfree \
      --disable-debug \
      --disable-doc \
    && \
    make -j$(nproc) && \
    make install

# extlibcp を使うと ldd を繰り返し呼び出して特定のプログラムの実行に必要な共有ライブラリを列挙してコピーしてくれる
RUN curl -fsSL https://github.com/kurukurumaware/extlibcp/tarball/master | tar -xz --strip-components=1

RUN ./extlibcp $(which ffmpeg) /build && \
    ./extlibcp $(which ffprobe) /build

FROM fetburner/distroless-epgstation:v2.10.0-18-bookworm

# fetburner/distroless-epgstation:v2.10.0-18-bookworm に既に存在する共有ライブラリは除外して、
# ビルドした FFmpeg 及び FFprobe をコピーする
# コピーしなくても良い共有ライブラリはプラットフォームや Debian のバージョンによって変わるので、
# [dive](https://github.com/wagoodman/dive) などを使って調べると良い
COPY --from=ffmpeg-build \
     --exclude=lib/aarch64-linux-gnu/libc.so.6 \
     --exclude=lib/aarch64-linux-gnu/libm.so.6 \
     --exclude=lib/aarch64-linux-gnu/ld-linux-aarch64.so.1 \
     --exclude=lib/aarch64-linux-gnu/libgcc_s.so.1 \
     --exclude=lib/ld-linux-aarch64.so.1 \
     /build /
```

## 注意点

SQLite3 の実行に必要な共有ライブラリがイメージに同梱されていないため、データベースには MySQL しか利用できません。

npm がイメージに同梱されていない上 node コマンドにパスが通っていないため、データベースのバックアップとレストアの手順が公式イメージと異なります。

バックアップの際は次のコマンドを、

```
/nodejs/bin/node /app/dist/DBTools.js -m backup -o FILENAME
```

レストアの際は次のコマンドを実行して下さい。

```
/nodejs/bin/node /app/dist/DBTools.js -m restore -o FILENAME
```
