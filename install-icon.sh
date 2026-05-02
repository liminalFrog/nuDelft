#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") -p PNG -d DIR [-s SVG] [-l LINK_NAME]...

  -p PNG        Source PNG (resized into 16, 22, 24, 32, 48 size dirs)
  -s SVG        Source SVG (copied into 96 dir)
  -d DIR        Target category directory containing size subdirs (e.g. Delft/apps)
  -l LINK_NAME  Symlink name(s) to create in each size dir (repeat for multiple)
  -h            Show this help

Symlinks are relative and use the same extension as the source file for that dir.

Example:
  $(basename "$0") -p myapp.png -s myapp.svg -d Delft/apps -l myapp-alias -l myapp-alt
EOF
    exit 1
}

if ! command -v convert &>/dev/null; then
    echo "Error: ImageMagick is required but not installed." >&2
    echo "Install it with: sudo apt install imagemagick" >&2
    exit 1
fi

PNG=""
SVG=""
DIR=""
LINKS=()

while getopts "p:s:d:l:h" opt; do
    case $opt in
        p) PNG="$OPTARG" ;;
        s) SVG="$OPTARG" ;;
        d) DIR="$OPTARG" ;;
        l) LINKS+=("$OPTARG") ;;
        h) usage ;;
        *) usage ;;
    esac
done

[[ -z "$PNG" ]]  && { echo "Error: -p PNG is required"; usage; }
[[ -z "$DIR" ]]  && { echo "Error: -d DIR is required"; usage; }
[[ -f "$PNG" ]]  || { echo "Error: PNG not found: $PNG"; exit 1; }
[[ -d "$DIR" ]]  || { echo "Error: Directory not found: $DIR"; exit 1; }
[[ -n "$SVG" && ! -f "$SVG" ]] && { echo "Error: SVG not found: $SVG"; exit 1; }

ICON_NAME=$(basename "$PNG" .png).png

for size in 48 32 24 22 16; do
    size_dir="$DIR/$size"
    if [[ ! -d "$size_dir" ]]; then
        echo "Warning: $size_dir not found, skipping" >&2
        continue
    fi

    dest="$size_dir/$ICON_NAME"
    convert "$PNG" -resize "${size}x${size}" "$dest"
    echo "Wrote $dest"

    for link in "${LINKS[@]}"; do
        ln -sf "./$ICON_NAME" "$size_dir/$link.png"
        echo "  -> $size_dir/$link.png"
    done
done

if [[ -n "$SVG" ]]; then
    svg_dir="$DIR/96"
    if [[ ! -d "$svg_dir" ]]; then
        echo "Warning: $svg_dir not found, skipping SVG" >&2
    else
        SVG_NAME=$(basename "$SVG" .svg).svg
        cp "$SVG" "$svg_dir/$SVG_NAME"
        echo "Wrote $svg_dir/$SVG_NAME"

        for link in "${LINKS[@]}"; do
            ln -sf "./$SVG_NAME" "$svg_dir/$link.svg"
            echo "  -> $svg_dir/$link.svg"
        done
    fi
fi
