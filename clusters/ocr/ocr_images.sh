#!/usr/bin/env bash
set -euo pipefail

# Flexible OCR for a folder of images (build PDF -> OCR -> extract text).
#
# Gebruik:
#   ./ocr_images.sh [OPTIES] [MAP] [OUTPUT_BASENAME]
#
# Voorbeelden:
#   ./ocr_images.sh
#   ./ocr_images.sh scans/
#   ./ocr_images.sh scans/ document_ocr
#   ./ocr_images.sh --lang "eng+heb" scans/
#   ./ocr_images.sh --pattern "*.jpg" scans/
#   ./ocr_images.sh --single-sided scans/
#
# Opties (kort):
#   --lang, --pattern, --single-sided, --double-sided, --verbose, --dry-run
#
# Dependencies:
#   img2pdf, ocrmypdf, pdftotext

show_help() {
    cat << EOF
Generic OCR Script - Flexibele OCR verwerking

GEBRUIK:
    $0 [OPTIES] [MAP] [OUTPUT_BASENAME]

OPTIES:
    -h, --help              Toon deze help
    -l, --lang TALEN        OCR talen (standaard: nld+eng)
    -p, --pattern PATROON   Bestandspatroon (standaard: auto-detectie)
    -s, --single-sided      Forceer enkelzijdige verwerking
    -d, --double-sided      Forceer dubbelzijdige verwerking
    -v, --verbose           Uitgebreide output
    --dry-run              Toon alleen welke bestanden gevonden worden

ARGUMENTEN:
    MAP                     Input map (standaard: huidige map)
    OUTPUT_BASENAME         Output bestandsnaam basis (standaard: auto)

VOORBEELDEN:
    $0                                    # Auto-detectie in huidige map
    $0 scans/                            # Scan specifieke map
    $0 --lang "eng+deu" documents/       # Duitse en Engelse OCR
    $0 --pattern "page*.tif" scans/      # Alleen TIFF bestanden met 'page'
    $0 --single-sided photos/            # Behandel als losse pagina's

ONDERSTEUNDE FORMATEN:
    jpg, jpeg, png, tif, tiff, bmp

BESTANDSPATRONEN:
    Auto-detecteert: numerieke volgorde, datum-tijd, alfabetisch
    Dubbelzijdig: detecteert L/R, 1/2, odd/even patronen
EOF
}

# Standaard waarden
INDIR="."
OUTBASE=""
LANGS="nld+eng"
PATTERN=""
FORCE_MODE=""  # single, double, of leeg voor auto
VERBOSE=false
DRY_RUN=false

# Parse command line argumenten
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -l|--lang)
            LANGS="$2"
            shift 2
            ;;
        -p|--pattern)
            PATTERN="$2"
            shift 2
            ;;
        -s|--single-sided)
            FORCE_MODE="single"
            shift
            ;;
        -d|--double-sided)
            FORCE_MODE="double"
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -*)
            echo "Onbekende optie: $1" >&2
            echo "Gebruik --help voor hulp" >&2
            exit 1
            ;;
        *)
            if [[ -z "$INDIR" || "$INDIR" == "." ]]; then
                INDIR="$1"
            elif [[ -z "$OUTBASE" ]]; then
                OUTBASE="$1"
            else
                echo "Te veel argumenten: $1" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

# Controleer of input directory bestaat
if [[ ! -d "$INDIR" ]]; then
    echo "Map niet gevonden: $INDIR" >&2
    exit 1
fi

# Vereiste tools checken
need() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Missing: $1" >&2
        exit 1
    }
}

need img2pdf
need ocrmypdf
need pdftotext

# Verbose logging functie
log() {
    if $VERBOSE; then
        echo ">> $*" >&2
    fi
}

