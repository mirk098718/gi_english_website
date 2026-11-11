#!/bin/bash
# 호스팅 배포 직전에만 실행한다.
# 이전 build/web 을 먼저 지우므로, 컴파일이 실패하면 예전 화면이 올라가지 않는다.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

COMMIT="$(git rev-parse --short HEAD)"
SUBJECT="$(git log -1 --pretty=%s)"
echo "웹 빌드 커밋: ${COMMIT} ${SUBJECT}"

rm -rf build/web
flutter build web --no-wasm-dry-run

test -f build/web/main.dart.js
test -f build/web/index.html
{
  git rev-parse HEAD
  git log -1 --pretty=%s
} > build/web/release.txt

echo "웹 빌드 완료: ${COMMIT}"
