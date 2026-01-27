# OCR scripts

This directory contains a small set of OCR helper scripts. Below is what each script does, how to use it, options, and dependencies.

## ocr_images.sh
Flexible OCR for a folder of image files. Builds an intermediate PDF from images, runs OCRmyPDF, extracts text, and writes PDF/TXT/MD/ORG/TYPST outputs.

Usage:
```
./ocr_images.sh [OPTIONS] [DIR] [OUTPUT_BASENAME]
```

Examples:
```
./ocr_images.sh
./ocr_images.sh scans/
./ocr_images.sh scans/ document_ocr
./ocr_images.sh --lang "eng+heb" scans/
./ocr_images.sh --pattern "*.jpg" scans/
./ocr_images.sh --single-sided scans/
```

Options:
- `-h, --help`        Show help
- `-l, --lang`        OCR languages (default: `nld+eng`)
- `-p, --pattern`     File glob pattern (default: auto-detect supported image types)
- `-s, --single-sided`  Force single-sided ordering
- `-d, --double-sided`  Force double-sided ordering
- `-v, --verbose`     Verbose output
- `--dry-run`         Show matched files only

Inputs:
- Image files in the target directory. Supported: `jpg`, `jpeg`, `png`, `tif`, `tiff`, `bmp`.

Outputs:
- `<OUTBASE>.pdf`, `<OUTBASE>.txt`, `<OUTBASE>.md`, `<OUTBASE>.org`, `<OUTBASE>.typst`

Dependencies:
- `img2pdf`
- `ocrmypdf`
- `pdftotext` (from poppler-utils)


## ocr_epub_inject.py
Inject OCR text into a `book.html` from an unpacked EPUB (or similar HTML export). It OCRs images and inserts text blocks into the HTML.

Usage:
```
./ocr_epub_inject.py book.html langs [--mode inject|replace] [--root PATH] [--out PATH] [--inplace] [--no-css-url]
```

Examples:
```
./ocr_epub_inject.py book.html nld
./ocr_epub_inject.py book.html eng+heb --mode replace
./ocr_epub_inject.py book.html nld+eng --root /path/to/unpacked_epub
./ocr_epub_inject.py book.html nld --inplace
```

Options:
- `--mode`       `inject` (keep images, add text) or `replace` (replace img/object/embed)
- `--root`       Root directory to resolve referenced images (default: directory of `book.html`)
- `--out`        Output HTML file (default: `book_ocr.html` next to input)
- `--inplace`    Overwrite `book.html` in-place (make a backup yourself)
- `--no-css-url` Ignore `background-image: url(...)` in inline styles

Inputs:
- `book.html` plus image files referenced by the HTML (img/object/embed and inline CSS URLs)

Outputs:
- HTML with injected OCR text blocks; cache directory `.ocr_cache` is created under `--root`

Dependencies:
- `python3`
- `tesseract`
- `beautifulsoup4` (Python package)
- `lxml` (optional; falls back to Python html parser)
- `rsvg-convert` or ImageMagick `convert` for SVG images


## pdfsand_nld_dir
Run OCR on all `*.pdf` in the current directory using `pdfsandwich` with Dutch language.

Usage:
```
./pdfsand_nld_dir
```

Options:
- None

Dependencies:
- `pdfsandwich`
- Tesseract language data for Dutch (`nld`)


## pdfsand_nld_double_dir
Same as `pdfsand_nld_dir`, but uses `-layout double` for double-sided scans.

Usage:
```
./pdfsand_nld_double_dir
```

Options:
- None (uses `-layout double -lang nld` internally)

Dependencies:
- `pdfsandwich`
- Tesseract language data for Dutch (`nld`)
