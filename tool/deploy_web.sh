#!/bin/bash
# 운영 사이트에 이미 올라간 커밋을 포함한 뒤에만 웹을 빌드하고 호스팅에 올린다.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT="gleam-island"
CHECK_ONLY=0

if [[ "${1:-}" == "--check" ]]; then
  CHECK_ONLY=1
elif [[ -n "${1:-}" ]]; then
  echo "알 수 없는 옵션: $1" >&2
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "커밋하지 않은 변경이 있습니다. 배포되는 커밋과 빌드가 달라지므로 먼저 커밋하세요." >&2
  git status --short >&2
  exit 1
fi

bash "${ROOT}/tool/assert_hosting_deploy.sh" --ancestor-only

if [[ "$CHECK_ONLY" == "1" ]]; then
  exit 0
fi

if [[ -x /tmp/flutter-sdk/flutter/bin/flutter ]]; then
  export PATH="/tmp/flutter-sdk/flutter/bin:${PATH}"
fi

flutter build web --pwa-strategy=none --no-wasm-dry-run
printf '%s\n' "$(git rev-parse HEAD)" > build/web/deploy-sha.txt

npx --yes firebase-tools@13 deploy \
  --only hosting,firestore:rules \
  --project "${PROJECT}" \
  --non-interactive

echo "호스팅 배포가 끝났습니다. https://${PROJECT}.web.app"
echo "배포 SHA: $(git rev-parse HEAD)"
