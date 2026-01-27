#!/usr/bin/env python3
import runpy
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) < 3:
        print("Usage: fw_transcribe.py AUDIO OUTPUT_BASE")
        return 1

    script = Path(__file__).with_name("media_transcribe.py")
    audio = sys.argv[1]
    out_base = sys.argv[2]
    rest = sys.argv[3:]

    sys.argv = [
        str(script),
        "--format",
        "json",
        "--format",
        "srt",
        "--format",
        "vtt",
        "--output",
        out_base,
        audio,
        *rest,
    ]
    runpy.run_path(script, run_name="__main__")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
