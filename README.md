# distroless-epgstation

[![Docker build](https://github.com/fetburner/distroless-epgstation/actions/workflows/build.yml/badge.svg)](https://github.com/fetburner/distroless-epgstation/actions/workflows/build.yml)
[![Dockerfile lint](https://github.com/fetburner/distroless-epgstation/actions/workflows/lint.yml/badge.svg)](https://github.com/fetburner/distroless-epgstation/actions/workflows/lint.yml)

[Distroless](https://github.com/GoogleContainerTools/distroless) をベースイメージとして用いた録画管理ソフト [EPGStation](https://github.com/l3tnun/EPGStation) の非公式ビルドです。
[EPGStation](https://github.com/l3tnun/EPGStation) の動作に必要な最小限のファイルのみ含むよう実装されているため軽量であり、v2.10.0 時点で公式イメージのおよそ半分に相当する 85MB 程度に収まっています。
