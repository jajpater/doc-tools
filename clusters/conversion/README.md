# Document Conversion Directory

This directory contains small conversion utilities and helpers.

## Conversion scripts
- `md_to_typ`: Convert Markdown to Typst; adds A5 page header and removes horizontal rules.
- `md_to_org`: Convert Markdown to Org-mode.
- `md_to_tex`: Convert Markdown to LaTeX.
- `org_to_typ`: Convert Org-mode to Typst; adds A5 page header and removes horizontal rules.
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
- `typst_lite2docx.py`: Convert Typst Lite to DOCX.
- `hrule.lua`: Pandoc Lua filter to remove horizontal rules.
- `commentary`: Comment-preserving docx/markdown converter (uses pandoc via pypandoc).
- `lib/convert_common.sh`: Shared helpers for selection, deps, and file handling.

## Selection/GUI behavior
The conversion scripts share a common selection flow. See `README_CONVERSION_SCRIPTS.md` for flags and examples.

## PPTX notes: `extractnotes` vs `pptx_notes_to_txt`
- `extractnotes` parses both slide titles and notes and writes a structured `.notes` file with slide numbers + titles.
- `pptx_notes_to_txt` extracts only raw notes text (no titles/labels).
- They are independent; `extractnotes` is not a required pre-step for `pptx_notes_to_txt`.

## commentary details
- `commentary` converts between docx and markdown while preserving comments and optionally tracked changes.
- Dependencies: `pandoc`, `pypandoc`, `PyYAML`, `gitpython`.
