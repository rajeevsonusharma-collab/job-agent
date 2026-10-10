# Platforms, Export & Delivery

> Specs drift. Treat numbers as safe defaults; verify against the platform's current docs when the delivery is critical.

## Platform Cheat Sheet
| Platform | Aspect / Resolution | Length sweet spot | Codec/Bitrate guide | Notes |
|---|---|---|---|---|
| YouTube (long) | 16:9, 1080p/1440p/4K | 8–20 min typical | H.264 8–12 Mbps (1080p), 35–45 (4K); AAC 320k | Upload 4K for better VP9/AV1 re-encode; chapters; end screens last 5–20 s |
| YouTube Shorts | 9:16, 1080×1920 | 15–45 s (max 3 min) | H.264 10–15 Mbps | Loop-friendly; title in first frames |
| Instagram Reels | 9:16, 1080×1920 | 15–30 s (up to 90 s+) | H.264 8–12 Mbps, 30 fps | Keep text out of top ~14% / bottom ~20%; cover frame in grid-safe 4:5 area |
| TikTok | 9:16, 1080×1920 | 15–60 s | H.264 8–12 Mbps | Native captions/sounds; avoid watermarks from other apps |
| Facebook/Meta feed | 4:5 (1080×1350) or 1:1 | 15–60 s | H.264 8 Mbps | Design for sound-off |
| LinkedIn | 1:1 or 4:5 / 16:9 | 30–90 s | H.264 8 Mbps | Captions essential |
| X (Twitter) | 16:9 or 1:1 | < 45 s | H.264 8 Mbps | Max 2:20 (free) |
| Broadcast / OTT | 1080p/4K, specific frame rates | per spec | ProRes 422 HQ / XDCAM / IMF | Follow delivery spec (loudness, safe areas, slate, color bars) |
| Web hero/ads | 16:9, 720–1080p | 6–30 s | H.264 3–6 Mbps + WebM VP9/AV1 | Autoplay muted; <5 MB if possible |
| Podcast video | 16:9 + 9:16 clips | — | H.264 | Audio at −16 LUFS |

## Frame Rate Rules
24/23.976 = cinematic; 25 PAL; 30/29.97 NTSC & social default; 50/60 smooth/sports/gaming; **never frame-rate-convert casually** — match timeline to source; use optical flow/frame blending carefully for conform; shoot 60 fps for slow motion at 24/30 timeline. Always export **constant frame rate**.

## Safe Zones
- 16:9 title-safe: inner 90% (action-safe 93%). Vertical: avoid platform UI zones (top ~14%, bottom ~20%, right ~12% for icons).
- Center important faces/text; test on a phone mockup overlay.

## Export Settings
**Delivery H.264 (default):**
```bash
ffmpeg -i in.mov -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -profile:v high -level 4.2 \
  -colorspace bt709 -color_primaries bt709 -color_trc bt709 -r 30 -vsync cfr \
  -c:a aac -b:a 192k -ar 48000 -movflags +faststart out.mp4
```
**H.265/HEVC (smaller, less compatible):** `-c:v libx265 -crf 22 -tag:v hvc1`.
**Master/archive:** ProRes 422 HQ `-c:v prores_ks -profile:v 3 -pix_fmt yuv422p10le -c:a pcm_s24le` or DNxHR HQX.
**Web-optimized AV1/VP9:** `-c:v libsvtav1 -crf 30 -preset 6` / `-c:v libvpx-vp9 -crf 32 -b:v 0`.
**GIF/WebP preview:** `-vf "fps=12,scale=720:-1:flags=lanczos"` with palettegen/paletteuse.
**Target bitrate when size matters:** two-pass `-b:v` with `-maxrate/-bufsize`.

Rules: export from the highest-quality master, not from a previous lossy export; keep text sharp (no scaling below native); check bit depth; enable "use max render quality"; render audio at 48 kHz; limit to one lossy generation before the platform's own encode.

## Captions & Subtitles
- Deliver **SRT/VTT** for accessibility and SEO, plus **burned-in** styled captions for social.
- Timing: 1–7 s per caption, ≤ 17 characters/second reading speed, break at phrase boundaries, ≤ 2 lines.
- Accuracy: proofread names/brands; mark sound cues for accessibility `[music]`, `[applause]`.
- Multi-language: translate from cleaned transcript; check line-length expansion (German, Hindi); right-to-left layout for Arabic/Hebrew; fonts that support the script.

## Thumbnails & Metadata
Provide cover frame/thumbnail still, title options, description with timestamps (chapters), tags/hashtags, alt text, and end-screen/CTA plan. Embed metadata: `-metadata title="…" -metadata comment="…"`.

## Delivery Package (client)
`/Final`: master + platform versions; `/Captions`: SRT/VTT; `/Stems`: audio stems; `/Graphics`: project-free assets; `/Docs`: cut sheet, music licenses, release forms; naming `Project_Title_Platform_AR_Res_FPS_vNN_YYYYMMDD.ext`. Include checksum (`shasum -a 256`) for large deliveries.

## Archiving
Consolidate/Trim media; keep project file + proxies + original footage on 3-2-1 backup (3 copies, 2 media, 1 offsite); document software version, plugins, fonts, LUTs.
