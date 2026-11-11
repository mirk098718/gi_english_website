#!/bin/bash
# 웹 배포는 새 커리큘럼 브랜치를 받은 뒤에만 빌드한다.
# main 작업 트리에서 빌드하면 예전 화면이 gleam-island.web.app 에 올라간다.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BRANCH="cursor/online-product-plans-037b"
PROJECT="gleam-island"

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "커밋하지 않은 변경이 있습니다. 배포 브랜치를 받기 전에 커밋하거나 치워 주세요." >&2
  git status --short >&2
  exit 1
fi

git fetch origin

if git rev-parse --verify "origin/${BRANCH}" >/dev/null 2>&1; then
  echo "배포 브랜치: origin/${BRANCH}"
  git checkout "${BRANCH}"
  git pull --ff-only origin "${BRANCH}"
else
  echo "origin/${BRANCH} 가 없습니다. main 을 받아 빌드합니다."
  git checkout main
  git pull --ff-only origin main
fi

echo "빌드 기준: $(git rev-parse --abbrev-ref HEAD) @ $(git rev-parse --short HEAD)"
flutter build web
firebase deploy --only hosting --project "${PROJECT}"
echo "호스팅 배포가 끝났습니다. https://${PROJECT}.web.app"
