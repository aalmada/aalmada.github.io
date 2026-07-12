#!/usr/bin/env bash
set -euo pipefail

# Optimize images in assets/img/posts/:
#   - Convert JPG/JPEG/PNG to WebP (quality 82, max 1200px width)
#   - Resize existing WebP if wider than 1200px
#   - Update all .md references to use .webp extension
#   - Remove original non-WebP files after conversion

IMG_DIR="${1:-assets/img/posts}"
MAX_WIDTH=1200
QUALITY=82
CHANGED=0

if ! command -v magick &>/dev/null && ! command -v convert &>/dev/null; then
  echo "ERROR: ImageMagick is required but not found." >&2
  exit 1
fi

# Use magick (v7) if available, otherwise fall back to convert (v6)
if command -v magick &>/dev/null; then
  IM_CMD="magick"
else
  IM_CMD="convert"
fi

# Collect all markdown files that may reference images
MD_FILES=()
while IFS= read -r -d '' f; do
  MD_FILES+=("$f")
done < <(find _posts _tabs -name '*.md' -print0 2>/dev/null)

update_references() {
  local old_basename="$1"  # e.g. "Photo.jpg"
  local new_basename="$2"  # e.g. "Photo.webp"

  # Skip if extension didn't change
  [[ "$old_basename" == "$new_basename" ]] && return

  local old_name="${old_basename%.*}"
  local old_ext="${old_basename##*.}"

  # Build URL-encoded variant for filenames with spaces
  local old_encoded="${old_basename// /%20}"
  local new_encoded="${new_basename// /%20}"

  for md in "${MD_FILES[@]}"; do
    # Replace exact filename (plain and URL-encoded)
    if grep -qF "$old_basename" "$md" 2>/dev/null; then
      sed -i "s|${old_basename}|${new_basename}|g" "$md"
    fi
    if [[ "$old_encoded" != "$old_basename" ]] && grep -qF "$old_encoded" "$md" 2>/dev/null; then
      sed -i "s|${old_encoded}|${new_encoded}|g" "$md"
    fi
  done
}

echo "Optimizing images in $IMG_DIR (max ${MAX_WIDTH}px, WebP quality ${QUALITY})..."

# Process JPG/JPEG/PNG → WebP
while IFS= read -r -d '' img; do
  basename_old="$(basename "$img")"
  name="${basename_old%.*}"
  dir="$(dirname "$img")"
  webp_path="${dir}/${name}.webp"

  echo "  Converting: $img → $webp_path"
  $IM_CMD "$img" -resize "${MAX_WIDTH}x>${MAX_WIDTH}" -quality "$QUALITY" "$webp_path"

  update_references "$basename_old" "${name}.webp"
  rm -f "$img"
  CHANGED=$((CHANGED + 1))
done < <(find "$IMG_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -print0)

# Resize existing WebP files if wider than MAX_WIDTH
while IFS= read -r -d '' img; do
  width=$($IM_CMD identify -format '%w' "$img" 2>/dev/null || echo 0)
  if (( width > MAX_WIDTH )); then
    echo "  Resizing WebP: $img (${width}px → ${MAX_WIDTH}px)"
    $IM_CMD "$img" -resize "${MAX_WIDTH}x>${MAX_WIDTH}" -quality "$QUALITY" "$img"
    CHANGED=$((CHANGED + 1))
  fi
done < <(find "$IMG_DIR" -type f -iname '*.webp' -print0)

echo "Done. $CHANGED image(s) processed."
