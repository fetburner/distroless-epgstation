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
