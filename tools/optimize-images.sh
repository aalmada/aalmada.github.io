#!/usr/bin/env bash
set -euo pipefail

# Optimize images in assets/img/posts/:
#   - Auto-orient based on EXIF metadata before any processing
#   - Convert JPG/JPEG/PNG to WebP (quality 82, max 1200px width)
#   - Portrait images are center-cropped to 40:21 landscape (never rotated)
#   - Resize existing WebP if wider than 1200px; crop if portrait
#   - Update all .md references to use .webp extension
#   - Remove original non-WebP files after conversion

IMG_DIR="${1:-assets/img/posts}"
MAX_WIDTH=1200
QUALITY=82
# Target aspect ratio for portrait→landscape crop (Chirpy 40:21 featured image frame)
ASPECT_W=40
ASPECT_H=21
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

# Get effective width and height after EXIF auto-orient (handles phones held sideways)
# EXIF orientations 5-8 indicate a 90° rotation is encoded, swapping w/h
effective_dims() {
  local img="$1" w h orient
  w=$("$IM_CMD" identify -format '%w' "$img" 2>/dev/null || echo 0)
  h=$("$IM_CMD" identify -format '%h' "$img" 2>/dev/null || echo 0)
  orient=$("$IM_CMD" identify -format '%[EXIF:Orientation]' "$img" 2>/dev/null || true)
  case "${orient:-1}" in
    5|6|7|8) echo "$h $w" ;;
    *)       echo "$w $h" ;;
  esac
}

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

  read -r ew eh < <(effective_dims "$img")
  if (( eh > ew )); then
    # Portrait: center-crop to 40:21 landscape, then resize to max width
    crop_h=$(( ew * ASPECT_H / ASPECT_W ))
    echo "  Converting (portrait ${ew}x${eh} → crop ${ew}x${crop_h}): $img → $webp_path"
    $IM_CMD "$img" -auto-orient \
      -gravity Center -crop "${ew}x${crop_h}+0+0" +repage \
      -resize "${MAX_WIDTH}x>" \
      -quality "$QUALITY" "$webp_path"
  else
    echo "  Converting (${ew}x${eh}): $img → $webp_path"
    $IM_CMD "$img" -auto-orient -resize "${MAX_WIDTH}x>" -quality "$QUALITY" "$webp_path"
  fi

  update_references "$basename_old" "${name}.webp"
  rm -f "$img"
  CHANGED=$((CHANGED + 1))
done < <(find "$IMG_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -print0)

# Resize existing WebP files if wider than MAX_WIDTH
while IFS= read -r -d '' img; do
  width=$($IM_CMD identify -format '%w' "$img" 2>/dev/null || echo 0)
  height=$($IM_CMD identify -format '%h' "$img" 2>/dev/null || echo 0)
  if (( height > width )); then
    # Portrait WebP: crop to 40:21 landscape
    crop_h=$(( width * ASPECT_H / ASPECT_W ))
    echo "  Cropping portrait WebP: $img (${width}x${height} → ${width}x${crop_h})"
    $IM_CMD "$img" -gravity Center -crop "${width}x${crop_h}+0+0" +repage \
      -resize "${MAX_WIDTH}x>" -quality "$QUALITY" "$img"
    CHANGED=$((CHANGED + 1))
  elif (( width > MAX_WIDTH )); then
    echo "  Resizing WebP: $img (${width}px → ${MAX_WIDTH}px)"
    $IM_CMD "$img" -resize "${MAX_WIDTH}x>" -quality "$QUALITY" "$img"
    CHANGED=$((CHANGED + 1))
  fi
done < <(find "$IMG_DIR" -type f -iname '*.webp' -print0)

echo "Done. $CHANGED image(s) processed."
