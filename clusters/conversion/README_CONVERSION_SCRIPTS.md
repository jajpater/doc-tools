# Document Conversion Scripts

Common usage and selection flow for scripts in this directory.

## Core scripts (no .sh suffix)
- `md_to_typ`
- `md_to_org`
- `md_to_tex`
- `org_to_typ`
- `org_to_tex`
- `docx_to_org`
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

## Dependencies
Minimum dependencies per script are checked at runtime:
- `pandoc` for `md_to_*`, `org_to_*`, `docx_to_*`
- `typst` for `compile-typst`
- `docx2txt` for `docx_to_txt`
- `unzip` + `perl` for `pptx_to_txt` and `pptx_notes_to_txt`
- `fzf` is required for CLI selection
- `wofi` is required if `--gui` is used

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

GUI selection with wofi:
```
./docx_to_pdf --gui
```