# Zoek alle afbeeldingsbestanden
find_image_files() {
    local dir="$1"
    local pattern="$2"

    if [[ -n "$pattern" ]]; then
        find "$dir" -maxdepth 1 -type f -name "$pattern" | sort -V
    else
        # Auto-detectie: zoek alle ondersteunde formaten
        find "$dir" -maxdepth 1 -type f \( \
            -iname "*.jpg" -o -iname "*.jpeg" -o \
            -iname "*.png" -o -iname "*.tif" -o \
            -iname "*.tiff" -o -iname "*.bmp" \
        \) | sort -V
    fi
}

# Detecteer of bestanden dubbelzijdig zijn (L/R, 1/2, odd/even patronen)
detect_double_sided() {
    local files=("$@")
    local double_indicators=0

    for file in "${files[@]}"; do
        local basename=$(basename "$file")
        if [[ "$basename" =~ [12][LR]|[LR][12]|_[LR]_|_[12]_|left|right|odd|even ]]; then
            ((double_indicators++))
        fi
    done

    # Als meer dan 30% van de bestanden dubbelzijdig-indicatoren hebben
    if (( double_indicators * 100 / ${#files[@]} > 30 )); then
        return 0  # dubbelzijdig
    else
        return 1  # enkelzijdig
    fi
}

# Sorteer dubbelzijdige bestanden (probeer L voor R, 1 voor 2, etc.)
sort_double_sided() {
    local files=("$@")
    local -A page_map
    local -a ordered

    # Probeer verschillende patronen te extracteren
    for file in "${files[@]}"; do
        local basename=$(basename "$file")
        local page_num=""
        local side=""

        # Patroon 1: prefix_pageXXXX_[12][LR]
        if [[ "$basename" =~ (.+)_page([0-9]+)_([12][LR]) ]]; then
            page_num="${BASH_REMATCH[2]}"
            side="${BASH_REMATCH[3]}"
        # Patroon 2: prefix_XXXX_[LR]
        elif [[ "$basename" =~ (.+)_([0-9]+)_([LR]) ]]; then
            page_num="${BASH_REMATCH[2]}"
            side="${BASH_REMATCH[3]}"
        # Patroon 3: prefixXXXX[LR]
        elif [[ "$basename" =~ (.+)([0-9]+)([LR]) ]]; then
            page_num="${BASH_REMATCH[2]}"
            side="${BASH_REMATCH[3]}"
        # Patroon 4: left/right in naam
        elif [[ "$basename" =~ (.+)([0-9]+).*left ]]; then
            page_num="${BASH_REMATCH[2]}"
            side="L"
        elif [[ "$basename" =~ (.+)([0-9]+).*right ]]; then
            page_num="${BASH_REMATCH[2]}"
            side="R"
        fi

        if [[ -n "$page_num" && -n "$side" ]]; then
            # Normaliseer side naar L/R
            case "$side" in
                1L|L|left) side="L" ;;
                2R|R|right) side="R" ;;
            esac

            page_map["$(printf "%04d" "$((10#$page_num))"),$side"]="$file"
        else
            # Fallback: gewoon toevoegen zonder sortering
            ordered+=("$file")
        fi
    done

    # Sorteer pagina's en voeg L/R paren toe
    local -a page_numbers
    mapfile -t page_numbers < <(printf "%s\n" "${!page_map[@]}" | cut -d, -f1 | sort -u)

    for page in "${page_numbers[@]}"; do
        for side in L R; do
            local key="$page,$side"
            if [[ -n "${page_map[$key]+set}" ]]; then
                ordered+=("${page_map[$key]}")
            fi
        done
    done

    printf "%s\n" "${ordered[@]}"
}

# Hoofdlogica
main() {
    log "Zoeken naar afbeeldingsbestanden in: $INDIR"

    mapfile -t FILES < <(find_image_files "$INDIR" "$PATTERN")

    if [[ ${#FILES[@]} -eq 0 ]]; then
        echo "Geen afbeeldingsbestanden gevonden in: $INDIR" >&2
        if [[ -n "$PATTERN" ]]; then
            echo "Patroon: $PATTERN" >&2
        fi
        exit 1
    fi

    log "Gevonden ${#FILES[@]} bestanden"

    if $DRY_RUN; then
        echo "Gevonden bestanden:"
        printf "%s\n" "${FILES[@]}"
        exit 0
    fi

    # Auto-detectie of expliciet geforceerd mode
    local is_double_sided=false
    case "$FORCE_MODE" in
        single)
            log "Geforceerd enkelzijdig"
            ;;
        double)
            log "Geforceerd dubbelzijdig"
            is_double_sided=true
            ;;
        *)
            if detect_double_sided "${FILES[@]}"; then
                log "Auto-detectie: dubbelzijdig"
                is_double_sided=true
            else
                log "Auto-detectie: enkelzijdig"
            fi
            ;;
    esac

    # Sorteer bestanden
    local -a ordered_files
    if $is_double_sided; then
        log "Sorteren als dubbelzijdige pagina's"
        mapfile -t ordered_files < <(sort_double_sided "${FILES[@]}")
    else
        log "Sorteren als enkelzijdige pagina's"
        mapfile -t ordered_files < <(printf "%s\n" "${FILES[@]}" | sort -V)
    fi

    if [[ ${#ordered_files[@]} -eq 0 ]]; then
        echo "Geen bestanden om te verwerken na sortering" >&2
        exit 1
    fi

    # Bepaal output basename als niet opgegeven
    if [[ -z "$OUTBASE" ]]; then
        local dir_name=$(basename "$(realpath "$INDIR")")
        if [[ "$dir_name" == "." ]]; then
            OUTBASE="ocr_output"
        else
            OUTBASE="${dir_name}_ocr"
        fi
    fi

    # Output bestanden
    local TMPPDF="${OUTBASE}_images.pdf"
    local OUTPDF="${OUTBASE}.pdf"
    local TXTOUT="${OUTBASE}.txt"
    local MDOUT="${OUTBASE}.md"
    local ORGOUT="${OUTBASE}.org"
    local TYPSTOUT="${OUTBASE}.typst"

    log "Output basis: $OUTBASE"
    log "Verwerken van ${#ordered_files[@]} bestanden met talen: $LANGS"

    if $VERBOSE; then
        echo "Bestandsvolgorde:"
        printf "  %s\n" "${ordered_files[@]}"
    fi

    echo ">> Stap 1: Bouw tussen-PDF van afbeeldingen met img2pdf"
    img2pdf "${ordered_files[@]}" -o "$TMPPDF"

    echo ">> Stap 2: OCR met OCRmyPDF ($LANGS)"
    ocrmypdf -l "$LANGS" --rotate-pages --deskew --optimize 3 --output-type pdfa "$TMPPDF" "$OUTPDF"

    echo ">> Stap 3: Tekst extraheren met pdftotext"
    pdftotext "$OUTPDF" "$TXTOUT"

    echo ">> Stap 4: Schrijf Markdown / Org / Typst"

    # Markdown
    {
        echo "# ${OUTBASE}"
        echo
        awk '
            {
                gsub(/\f/,"\n\n---\n\n",$0);
                print $0
            }
        ' "$TXTOUT"
    } > "$MDOUT"

    # Org
    {
        echo "#+TITLE: ${OUTBASE}"
        echo
        awk '
            {
                gsub(/\f/,"\n\n-----\n\n",$0);
                print $0
            }
        ' "$TXTOUT"
    } > "$ORGOUT"

    # Typst
    {
        echo "= ${OUTBASE}"
        echo
        echo "#let pb = [---]"
        echo
        awk '
            {
                gsub(/\f/,"\n\n#pb\n\n",$0);
                print $0
            }
        ' "$TXTOUT"
    } > "$TYPSTOUT"

    # Ruim tijdelijk PDF op
    rm -f "$TMPPDF"

    echo "Klaar:"
    echo "  PDF  : $OUTPDF"
    echo "  TXT  : $TXTOUT"
    echo "  MD   : $MDOUT"
    echo "  ORG  : $ORGOUT"
    echo "  TYPST: $TYPSTOUT"
}

# Start hoofdfunctie
main "$@"
