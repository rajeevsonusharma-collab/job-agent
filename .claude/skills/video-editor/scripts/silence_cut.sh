#!/usr/bin/env bash
# Remove silences from talking-head video, keeping A/V in sync (re-encodes).
# Usage: silence_cut.sh in.mp4 out.mp4 [thresh_dB=-35] [min_silence=0.4] [pad=0.08]
set -euo pipefail
in="${1:?in}"; out="${2:?out}"; th="${3:--35}"; ms="${4:-0.4}"; pad="${5:-0.08}"
dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$in")
tmp=$(mktemp)
ffmpeg -hide_banner -nostats -i "$in" -af "silencedetect=noise=${th}dB:d=${ms}" -f null - 2>&1 | grep -E "silence_(start|end)" > "$tmp" || true
python3 - "$tmp" "$dur" "$pad" > "$tmp.filter" <<'PY'
import re, sys
log, dur, pad = open(sys.argv[1]).read(), float(sys.argv[2]), float(sys.argv[3])
starts = [float(x) for x in re.findall(r"silence_start: ([\d.]+)", log)]
ends = [float(x) for x in re.findall(r"silence_end: ([\d.]+)", log)]
keep, cur = [], 0.0
for i, s in enumerate(starts):
    e = ends[i] if i < len(ends) else dur
    a, b = cur, min(dur, s + pad)           # keep speech plus a small tail
    if b - a > 0.05: keep.append((a, b))
    cur = max(0.0, e - pad)                 # resume slightly before speech
if dur - cur > 0.05: keep.append((cur, dur))
if not keep: keep = [(0.0, dur)]
parts = []
for i, (a, b) in enumerate(keep):
    parts.append(f"[0:v]trim={a:.3f}:{b:.3f},setpts=PTS-STARTPTS[v{i}];[0:a]atrim={a:.3f}:{b:.3f},asetpts=PTS-STARTPTS[a{i}]")
cat = "".join(f"[v{i}][a{i}]" for i in range(len(keep)))
print(";".join(parts) + f";{cat}concat=n={len(keep)}:v=1:a=1[v][a]")
PY
ffmpeg -hide_banner -loglevel error -y -i "$in" -filter_complex_script "$tmp.filter" -map "[v]" -map "[a]" \
  -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart "$out"
rm -f "$tmp" "$tmp.filter"
echo "wrote $out (original ${dur}s)"
