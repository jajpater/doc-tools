#!/usr/bin/env python3
"""Zet [@N]-cookies in Org-tekst zodat genummerde lijsten hun getal houden.

Org (en pandoc's Org-lezer) telt het getal voor een genummerd item niet mee:
"23." telt als eerste item en wordt "1.".  Alleen een [@N]-cookie legt het
getal vast.  Dit script zet zo'n cookie op het eerste item van een lijst die
niet bij 1 begint, en op elk item waar de nummering verspringt.

Het volgt Org's lijstregels bij benadering: een kop of twee lege regels
beëindigen elke lijst, een regel die niet verder inspringt dan de bullet
beëindigt die lijst, en regels in #+begin_/#+end_-blokken tellen niet als
item.

Gebruik: org_keep_list_numbers.py IN.org [UIT.org]   (zonder UIT: stdout)
"""
import re
import sys
from pathlib import Path

ITEM_RE = re.compile(
    r"^(?P<indent>[ \t]*)(?:(?P<num>\d+)[.)]|[-+]|(?<=\s)\*)(?P<space>[ \t]+|$)"
    r"(?P<cookie>\[@(?P<counter>\d+)\])?"
)
HEADLINE_RE = re.compile(r"^\*+[ \t]")
BLOCK_BEGIN_RE = re.compile(r"^[ \t]*#\+begin_(\S+)", re.IGNORECASE)


def indent_width(indent: str) -> int:
    return len(indent.expandtabs(8))


def keep_list_numbers(text: str) -> str:
    lines = text.splitlines(keepends=True)
    out = []
    # Open lijsten, buitenste eerst: [inspringing van de bullet, verwacht getal]
    lists = []
    blank_run = 0
    block_end = None

    for line in lines:
        if block_end is not None:
            out.append(line)
            if block_end.match(line):
                block_end = None
            continue

        if not line.strip():
            blank_run += 1
            if blank_run >= 2:
                lists.clear()
            out.append(line)
            continue
        blank_run = 0

        if HEADLINE_RE.match(line):
            lists.clear()
            out.append(line)
            continue

        item = ITEM_RE.match(line)
        if item is None:
            width = indent_width(line[: len(line) - len(line.lstrip())])
            while lists and lists[-1][0] >= width:
                lists.pop()
            begin = BLOCK_BEGIN_RE.match(line)
            if begin:
                block_end = re.compile(
                    r"^[ \t]*#\+end_" + re.escape(begin.group(1)) + r"\b",
                    re.IGNORECASE,
                )
            out.append(line)
            continue

        width = indent_width(item.group("indent"))
        while lists and lists[-1][0] > width:
            lists.pop()
        if not lists or lists[-1][0] < width:
            lists.append([width, 1])
        current = lists[-1]

        if item.group("counter"):
            current[1] = int(item.group("counter")) + 1
        elif item.group("num"):
            n = int(item.group("num"))
            if n != current[1]:
                pos = item.end("space")
                line = f"{line[:pos]}[@{n}] {line[pos:]}"
            current[1] = n + 1
        else:
            current[1] += 1
        out.append(line)

    return "".join(out)


def main() -> int:
    if len(sys.argv) not in (2, 3):
        print(__doc__.strip().splitlines()[-1], file=sys.stderr)
        return 2
    result = keep_list_numbers(Path(sys.argv[1]).read_text(encoding="utf-8"))
    if len(sys.argv) == 3:
        Path(sys.argv[2]).write_text(result, encoding="utf-8")
    else:
        sys.stdout.write(result)
    return 0


if __name__ == "__main__":
    sys.exit(main())
