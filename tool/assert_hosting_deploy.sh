#!/bin/bash
# 호스팅을 올리기 전에 실행한다. firebase.json predeploy도 이 스크립트를 부른다.
# 지금 커밋이 운영 사이트에 이미 올라간 커밋을 포함하지 않으면 배포를 멈춘다.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT="gleam-island"
LIVE_URL="https://${PROJECT}.web.app/deploy-sha.txt"
MODE="predeploy"

if [[ "${1:-}" == "--ancestor-only" ]]; then
  MODE="ancestor"
elif [[ -n "${1:-}" ]]; then
  echo "알 수 없는 옵션: $1" >&2
  exit 1
fi

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
  echo "운영 사이트의 배포 커밋을 읽지 못했습니다. 이미 올린 화면을 덮지 않도록 배포를 멈춥니다." >&2
  echo "주소: ${LIVE_URL}" >&2
  exit 1
fi

SHA="$(git rev-parse HEAD)"
if ! git cat-file -e "${LIVE}^{commit}" 2>/dev/null; then
  git fetch origin --quiet || true
fi
if ! git cat-file -e "${LIVE}^{commit}" 2>/dev/null; then
  echo "운영 중인 커밋 ${LIVE} 가 이 저장소에 없습니다. 그 커밋을 받은 뒤에 배포하세요." >&2
  exit 1
fi
if ! git merge-base --is-ancestor "$LIVE" HEAD; then
  echo "이 커밋 ${SHA} 에는 지금 운영 중인 ${LIVE} 가 없습니다." >&2
  echo "이미 배포된 수정이 지워지므로 배포하지 않습니다. 그 커밋을 먼저 합치세요." >&2
  exit 1
fi

if [[ "$MODE" == "predeploy" ]]; then
  BUILT="${ROOT}/build/web/deploy-sha.txt"
  if [[ ! -f "$BUILT" ]]; then
    echo "build/web/deploy-sha.txt 가 없습니다. tool/deploy_web.sh 로 빌드한 뒤에 배포하세요." >&2
    exit 1
  fi
  BUILT_SHA="$(tr -d '[:space:]' < "$BUILT")"
  if [[ "$BUILT_SHA" != "$SHA" ]]; then
    echo "빌드에 적힌 커밋은 ${BUILT_SHA} 이고, 지금 커밋은 ${SHA} 입니다." >&2
    echo "다른 시점의 빌드를 올리면 화면이 어긋납니다. tool/deploy_web.sh 를 다시 실행하세요." >&2
    exit 1
  fi
fi

echo "배포 검사 통과: ${SHA} 가 운영 커밋 ${LIVE} 를 포함합니다."
