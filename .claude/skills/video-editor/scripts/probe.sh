#!/usr/bin/env bash
# Concise technical summary of a media file. Usage: probe.sh <file>
set -euo pipefail
f="${1:?usage: probe.sh <file>}"
[ -f "$f" ] || { echo "not found: $f" >&2; exit 1; }
echo "== $f"
ffprobe -v error -show_entries format=format_name,duration,size,bit_rate -of default=nw=1 "$f"
echo "-- video"
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,profile,width,height,pix_fmt,r_frame_rate,avg_frame_rate,color_space,color_transfer,color_primaries,bit_rate,nb_frames -of default=nw=1 "$f" || true
echo "-- audio"
ffprobe -v error -select_streams a -show_entries stream=codec_name,sample_rate,channels,channel_layout,bit_rate -of default=nw=1 "$f" || true
r=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$f" 2>/dev/null || true)
a=$(ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of csv=p=0 "$f" 2>/dev/null || true)
if [ -n "$r" ] && [ "$r" != "$a" ]; then
  echo "!! r_frame_rate ($r) != avg_frame_rate ($a): likely variable frame rate; conform to CFR before editing"
fi
