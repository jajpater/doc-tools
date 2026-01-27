#!/usr/bin/env python3
import runpy
import sys
from pathlib import Path


def main() -> int:
    script = Path(__file__).with_name("media_transcribe.py")
    sys.argv = [str(script), "--format", "org", *sys.argv[1:]]
    runpy.run_path(script, run_name="__main__")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
