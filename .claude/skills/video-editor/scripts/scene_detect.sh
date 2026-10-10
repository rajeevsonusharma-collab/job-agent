#!/usr/bin/env bash
# List detected cut points (seconds). Usage: scene_detect.sh in.mp4 [threshold=0.3]
set -euo pipefail
in="${1:?in}"; th="${2:-0.3}"
ffmpeg -hide_banner -nostats -i "$in" -vf "select='gt(scene,${th})',showinfo" -vsync vfr -an -f null - 2>&1 \
 | grep -o "pts_time:[0-9.]*" | cut -d: -f2 | awk '{printf "%.3f\n",$1}'
