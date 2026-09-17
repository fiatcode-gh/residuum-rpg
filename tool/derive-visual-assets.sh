#!/usr/bin/env bash
set -euo pipefail

if ! command -v magick >/dev/null 2>&1; then
  echo "error: magick (ImageMagick) is required on PATH" >&2
  exit 1
fi

masters="art/visual-reboot"
if [[ ! -d "$masters" ]]; then
  echo "error: $masters is missing; nothing to derive from" >&2
  exit 1
fi

out_environments="packages/app/assets/visual/environments"
out_dungeon="packages/app/assets/visual/dungeon"
out_icons="packages/app/assets/visual/icons"
mkdir -p "$out_environments" "$out_dungeon" "$out_icons"

derive_environment() {
  local master=$1 offset=$2 out=$3
  magick "$master" \
    -crop "1254x502+0+${offset}" +repage -resize 1080x432! \
    -quality 82 -sampling-factor 4:2:0 -strip \
    "$out"
  echo "$out"
}

derive_sheet() {
  local master=$1 out=$2
  local target_std=0.05
  local highpass
  highpass="$(mktemp --suffix=.miff)"
  trap 'rm -f "$highpass"' RETURN
  magick "$master" -colorspace Gray -resize 576x576! \
    \( +clone -blur 0x24 \) \
    -compose Mathematics -define compose:args='0,-1,1,0.5' -composite \
    "$highpass"
  local std gain bias
  std=$(magick "$highpass" -format "%[fx:standard_deviation]" info:)
  gain=$(awk -v t="$target_std" -v s="$std" 'BEGIN { printf "%.10f", t / s }')
  bias=$(awk -v g="$gain" 'BEGIN { printf "%.10f", 0.5 - 0.5 * g }')
  magick "$highpass" -function polynomial "${gain},${bias}" -depth 8 -strip "$out"
  echo "$out"
}

derive_overlay() {
  local master=$1 out=$2
  magick "$master" -colorspace Gray -resize 144x144 -strip "$out"
  echo "$out"
}

derive_icon() {
  local master=$1 out=$2
  magick "$master" -background none -resize 72x72 -strip "$out"
  echo "$out"
}

derive_environment "$masters/environments/ENV-001_stonebridge.png" 251 \
  "$out_environments/stonebridge.jpg"
derive_environment "$masters/environments/ENV-002_forge.png" 439 \
  "$out_environments/forge.jpg"
derive_environment "$masters/environments/ENV-003_tavern.png" 439 \
  "$out_environments/tavern.jpg"

derive_sheet "$masters/dungeon/crypt/DNG-001_crypt_floor_base.png" \
  "$out_dungeon/crypt_floor.png"
derive_sheet "$masters/dungeon/crypt/DNG-002_crypt_wall_base.png" \
  "$out_dungeon/crypt_wall.png"
derive_sheet "$masters/dungeon/sea_cave/DNG-SC-001_sea_cave_floor_material_source.png" \
  "$out_dungeon/sea_cave_floor.png"
derive_sheet "$masters/dungeon/sea_cave/DNG-SC-002_sea_cave_wall_material_source.png" \
  "$out_dungeon/sea_cave_wall.png"
derive_sheet "$masters/dungeon/ruined_keep/DNG-RK-001_ruined_keep_floor_material_source.png" \
  "$out_dungeon/ruined_keep_floor.png"
derive_sheet "$masters/dungeon/ruined_keep/DNG-RK-002_ruined_keep_wall_material_source.png" \
  "$out_dungeon/ruined_keep_wall.png"

derive_overlay "$masters/dungeon/crypt/DNG-003_crypt_crack_overlay_a.png" \
  "$out_dungeon/crypt_crack_a.png"
derive_overlay "$masters/dungeon/crypt/DNG-004_crypt_crack_overlay_b.png" \
  "$out_dungeon/crypt_crack_b.png"
derive_overlay "$masters/dungeon/crypt/DNG-005_crypt_rubble_small.png" \
  "$out_dungeon/crypt_rubble_small.png"
derive_overlay "$masters/dungeon/crypt/DNG-006_crypt_rubble_medium.png" \
  "$out_dungeon/crypt_rubble_medium.png"
derive_overlay "$masters/dungeon/sea_cave/DNG-SC-003_sea_cave_crack_overlay_a.png" \
  "$out_dungeon/sea_cave_crack_a.png"
derive_overlay "$masters/dungeon/sea_cave/DNG-SC-004_sea_cave_crack_overlay_b.png" \
  "$out_dungeon/sea_cave_crack_b.png"
derive_overlay "$masters/dungeon/sea_cave/DNG-SC-005_sea_cave_rubble_small.png" \
  "$out_dungeon/sea_cave_rubble_small.png"
derive_overlay "$masters/dungeon/sea_cave/DNG-SC-006_sea_cave_rubble_medium.png" \
  "$out_dungeon/sea_cave_rubble_medium.png"
derive_overlay "$masters/dungeon/ruined_keep/DNG-RK-003_ruined_keep_fracture_overlay_a.png" \
  "$out_dungeon/ruined_keep_crack_a.png"
derive_overlay "$masters/dungeon/ruined_keep/DNG-RK-004_ruined_keep_fracture_overlay_b.png" \
  "$out_dungeon/ruined_keep_crack_b.png"
derive_overlay "$masters/dungeon/ruined_keep/DNG-RK-005_ruined_keep_rubble_small.png" \
  "$out_dungeon/ruined_keep_rubble_small.png"
derive_overlay "$masters/dungeon/ruined_keep/DNG-RK-006_ruined_keep_rubble_medium.png" \
  "$out_dungeon/ruined_keep_rubble_medium.png"

derive_icon "$masters/ui/icons/UI-P0-001_potion.png" "$out_icons/potion.png"
derive_icon "$masters/ui/icons/UI-P0-002_pack.png" "$out_icons/pack.png"
derive_icon "$masters/ui/icons/UI-P0-003_wait.png" "$out_icons/wait.png"
derive_icon "$masters/ui/icons/UI-P0-004_ascend.png" "$out_icons/ascend.png"
derive_icon "$masters/ui/icons/UI-P0-005_descend.png" "$out_icons/descend.png"
derive_icon "$masters/ui/icons/UI-P0-007_firebolt.png" "$out_icons/firebolt.png"
derive_icon "$masters/ui/icons/UI-P0-008_mend.png" "$out_icons/mend.png"
derive_icon "$masters/ui/icons/UI-P0-009_more.png" "$out_icons/more.png"
