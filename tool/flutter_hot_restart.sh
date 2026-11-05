#!/bin/zsh
# GI English (Chrome) 세션에 SIGUSR2를 보내 핫 리스타트한다.
# flutter run -d web-server 는 시작하지 않는다.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PID_FILE="$ROOT/.dart_tool/flutter_chrome.pid"
PORT=7357

is_flutter_tools() {
  local pid="$1"
  local cmd
  cmd="$(ps -o command= -p "$pid" 2>/dev/null || true)"
  [[ "$cmd" == *flutter_tools.snapshot* || "$cmd" == *"flutter_tools "* ]]
}

try_signal() {
  local pid="$1"
  [[ -n "$pid" ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  is_flutter_tools "$pid" || return 1
  kill -USR2 "$pid"
  echo "Flutter hot restart: SIGUSR2 -> $pid"
  return 0
}

if [[ -f "$PID_FILE" ]]; then
  if try_signal "$(tr -d '[:space:]' < "$PID_FILE")"; then
    exit 0
  fi
fi

listen_pid="$(lsof -nP -iTCP:${PORT} -sTCP:LISTEN -t 2>/dev/null | head -1 || true)"
if try_signal "$listen_pid"; then
  exit 0
fi

pid="$listen_pid"
for _ in {1..8}; do
  [[ -n "$pid" && "$pid" != "1" ]] || break
  pid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')"
  if try_signal "$pid"; then
    exit 0
  fi
done

echo "Chrome Flutter 세션(127.0.0.1:${PORT})이 없습니다. launch.json의 GI English (Chrome)을 한 번 실행하세요. web-server는 쓰지 마세요." >&2
exit 1
