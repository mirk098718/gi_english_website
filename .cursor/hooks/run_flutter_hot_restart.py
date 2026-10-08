#!/usr/bin/env python3
"""stop: Flutter 파일을 고친 턴이 끝나면 Chrome 세션을 핫 리스타트한다."""
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
STAMP = ROOT / ".dart_tool" / "needs_flutter_hot_restart"
SCRIPT = ROOT / "tool" / "flutter_hot_restart.sh"


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        print("{}")
        return
    status = data.get("status")
    if status not in (None, "completed"):
        print("{}")
        return
    if not STAMP.exists():
        print("{}")
        return
    try:
        STAMP.unlink()
    except OSError:
        pass
    subprocess.run([str(SCRIPT)], cwd=str(ROOT), check=False)
    print("{}")


if __name__ == "__main__":
    main()
