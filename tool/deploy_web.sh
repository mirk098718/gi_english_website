#!/bin/bash
# 운영 사이트에 이미 올라간 커밋을 포함하지 않는 빌드는 배포하지 않는다.
# 다른 브랜치를 checkout 해서 빌드하면, 그 브랜치에 없는 화면이 사이트에서 사라진다.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT="gleam-island"
LIVE_URL="https://${PROJECT}.web.app/deploy-sha.txt"
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

SHA="$(git rev-parse HEAD)"
# deploy-sha.txt 가 생기기 전에 운영에 있던 마지막 사이트 커밋.
# 이 커밋을 포함하지 않으면 수강과정 전체보기 등 이후 수정이 다시 지워진다.
FALLBACK_BASE="$(git rev-parse --verify 920eab6^{commit})"

fetch_live_sha() {
  local body http
  body="$(mktemp)"
  http="$(curl -sS -o "$body" -w '%{http_code}' --max-time 20 "$LIVE_URL" || true)"
  if [[ "$http" != "200" ]]; then
    rm -f "$body"
    echo ""
    return
  fi
  tr -d '[:space:]' < "$body"
  rm -f "$body"
}

LIVE="$(fetch_live_sha)"
if [[ ! "$LIVE" =~ ^[0-9a-f]{40}$ ]]; then
  if [[ -z "$LIVE" ]]; then
    echo "운영 사이트에 연결하지 못했습니다. 배포를 멈춥니다." >&2
    exit 1
  fi
  echo "운영 사이트에 배포 SHA가 아직 없습니다. 기준 커밋 ${FALLBACK_BASE} 를 포함해야 합니다." >&2
  LIVE="$FALLBACK_BASE"
fi

if ! git cat-file -e "${LIVE}^{commit}" 2>/dev/null; then
  git fetch origin
fi

if ! git cat-file -e "${LIVE}^{commit}" 2>/dev/null; then
  echo "운영 중인 커밋 ${LIVE} 를 저장소에서 찾지 못했습니다. 배포를 멈춥니다." >&2
  exit 1
fi

if ! git merge-base --is-ancestor "$LIVE" HEAD; then
  echo "이 커밋 ${SHA} 는 지금 운영 중인 ${LIVE} 를 포함하지 않습니다." >&2
  echo "그 커밋을 먼저 합친 뒤에만 배포할 수 있습니다. 다른 브랜치를 받아 덮어쓰지 마세요." >&2
  exit 1
fi

echo "배포 가능: ${SHA}"
echo "포함하는 운영 커밋: ${LIVE}"

if [[ "$CHECK_ONLY" == "1" ]]; then
  exit 0
fi

if [[ -x /tmp/flutter-sdk/flutter/bin/flutter ]]; then
  export PATH="/tmp/flutter-sdk/flutter/bin:${PATH}"
fi

flutter build web --pwa-strategy=none --no-wasm-dry-run
printf '%s\n' "$SHA" > build/web/deploy-sha.txt

npx --yes firebase-tools@13 deploy \
  --only hosting,firestore:rules \
  --project "${PROJECT}" \
  --non-interactive

echo "호스팅 배포가 끝났습니다. https://${PROJECT}.web.app"
echo "배포 SHA: ${SHA}"
