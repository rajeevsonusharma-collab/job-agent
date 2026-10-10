#!/usr/bin/env bash
# Contact sheet PNG for quick visual review. Usage: contact_sheet.sh in.mp4 [every_sec=5] [out=sheet.png]
set -euo pipefail
in="${1:?in}"; n="${2:-5}"; out="${3:-sheet.png}"
ffmpeg -hide_banner -y -i "$in" -vf "fps=1/${n},scale=320:-1,tile=6x4" -frames:v 1 "$out" 2>/dev/null
echo "wrote $out"
