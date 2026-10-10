# ffmpeg Cookbook (video editing)

Conventions: `-ss` before `-i` = fast seek; after `-i` = frame-accurate. Always write to a new file. Add `-y` to overwrite, `-hide_banner` for quieter logs.

## Inspect
```bash
ffprobe -hide_banner -v error -show_entries format=duration,size,bit_rate:stream=index,codec_type,codec_name,width,height,r_frame_rate,avg_frame_rate,pix_fmt,color_space,sample_rate,channels -of default=nw=1 in.mp4
ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate,avg_frame_rate -of csv=p=0 in.mp4   # VFR if the two differ
```

## Cut / Trim / Join
```bash
ffmpeg -ss 00:00:10 -to 00:00:25 -i in.mp4 -c copy out.mp4                          # fast, keyframe-snapped
ffmpeg -ss 10 -i in.mp4 -t 15 -c:v libx264 -crf 18 -preset slow -c:a aac -b:a 192k out.mp4   # frame-accurate
# Concat (identical codecs/params)
printf "file 'a.mp4'\nfile 'b.mp4'\n" > list.txt && ffmpeg -f concat -safe 0 -i list.txt -c copy joined.mp4
# Concat different sources (re-encode, normalize)
ffmpeg -i a.mp4 -i b.mp4 -filter_complex "[0:v]scale=1920:1080,setsar=1,fps=30[v0];[1:v]scale=1920:1080,setsar=1,fps=30[v1];[0:a][1:a]concat=n=2:v=0:a=1[a];[v0][v1]concat=n=2:v=1:a=0[v]" -map "[v]" -map "[a]" out.mp4
# Remove a middle section (keep 0–10s and 20s–end)
ffmpeg -i in.mp4 -filter_complex "[0:v]trim=0:10,setpts=PTS-STARTPTS[v0];[0:a]atrim=0:10,asetpts=PTS-STARTPTS[a0];[0:v]trim=start=20,setpts=PTS-STARTPTS[v1];[0:a]atrim=start=20,asetpts=PTS-STARTPTS[a1];[v0][a0][v1][a1]concat=n=2:v=1:a=1[v][a]" -map "[v]" -map "[a]" out.mp4
```

## Transitions
```bash
# Crossfade video 1 s at offset (clip A length - 1)
ffmpeg -i a.mp4 -i b.mp4 -filter_complex "[0:v][1:v]xfade=transition=fade:duration=1:offset=9[v];[0:a][1:a]acrossfade=d=1[a]" -map "[v]" -map "[a]" out.mp4
# Other xfade: wipeleft, slideright, circleopen, dissolve, fadeblack, smoothleft, zoomin
# Fade in/out
ffmpeg -i in.mp4 -vf "fade=t=in:st=0:d=0.5,fade=t=out:st=9.5:d=0.5" -af "afade=t=in:d=0.5,afade=t=out:st=9.5:d=0.5" out.mp4
```

## Reframe / Scale / Crop
```bash
ffmpeg -i in.mp4 -vf "crop=ih*9/16:ih,scale=1080:1920" -c:a copy vertical.mp4                       # center crop to 9:16
ffmpeg -i in.mp4 -vf "split[a][b];[a]scale=1080:1920,boxblur=30[bg];[b]scale=1080:-2[fg];[bg][fg]overlay=(W-w)/2:(H-h)/2" blurpad.mp4   # blurred-background letterbox
ffmpeg -i in.mp4 -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:black" padded.mp4
ffmpeg -i in.mp4 -vf "crop=w=1080:h=1920:x='(iw-1080)*t/DURATION':y=0" pan.mp4   # slow pan (replace DURATION)
ffmpeg -i in.mp4 -vf "zoompan=z='min(zoom+0.0015,1.3)':d=1:s=1920x1080:fps=30" zoom.mp4  # use on images
```

## Speed & Time
```bash
ffmpeg -i in.mp4 -filter_complex "[0:v]setpts=PTS/1.25[v];[0:a]atempo=1.25[a]" -map "[v]" -map "[a]" fast.mp4    # atempo 0.5–2.0 per stage; chain for more
ffmpeg -i in.mp4 -filter_complex "[0:v]setpts=2*PTS[v];[0:a]atempo=0.5[a]" -map "[v]" -map "[a]" slow.mp4
ffmpeg -i in.mp4 -vf "minterpolate=fps=60:mi_mode=mci" smooth60.mp4         # optical-flow interpolation (slow)
ffmpeg -i in.mp4 -vf "reverse" -af "areverse" reversed.mp4                  # short clips only (memory)
ffmpeg -i in.mp4 -vf "fps=30" -vsync cfr cfr.mp4                            # fix VFR
```

