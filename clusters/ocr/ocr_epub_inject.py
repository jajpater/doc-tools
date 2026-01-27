#!/usr/bin/env python3
# Inject OCR text into book.html from an unpacked EPUB (or similar HTML export).
#
# Usage:
#   ./ocr_epub_inject.py book.html langs [--mode inject|replace] [--root PATH] [--out PATH] [--inplace] [--no-css-url]
#
# Dependencies:
#   python3, tesseract, beautifulsoup4
#   optional: lxml, rsvg-convert or ImageMagick convert (for SVG)
import argparse, hashlib, os, re, sys, subprocess
from pathlib import Path
from bs4 import BeautifulSoup

# parser-keuze: lxml als aanwezig, anders builtin
try:
    import lxml  # noqa
    PARSER = "lxml"
except Exception:
    PARSER = "html.parser"

IMG_EXTS = {".png",".jpg",".jpeg",".tif",".tiff",".gif",".jp2",".webp",".bmp",".pbm",".pgm",".ppm",".svg"}
URL_RE = re.compile(r"url\(\s*['\"]?([^'\"\)]+)['\"]?\s*\)", re.I)

def run(cmd):
    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if p.returncode != 0:
        raise RuntimeError(f"Command failed: {' '.join(cmd)}\n{p.stderr}")
    return p

def ensure_css(soup: BeautifulSoup):
    head = soup.find("head")
    if not head:
        if not soup.html:
            html = soup.new_tag("html"); soup.append(html)
            head = soup.new_tag("head"); html.append(head)
            body = soup.new_tag("body"); html.append(body)
        else:
            head = soup.new_tag("head"); soup.html.insert(0, head)
    if not soup.find("meta", attrs={"charset": True}):
        head.append(soup.new_tag("meta", charset="utf-8"))
    if not soup.find("style", attrs={"id": "ocr-css"}):
        style = soup.new_tag("style", id="ocr-css")
        style.string = ".ocr-text{white-space:pre-wrap;font-family:serif;border-left:3px solid #ccc;padding-left:.6em;margin:.6em 0;}"
        head.append(style)

def ocr_image(img_path: Path, langs: str, cache_dir: Path) -> str:
    cache_dir.mkdir(parents=True, exist_ok=True)
    h = hashlib.sha1(img_path.read_bytes() + langs.encode()).hexdigest()
    txt = cache_dir / f"{h}.txt"
    if txt.exists():
        return txt.read_text(encoding="utf-8", errors="ignore")

    src = img_path
    tmp_png = None
    if img_path.suffix.lower() == ".svg":
        tmp_png = cache_dir / f"{h}.png"
        try:
            run(["rsvg-convert", str(img_path), "-o", str(tmp_png), "--dpi-x=300", "--dpi-y=300"])
        except Exception:
            run(["convert", str(img_path), "-density","300","-units","PixelsPerInch","-resample","300x300", str(tmp_png)])
        src = tmp_png

    out_base = cache_dir / f"{h}_out"
    run(["tesseract", str(src), str(out_base), "-l", langs, "--oem","1","--psm","3","txt"])
    out_txt = cache_dir / f"{h}_out.txt"
    text = out_txt.read_text(encoding="utf-8", errors="ignore")
    txt.write_text(text, encoding="utf-8")

    try:
        out_txt.unlink()
        (cache_dir / f"{h}_out.log").unlink(missing_ok=True)
        if tmp_png and tmp_png.exists():
            tmp_png.unlink()
    except Exception:
        pass
    return text

def find_resource(src: str, html_path: Path, root: Path) -> Path | None:
    # probeer: naast HTML, relatief t.o.v. root, en als laatste: glob op bestandsnaam
    cand = (html_path.parent / src)
    if cand.exists():
        return cand
    cand2 = (root / src.lstrip("/"))
    if cand2.exists():
        return cand2
    name = Path(src).name
    for p in root.rglob(name):
        if p.is_file():
            return p
    return None

def inject_into_book(book_html: Path, langs: str, mode: str, root: Path, cache_dir: Path, include_css_urls=True) -> int:
    html = book_html.read_text(encoding="utf-8", errors="ignore")
    soup = BeautifulSoup(html, PARSER)
    ensure_css(soup)

    targets = []  # (tag, src_str, resolved_path)
    # img / object / embed
    for tag in soup.find_all(["img","object","embed"]):
        attr = None
        if tag.name == "img":
            attr = tag.get("src")
        elif tag.name == "object":
            attr = tag.get("data")
        else:
            attr = tag.get("src")
        if not attr:
            continue
        res = find_resource(attr.strip(), book_html, root)
        if not res or res.suffix.lower() not in IMG_EXTS:
            continue
        targets.append((tag, attr.strip(), res))

    # inline CSS background-image: url(...)
    if include_css_urls:
        for tag in soup.find_all(style=True):
            style = tag.get("style","")
            for m in URL_RE.finditer(style):
                url = m.group(1)
                res = find_resource(url, book_html, root)
                if not res or res.suffix.lower() not in IMG_EXTS:
                    continue
                targets.append((tag, url, res))

    changed = 0
    for tag, src_str, path in targets:
        try:
            text = ocr_image(path, langs, cache_dir)
        except Exception:
            continue

        ocr_div = soup.new_tag("div", attrs={"class":"ocr-text","data-src":src_str})
        ocr_div.string = text or ""
        if mode == "replace" and tag.name in ("img","object","embed"):
            tag.replace_with(ocr_div)
        else:
            tag.insert_after(ocr_div)
        changed += 1

    book_html_out = book_html
    return changed, soup

def main():
    ap = argparse.ArgumentParser(description="Injecteer OCR-tekst in book.html")
    ap.add_argument("book_html", help="Pad naar book.html")
    ap.add_argument("langs", help="Tesseract talen, bv: eng of nld+eng")
    ap.add_argument("--mode", choices=["inject","replace"], default="inject", help="img/object/embed behouden (inject) of vervangen (replace)")
    ap.add_argument("--root", help="Extract-root (default: directory van book.html)")
    ap.add_argument("--out", help="Uitvoerbestand (default: naast book.html met suffix _ocr)")
    ap.add_argument("--inplace", action="store_true", help="Overschrijf book.html in-place (maak zelf eerst een backup!)")
    ap.add_argument("--no-css-url", action="store_true", help="Negeer inline CSS background-image url()")
    args = ap.parse_args()

    book_html = Path(args.book_html).resolve()
    if not book_html.is_file():
        print(f"Bestand niet gevonden: {book_html}", file=sys.stderr); sys.exit(2)

    root = Path(args.root).resolve() if args.root else book_html.parent
    cache_dir = (root / ".ocr_cache")

    changed, soup = inject_into_book(
        book_html, args.langs, args.mode, root, cache_dir,
        include_css_urls=not args.no_css_url
    )

    if args.inplace:
        out_path = book_html
    else:
        out_path = book_html.with_name(book_html.stem + "_ocr" + book_html.suffix)

    out_path.write_text(str(soup), encoding="utf-8")
    print(f"OCR-injecties: {changed}")
    print(f"Geschreven: {out_path}")

if __name__ == "__main__":
    main()
