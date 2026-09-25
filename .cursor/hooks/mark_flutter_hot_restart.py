#!/usr/bin/env python3
"""afterFileEdit: Flutter 미리보기 파일이면 핫 리스타트 스탬프를 남긴다."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STAMP = ROOT / ".dart_tool" / "needs_flutter_hot_restart"


def should_mark(path: str) -> bool:
    p = path.replace("\\", "/")
    name = p.rsplit("/", 1)[-1]
    if name in ("pubspec.yaml", "pubspec.lock"):
        return True
    if p.endswith(".dart") and ("/lib/" in p or "/test/" in p):
        return True
    if "/web/" in p and not p.endswith(".md"):
        return True
    return False


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        print("{}")
        return
    if should_mark(data.get("file_path") or ""):
        STAMP.parent.mkdir(parents=True, exist_ok=True)
        STAMP.write_text("1\n")
    print("{}")


if __name__ == "__main__":
    main()
