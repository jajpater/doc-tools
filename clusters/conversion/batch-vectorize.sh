#!/bin/bash
# batch-vectorize.sh
# Converteer alle JPG en WEBP bestanden in een map naar SVG

# Zorg dat je deze tools hebt:
# sudo apt install imagemagick potrace

shopt -s nullglob
for img in *.jpg *.jpeg *.webp; do
    base="${img%.*}"
    echo "Verwerk: $img → $base.svg"

    # 1. Eerst naar PNM (bitmapformaat voor potrace)
    convert "$img" -colorspace Gray "$base.pnm"

    # 2. Vectoriseer naar SVG
    potrace "$base.pnm" -s -o "$base.svg"

    # 3. (Optioneel) verwijder tussenbestand
    rm "$base.pnm"
done

