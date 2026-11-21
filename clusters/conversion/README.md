# Document Conversion Directory

This directory contains small conversion utilities and helpers.

## Conversion scripts
- `md_to_typ`: Convert Markdown to Typst; adds an A5 page header, converts horizontal rules to lines, and preserves HTML comments as Typst line comments (`//`). Use `--comment-style block` for `/* ... */` or `--no-comments` to omit comments.
- `md_to_org`: Convert Markdown to Org-mode.
- `md_to_tex`: Convert Markdown to LaTeX.
- `org_to_typ`: Convert Org-mode to Typst; adds A5 page header and removes horizontal rules.
- `org_to_docx`: Convert Org-mode to DOCX; numbered lists stay decimal at every level, optional `--reference-doc` for styles.
- `org_to_tex`: Convert Org-mode to LaTeX.
- `docx_to_org`: Convert DOCX to Org-mode.
- `docx_to_md`: Convert DOCX to Markdown.
- `docx_to_pdf`: Convert DOCX to PDF.
- `docx_to_txt`: Convert DOCX to plain text (pandoc).
- `compile-typst`: Compile Typst files to PDF.
- `pptx_to_txt`: Extract slide text from PPTX files.
- `pptx_notes_to_txt`: Extract speaker notes from PPTX files.

## EPUB utilities
- `epub-preprocess`: Preprocess EPUB XHTML to make it Pandoc-friendly.
- `epub-convert`: Convert a single EPUB XHTML file to multiple formats (md/org/typ/docx).
- `README_EPUB_CONVERSION.md`: Detailed EPUB workflow documentation.

## Other utilities
- `batch-vectorize.sh`: Batch convert JPG/WEBP to SVG using ImageMagick + potrace.
- `convert-html2docx-comments`: Convert HTML comments to DOCX comments (Perl).
- `extractnotes`: Extract PPTX speaker notes with slide numbers and titles into a `.notes` file (uses xmlstarlet).
- `hrule.lua`: Pandoc Lua filter to remove horizontal rules.
- `decimal-lists.lua`: Pandoc Lua filter that keeps Org's numbered lists decimal (pandoc's docx writer otherwise uses letters for nested lists).
- `lib/org_keep_list_numbers.py`: Adds `[@N]` cookies to Org lists that don't start at 1, so pandoc keeps the numbers (`23.` would otherwise become `1.`).
- `commentary`: Comment-preserving docx/markdown converter (uses pandoc via pypandoc).
- `lib/convert_common.sh`: Shared helpers for selection, deps, and file handling.

## Org list numbers
Org (and pandoc's Org reader) ignores the number in front of an item: `23.` is read as item 1. Only a counter cookie keeps it: `23. [@23] text`. `org_to_typ` and `org_to_docx` honour cookies that are in the file. For files without cookies, `--keep-numbers` runs `lib/org_keep_list_numbers.py` first. It follows Org's list rules approximately. Pandoc only uses the cookie on the first item of a list; a jump in the middle of a list (24 → 26) is lost.

## Selection/GUI behavior
The conversion scripts share a common selection flow. See `README_CONVERSION_SCRIPTS.md` for flags and examples.

## PPTX notes: `extractnotes` vs `pptx_notes_to_txt`
- `extractnotes` parses both slide titles and notes and writes a structured `.notes` file with slide numbers + titles.
- `pptx_notes_to_txt` extracts only raw notes text (no titles/labels).
- They are independent; `extractnotes` is not a required pre-step for `pptx_notes_to_txt`.

## commentary details
- `commentary` converts between docx and markdown while preserving comments and optionally tracked changes.
- Dependencies: `pandoc`, `pypandoc`, `PyYAML`, `gitpython`.

## typst_lite2docx
This script used to convert typstfiles to docx, has been moved to a separate typ-docx repo.