## Audio
```bash
ffmpeg -i in.mp4 -af "loudnorm=I=-14:TP=-1.5:LRA=11" -c:v copy norm.mp4                  # quick
# Two-pass loudnorm: measure then apply
ffmpeg -i in.mp4 -af loudnorm=I=-14:TP=-1.5:LRA=11:print_format=json -f null - 2>&1 | tail -n 14
ffmpeg -i in.mp4 -af "loudnorm=I=-14:TP=-1.5:LRA=11:measured_I=..:measured_TP=..:measured_LRA=..:measured_thresh=..:offset=..:linear=true" -c:v copy out.mp4
ffmpeg -i in.mp4 -af "highpass=f=80,afftdn=nr=12,acompressor=threshold=-18dB:ratio=3:attack=15:release=120,equalizer=f=3500:t=q:w=1:g=2,alimiter=limit=0.89" clean.mp4
# Duck music under voice (sidechain)
ffmpeg -i voice.wav -i music.mp3 -filter_complex "[1:a][0:a]sidechaincompress=threshold=0.05:ratio=8:attack=20:release=400[duck];[0:a][duck]amix=inputs=2:duration=first:dropout_transition=0[a]" -map "[a]" mix.wav
# Mix music at -18 dB under video audio
ffmpeg -i in.mp4 -i music.mp3 -filter_complex "[1:a]volume=-18dB,aloop=loop=-1:size=2e9[m];[0:a][m]amix=inputs=2:duration=first[a]" -map 0:v -map "[a]" -c:v copy out.mp4
ffmpeg -i in.mp4 -vn -c:a pcm_s16le -ar 48000 audio.wav                               # extract
ffmpeg -i in.mp4 -i new.wav -map 0:v -map 1:a -c:v copy -shortest swapped.mp4          # replace audio
ffmpeg -i in.mp4 -af "silenceremove=stop_periods=-1:stop_duration=0.4:stop_threshold=-35dB" gappy.mp4   # NOTE: audio only; use scripts/silence_cut.sh for A/V sync
```

## Text, Captions, Overlays
```bash
ffmpeg -i in.mp4 -vf "subtitles=subs.srt:force_style='FontName=Montserrat ExtraBold,Fontsize=18,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,BorderStyle=1,Outline=3,Alignment=2,MarginV=180'" burned.mp4
ffmpeg -i in.mp4 -vf "drawtext=text='HOOK TEXT':fontfile=/path/Anton.ttf:fontsize=96:fontcolor=white:borderw=6:bordercolor=black:x=(w-text_w)/2:y=h*0.18:enable='between(t,0,2.5)'" out.mp4
ffmpeg -i in.mp4 -i logo.png -filter_complex "[1][0]scale2ref=w=iw*0.12:h=ow/mdar[l][v];[v][l]overlay=W-w-40:40" logo.mp4
ffmpeg -i in.mp4 -i broll.mp4 -filter_complex "[0:v][1:v]overlay=enable='between(t,5,9)':shortest=0" -c:a copy pip.mp4
```

## Stabilize / Denoise / Sharpen / Grade
```bash
ffmpeg -i in.mp4 -vf vidstabdetect=shakiness=5 -f null - && ffmpeg -i in.mp4 -vf vidstabtransform=smoothing=20,unsharp=5:5:0.8 stab.mp4
ffmpeg -i in.mp4 -vf "hqdn3d=3:3:6:6" dn.mp4
ffmpeg -i in.mp4 -vf "unsharp=5:5:0.6:5:5:0.0" sharp.mp4
ffmpeg -i in.mp4 -vf "eq=contrast=1.08:saturation=1.12,curves=preset=medium_contrast" graded.mp4
ffmpeg -i in.mp4 -vf "lut3d=look.cube" lut.mp4
```

## Analysis & QC
```bash
ffmpeg -i in.mp4 -vf "select='gt(scene,0.3)',showinfo" -vsync vfr -f null - 2>&1 | grep pts_time     # scene cuts
ffmpeg -i in.mp4 -af silencedetect=noise=-35dB:d=0.4 -f null - 2>&1 | grep silence_
ffmpeg -i in.mp4 -vf blackdetect=d=0.1:pix_th=0.1 -an -f null - 2>&1 | grep black_
ffmpeg -i in.mp4 -vf freezedetect=n=-60dB:d=1 -an -f null - 2>&1 | grep freeze_
ffmpeg -i in.mp4 -af ebur128=peak=true -f null - 2>&1 | tail -n 14                                   # LUFS / true peak
ffmpeg -i in.mp4 -vf "fps=1/5,scale=320:-1,tile=6x4" -frames:v 1 sheet.png                            # contact sheet
ffmpeg -i a.mp4 -i b.mp4 -lavfi "ssim;[0:v][1:v]psnr" -f null -                                       # compare quality
```

## Proxies, Extraction, Misc
```bash
ffmpeg -i in.mov -vf scale=-2:540 -c:v libx264 -crf 24 -preset veryfast -c:a aac proxy.mp4
ffmpeg -ss 12.5 -i in.mp4 -frames:v 1 -q:v 2 frame.jpg                                                # still
ffmpeg -i in.mp4 -vf "fps=12,scale=720:-1:flags=lanczos,split[a][b];[a]palettegen[p];[b][p]paletteuse" out.gif
ffmpeg -i in.mp4 -map 0:v -map 0:a -c copy -metadata title="Title" tagged.mp4
for f in *.mov; do ffmpeg -i "$f" -c:v libx264 -crf 20 -c:a aac "${f%.mov}.mp4"; done                  # batch
```

## Gotchas
- `-c copy` cuts snap to keyframes; re-encode for frame-accuracy.
- Concat demuxer needs identical codec/fps/timebase/audio params.
- Phone footage is often VFR — conform to CFR before editing/sync.
- Use `-pix_fmt yuv420p` for broad compatibility; `-movflags +faststart` for web.
- Quote filtergraphs carefully; commas inside `if()`/`between()` must be escaped inside `-vf` in some shells.
- Hardware encoders (`h264_nvenc`, `h264_videotoolbox`) are faster, usually lower quality per bit than `libx264`.
