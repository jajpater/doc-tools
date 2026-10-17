# Document Conversion Scripts

Common usage and selection flow for scripts in this directory.

## Core scripts (no .sh suffix)
- `md_to_typ`
- `md_to_org`
- `md_to_tex`
- `org_to_typ`
- `org_to_docx`
- `org_to_tex`
- `docx_to_org`
- `docx_to_md`
- `docx_to_pdf`
- `docx_to_txt`
- `compile-typst`
- `pptx_to_txt`
- `pptx_notes_to_txt`

## Selection flow
Default behavior:
- If multiple input files exist, you are prompted: **All** vs **Select**.
- If only one input file exists, it is processed directly.

Common flags:
- `--all` process all matches without prompting
- `--select` select files (fzf)
- `--gui` use wofi instead of fzf for selection
- `--file <path>` add specific file(s) (repeatable)
- `--ext <ext>` add extra input extensions (repeatable)
- `--rename` replace spaces with underscores before processing
- `--force` overwrite existing output files
- `--dry-run` show what would happen
- `--verbose` extra output

Notes:
- `--file` can be used for files with non-standard extensions (e.g. `--ext txt`).
- With Nautilus: if `NAUTILUS_SCRIPT_SELECTED_FILE_PATHS` is set, those files are used directly.
- `--gui` uses wofi and supports multi-select by entering indices like `1 3 5-7`.

## Script-specific flags
`org_to_typ` and `org_to_docx`:
- `--keep-numbers` keep the numbers of Org lists that don't start at 1 (see below)

`org_to_docx`:
- `--reference-doc <path>` use the styles of this `.docx` file

### Org list numbers
Org (and pandoc's Org reader) ignores the number in front of an item: `23.` is
read as item 1 and comes out as `1.`. Only a counter cookie keeps the number:

```
23. [@23] first verse
24. second verse
```

The cookie is only needed on the first item; the next items count on. Both
scripts honour cookies that are in the file. For files without cookies,
`--keep-numbers` first runs `lib/org_keep_list_numbers.py`, which adds a cookie
to the first item of every list that doesn't start at 1 and to every item where
the numbering jumps. The source file itself is not changed. The script follows
Org's list rules approximately: a headline or two blank lines end every list,
and lines inside `#+begin_`/`#+end_` blocks are never items.

Pandoc only uses the cookie on the first item of a list, so a jump in the
middle of a list (24 → 26) is lost.

`org_to_docx` always applies `decimal-lists.lua`: pandoc's docx writer would
otherwise number nested lists with letters (`23.` becomes `w.`).

## Dependencies
Minimum dependencies per script are checked at runtime:
- `pandoc` for `md_to_*`, `org_to_*`, `docx_to_*`
- `typst` for `compile-typst`
- `pandoc` for `docx_to_txt`
- `unzip` + `perl` for `pptx_to_txt` and `pptx_notes_to_txt`
- `fzf` is required for CLI selection
- `wofi` is required if `--gui` is used
- `python3` is required if `--keep-numbers` is used

On NixOS, make sure these tools are in PATH (e.g. via `nix shell` or a profile).

## Exit codes
- `1`: no input files found or missing dependency
- `2`: no files selected
- `3`: conversion/compile error

## Examples
Convert selected markdown files (fzf):
```
./md_to_typ --select
```

Convert one file with a non-standard extension:
```
./md_to_typ --file notes.txt --ext txt
```

Compile specific typst files from Nautilus selection:
```
./compile-typst
```

Convert an Org file to docx, keeping verse numbers and using your own styles:
```
./org_to_docx --file schetsen.org --keep-numbers --reference-doc stijl.docx
```

GUI selection with wofi:
```
./docx_to_pdf --gui
```
