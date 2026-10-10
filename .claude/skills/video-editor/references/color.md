# Color: Correct, Match, Grade

## Workflow
1. **Color-manage** the project (input transform → working space → output transform). Common: DaVinci Wide Gamut/Intermediate or ACES; Rec.709 gamma 2.4 for broadcast, sRGB/2.2 for web; Rec.2020 + PQ/HLG for HDR.
2. **Normalize** log footage (camera LUT/CST), not a heavy "look" LUT as step 1.
3. **Correct** per shot: exposure → contrast → white balance → saturation.
4. **Match** shots in a scene to a hero frame (use scopes, split-screen, reference stills).
5. **Grade** the look (creative intent) at group/timeline level.
6. **Finish**: secondary fixes (skin, sky), power windows/tracking, noise reduction, grain, sharpening, vignette, halation/bloom.
7. **QC** gamut/legal levels and compare against references on a calibrated display.

## Scopes (trust them over your eyes)
- **Waveform:** exposure & contrast; keep highlights < ~95% unless stylized; blacks ≥ ~2–5% for web unless intentional.
- **RGB parade:** balance; neutrals should align across channels.
- **Vectorscope:** saturation & hue; **skin tones land on the skin-tone (I) line** regardless of ethnicity (vary distance/saturation, not hue).
- **Histogram:** clipping detection.

## Corrections Reference
| Issue | Fix |
|---|---|
| Underexposed | Lift gain/mids, avoid noise blowup; denoise before lifting |
| Blown highlights | Roll-off highlights with curves/soft clip; recover from log/RAW |
| Color cast | Eyedropper on neutral, then tweak temp/tint; fix per shot |
| Flat log | Contrast + pivot, S-curve, saturation ~100–120% post-transform |
| Mixed lighting | Qualifier/power window per light source |
| Skin green/magenta | Tint toward the skin line; isolate with qualifier, soften |
| Mismatched cameras | Match primaries and gamma first, then fine-tune hue vs hue |

## Looks (cinematic recipes)
- **Teal & orange:** teal in shadows (lift blue/cyan), warm highlights/skin; protect skin hue.
- **Clean commercial:** neutral contrast, bright, slightly cool whites, saturated brand colors.
- **Moody/filmic:** lower highlights, lifted milky blacks, desaturated mids, subtle grain.
- **Vintage/film emulation:** gentle contrast, warm highlight bias, halation, grain 4–8%.
- **Social "pop":** contrast +, vibrance +, crisp sharpening, bright skin — avoid crushed blacks and posterization after compression.

## Tools & Techniques
Primary wheels (lift/gamma/gain), curves (custom, hue-vs-hue/sat/lum), qualifiers (HSL keys), power windows with tracking, parallel/layer nodes, LUTs (technical vs creative, apply at the correct stage), film grain, glow/halation, skin retouch (subtle), depth/sky replacement (only when disclosed/appropriate).

## HDR Notes
Grade on an HDR-capable reference monitor; set MaxCLL/MaxFALL; deliver an SDR trim; PQ (HDR10/Dolby Vision) vs HLG (broadcast); never upconvert SDR to "fake HDR" for delivery.

## ffmpeg Color Basics
```bash
# Quick correction (brightness/contrast/saturation/gamma)
ffmpeg -i in.mp4 -vf "eq=brightness=0.04:contrast=1.08:saturation=1.12:gamma=1.0" -c:a copy out.mp4

# Apply a 3D LUT (.cube)
ffmpeg -i in.mp4 -vf "lut3d=look.cube" -c:a copy out.mp4

# Convert BT.2020/HLG-ish to SDR (tonemap)
ffmpeg -i hdr.mp4 -vf "zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p" -c:a copy sdr.mp4

# Tag output color metadata properly
ffmpeg -i in.mp4 -c:v libx264 -colorspace bt709 -color_primaries bt709 -color_trc bt709 -pix_fmt yuv420p out.mp4
```

## Common Pitfalls
Grading on a non-calibrated or bright-room display; crushing blacks that re-appear as banding after compression; over-saturated reds; clipping chroma; inconsistent grade between cuts; ignoring gamma shift (QuickTime vs browser); delivering full-range into limited-range pipelines.
