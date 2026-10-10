#!/usr/bin/env bash
# QC report: specs, loudness, black frames, freezes, silence. Usage: qc.sh <file> [target_lufs=-14]
set -uo pipefail
f="${1:?usage: qc.sh <file> [target_lufs]}"; target="${2:--14}"
[ -f "$f" ] || { echo "not found: $f" >&2; exit 1; }
flags=0
echo "== QC: $f"
w=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height,pix_fmt,r_frame_rate,avg_frame_rate,codec_name -of csv=p=0 "$f")
echo "video: $w"
IFS=, read -r codec W H pf rfr afr <<<"$w"
[ "$pf" != "yuv420p" ] && { echo "WARN pix_fmt=$pf (web/social expect yuv420p)"; flags=$((flags+1)); }
[ "$rfr" != "$afr" ] && { echo "WARN variable frame rate suspected ($rfr vs $afr)"; flags=$((flags+1)); }
ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,sample_rate,channels -of csv=p=0 "$f" | sed 's/^/audio: /'
has_audio=$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$f" | head -1)
if [ -n "$has_audio" ]; then
  out=$(ffmpeg -hide_banner -nostats -i "$f" -af ebur128=peak=true -f null - 2>&1)
  I=$(echo "$out" | awk '/^ *I:/{v=$2} END{print v}')
  TP=$(echo "$out" | awk '/Peak:/{v=$2} END{print v}')
  LRA=$(echo "$out" | awk '/LRA:/{v=$2} END{print v}')
  echo "loudness: I=${I:-?} LUFS  TP=${TP:-?} dBTP  LRA=${LRA:-?} LU  (target $target LUFS, TP <= -1)"
  if [ -n "${I:-}" ]; then
    awk -v i="$I" -v t="$target" 'BEGIN{d=i-t; if(d<0)d=-d; if(d>1.5) exit 1}' || { echo "WARN integrated loudness off target by >1.5 LU"; flags=$((flags+1)); }
  fi
  if [ -n "${TP:-}" ]; then awk -v p="$TP" 'BEGIN{exit !(p>-1.0)}' && { echo "WARN true peak above -1 dBTP"; flags=$((flags+1)); }; fi
  s=$(ffmpeg -hide_banner -nostats -i "$f" -af silencedetect=noise=-45dB:d=1 -f null - 2>&1 | grep -c silence_start || true)
  [ "$s" -gt 0 ] && { echo "WARN $s silent gap(s) >=1s (check timestamps with silencedetect)"; flags=$((flags+1)); }
else
  echo "WARN no audio stream"; flags=$((flags+1))
fi
b=$(ffmpeg -hide_banner -nostats -i "$f" -vf blackdetect=d=0.1:pix_th=0.10 -an -f null - 2>&1 | grep -E "black_start" || true)
[ -n "$b" ] && { echo "WARN black segments:"; echo "$b" | sed 's/.*\(black_start:[^ ]*\).*\(black_end:[^ ]*\).*/  \1 \2/'; flags=$((flags+1)); }
z=$(ffmpeg -hide_banner -nostats -i "$f" -vf freezedetect=n=-60dB:d=1.5 -an -f null - 2>&1 | grep -E "freeze_start" || true)
[ -n "$z" ] && { echo "WARN frozen frames:"; echo "$z" | sed 's/.*\(lavfi.freezedetect.freeze_start: [0-9.]*\).*/  \1/'; flags=$((flags+1)); }
echo "== $flags flag(s)"
exit 0
