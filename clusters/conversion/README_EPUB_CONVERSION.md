# EPUB XHTML naar Pandoc Conversie Scripts

Generieke scripts voor het converteren van EPUB XHTML-bestanden naar verschillende formaten (Markdown, Org-mode, Typst) met behulp van pandoc.

## Overzicht

Deze scripts werken met **elk uitgepakt EPUB** en lossen veelvoorkomende problemen op bij het converteren van EPUB XHTML naar andere formaten.

## Bestanden

- **`epub-preprocess`** - Python script voor het preprocessen van EPUB XHTML
- **`epub-convert`** - Bash script voor complete conversie-workflow  
- **`README_EPUB_CONVERSION.md`** - Deze documentatie

## Installatie

De scripts staan in de `document-conversion/` directory en zijn uitvoerbaar.

## Problemen die worden opgelost

✅ **E-reader markup** - Verwijdert Kobo, Kindle en andere e-reader specifieke spans/IDs  
✅ **EPUB namespace** - Schoont EPUB-specifieke attributen op  
✅ **Afbeeldingspaden** - Corrigeert relatieve paden voor EPUB-structuur  
✅ **Pagebreaks** - Converteert naar eenvoudige HTML-commentaren  
✅ **Geneste spans** - Vereenvoudigt complexe span-structuren  
✅ **Semantische markup** - Behoudt belangrijke tekst zoals Grieks/Hebreeuws  
✅ **Structuur** - Bewaart headings, paragrafen en lijsten  

## Gebruik

### Basis gebruik (alle formaten)

```bash
epub-convert input_file.xhtml [output_prefix]
```

**Voorbeelden:**
```bash
epub-convert chapter01.xhtml
epub-convert OEBPS/text/chapter08.xhtml mijn_hoofdstuk
epub-convert /pad/naar/ebook/text/chapter01.xhtml
```

### Specifiek formaat

```bash
epub-convert input_file.xhtml --markdown     # Alleen Markdown
epub-convert input_file.xhtml --org-mode     # Alleen Org-mode  
epub-convert input_file.xhtml --typst        # Alleen Typst
```

### Alleen preprocessing

```bash
epub-preprocess input_file.xhtml [output_file.xhtml]
```

## Uitvoer

**Standaard conversie geeft:**
- `output_prefix.md` (Markdown)
- `output_prefix.org` (Org-mode)
- `output_prefix.typ` (Typst)

## Werkt met elk EPUB

De scripts detecteren automatisch:
- **Verschillende afbeeldingspaden** (`image/`, `images/`, `img/`, `OEBPS/image/`)
- **Verschillende e-readers** (Kobo, Kindle, Adobe, enz.)
- **Verschillende EPUB-structuren** (EPUB2, EPUB3)
- **Verschillende tekstcoderingen** (UTF-8, Latin1)

## Vereisten

- **Python 3** (voor preprocessing)
- **pandoc** (voor conversie)
- **Bash shell** (voor het hoofdscript)

### Pandoc installeren

```bash
# Ubuntu/Debian
sudo apt install pandoc

# macOS  
brew install pandoc

# Windows
# Download van https://pandoc.org/installing.html
```

## Typst compileren

Na conversie naar Typst zijn er twee manieren om te compileren:

**Methode 1: Vanuit text directory (aanbevolen voor EPUB):**
```bash
cd OEBPS/text                           # Ga naar de text directory
typst compile --root ../.. bestand.typ  # Compileer met toegang tot afbeeldingen
```

**Methode 2: Vanuit OEBPS directory:**
```bash
cd OEBPS                       # Ga naar OEBPS directory  
typst compile text/bestand.typ # Compileer vanuit EPUB root
```

**Let op:** De `--root ../..` parameter is nodig zodat Typst toegang heeft tot afbeeldingen in de `../image/` directory. Zonder deze parameter krijg je "access denied" fouten.

## Voorbeelden

### Enkel hoofdstuk converteren
```bash
cd /pad/naar/mijn_ebook/
epub-convert OEBPS/text/chapter01.xhtml hoofdstuk1
```

### Meerdere hoofdstukken (batch)
```bash
cd /pad/naar/mijn_ebook/OEBPS/text/
for file in chapter*.xhtml; do
    epub-convert "$file" "$(basename "$file" .xhtml)"
done
```

### Alleen naar Markdown voor verdere bewerking
```bash
epub-convert complex_chapter.xhtml --markdown
```

## Bewaarde elementen

**Tekst formatting:**
- Vet (`<b>`, `<strong>`) → **tekst**
- Cursief (`<i>`, `<em>`) → *tekst*  
- Griekse tekst (`<span class="sym">`) → [tekst]{.sym}

**Structuur:**
- Hoofdstukken (`<h1>` - `<h6>`)
- Paragrafen (`<p>`)
- Lijsten (`<ul>`, `<ol>`, `<li>`)
- Citaten (`<blockquote>`)

**Metadata:**
- ID's voor kruisverwijzingen
- Pagina-opmerkingen (als HTML-commentaren)

## Tips

1. **Afbeeldingen controleren** - Verifieer paden na conversie
2. **Grote bestanden** - Script werkt ook met grote XHTML-bestanden
3. **Speciale karakters** - UTF-8 encoding wordt automatisch gebruikt
4. **Batch processing** - Gebruik shell loops voor meerdere bestanden

## Bekende beperkingen

- **Voetnoten** - Worden als gewone tekst behandeld (geen speciale voetnootstructuur)
- **Complexe tabellen** - Kunnen handmatige aanpassingen vereisen
- **CSS styling** - Wordt niet geconverteerd (alleen semantische markup)

## Hulp

```bash
epub-convert --help        # Toon help voor conversie script
epub-preprocess            # Toon help voor preprocessing script
```

Voor problemen: controleer dat pandoc geïnstalleerd is en het input bestand bestaat.
