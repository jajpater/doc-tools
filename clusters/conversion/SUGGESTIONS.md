# Suggestions and Notes

## Notes on existing tools

### PPTX notes: `extractnotes` vs `pptx_notes_to_txt`
- `extractnotes` parses both slide titles and notes and writes a structured `.notes` file with slide numbers + titles.
- `pptx_notes_to_txt` extracts only raw notes text (no titles/labels).
- They are independent; `extractnotes` is not a required pre-step for `pptx_notes_to_txt`.

### commentary
- `commentary` converts between docx and markdown while preserving comments and optionally tracked changes.
- Dependencies: `pandoc`, `pypandoc`, `PyYAML`, `gitpython`.

## Improvement ideas

### Implemented (Jan 2026)
- Added `--force` to avoid silent overwrites and added output-exists checks.
- Standardized exit codes: `1` no files/missing deps, `2` no selection, `3` conversion error.
- Made `compile-typst` dry-run output consistent (`Zou...`).
- Added NixOS dependency hints in missing-dependency errors (e.g. `nix shell nixpkgs#pandoc`).

### Reliability / UX
- Consider adding `--force` or output-exists checks to avoid silent overwrites.
- Consider standardizing exit codes: e.g. “no files” vs “no selection” vs “conversion failed”.
- Consider making `--dry-run` output fully consistent across scripts.
- Consider adding explicit NixOS-friendly dependency hints (e.g. `nix shell` examples).

### Selection / GUI
- Improve wofi prompt text with a clear example (`1 3 5-7`).
- If `NAUTILUS_SCRIPT_SELECTED_FILE_PATHS` is set, skip GUI/CLI prompts entirely.
- Sort discovered files for predictable selection order.

### DRY / Maintainability
- Introduce a helper “convert loop” function in `lib/convert_common.sh` to reduce per-script boilerplate.
- Use per-script config variables for input extensions and output formats.

### PPTX utilities
- Consider merging slide-text and notes extraction into one script with flags.
- If `extractnotes` is preferred, document its dependency (`xmlstarlet`) clearly.

### commentary
- Add explicit dependency checks and clearer errors before running.
- Write output using UTF-8 consistently.
