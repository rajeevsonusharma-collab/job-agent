# NLE Workflows, Shortcuts & Scripting

## Choosing a Tool
| Tool | Best for |
|---|---|
| DaVinci Resolve (free/Studio) | Color, Fairlight audio, Fusion VFX, all-in-one finishing |
| Adobe Premiere Pro (+ After Effects, Audition) | Team workflows, motion graphics via AE, wide plugin ecosystem, text-based editing |
| Final Cut Pro | Fast Mac editing, magnetic timeline, multicam, great performance on Apple silicon |
| CapCut / VN / InShot | Rapid mobile & short-form with templates, auto-captions |
| Descript | Transcript/podcast editing, filler removal, overdub |
| Avid Media Composer | Broadcast/film long-form, collaborative bin locking |
| ffmpeg + scripts | Batch, automation, servers, QC |

## Universal Project Setup
1. Match timeline resolution/fps to the delivery (or highest-quality source); set color space/management.
2. Ingest with checksum verification; generate proxies/optimized media; set scratch disks (fast SSD).
3. Bin structure: `Footage / Audio / Music / SFX / Graphics / Sequences / Selects / Exports`.
4. Label colors: selects, B-roll, interview A/B, VO, music, temp.
5. Markers: story beats, VO notes, issues to fix; sequence versions `Name_v01` and duplicates before major changes.
6. Autosave + project backups; cloud/versioned storage.

## Speed Edit Techniques (any NLE)
- Mark in/out while viewing at 1.5–2× (J/K/L); stringouts of selects by scene/topic.
- Three-point edits, ripple deletes, trim with roll/slip/slide; use "razor at playhead" + ripple delete for talking heads.
- Keep tracks tidy: V1 main story, V2 B-roll, V3 graphics/captions; A1–A2 dialogue, A3–A4 music, A5–A6 SFX/ambience.
- Adjustment layers for global grade/sharpen/vignette; nested sequences for repeatable animations.
- Presets for captions, lower thirds, transitions (save as templates / Motion/Fusion/Essential Graphics).

## Frequently Used Shortcuts
| Action | Resolve | Premiere | FCP |
|---|---|---|---|
| Play/Pause | Space | Space | Space |
| Blade/Split | Ctrl/Cmd+B | Ctrl/Cmd+K | Cmd+B |
| Ripple delete | Shift+Del / Del | Shift+Del | Shift+Del |
| Mark in/out | I / O | I / O | I / O |
| Zoom to fit | Shift+Z | \ | Shift+Z |
| Add marker | M | M | M |
| Trim: roll/ripple | N/T tools | N / B | T |
| Render/Export | Cmd+4 (Deliver) | Cmd+M | Cmd+E |
| Speed J/K/L | J/K/L | J/K/L | J/K/L |

## DaVinci Resolve Scripting (Python)
Enable: Preferences → System → General → External scripting = Local. Module: `DaVinciResolveScript`.
```python
import DaVinciResolveScript as dvr
resolve = dvr.scriptapp("Resolve")
pm = resolve.GetProjectManager(); proj = pm.GetCurrentProject()
mp = proj.GetMediaPool(); root = mp.GetRootFolder()

# Import media and create a timeline
clips = mp.ImportMedia(["/path/a.mp4", "/path/b.mp4"])
tl = mp.CreateTimelineFromClips("Assembly_v01", clips)

# Add markers
tl.AddMarker(120, "Red", "Hook", "Tighten this", 1)

# Queue and render
proj.SetRenderSettings({"TargetDir": "/exports", "CustomName": "final_v01", "FormatWidth": 1080, "FormatHeight": 1920, "FrameRate": 30})
proj.AddRenderJob(); proj.StartRendering()
```
Also: subtitle generation (`tl.CreateSubtitlesFromAudio()` in recent versions), color presets/LUT application, timeline export (`tl.Export(path, resolve.EXPORT_EDL, resolve.EXPORT_EDL)` / FCPXML / AAF).

## Premiere Pro Automation
- **ExtendScript / UXP** (`app.project.activeSequence`, `sequence.videoTracks[0].clips`) for batch trims, marker import, metadata.
- **Text-based editing**, **Speech to Text captions**, **Auto Reframe**, **Scene Edit Detection**, **Enhance Speech**, **Remix** (music to length) are the highest-ROI AI tools.
- Interchange: XML/EDL/AAF to Resolve/Pro Tools; Dynamic Link to After Effects.

## Final Cut Pro
Keywords + smart collections; Compound Clips for reusable blocks; roles for audio/graphics stems; FCPXML for scripts/interchange (e.g., generate cuts programmatically); Object tracker, Smart Conform, Voice Isolation.

## CapCut / Mobile Short-form
Auto-captions + keyword highlight; Auto cut/beat-sync; keyframes for punch-ins; speed curves; templates; export 1080p/30–60 fps, high bitrate; remove tool watermark/end-card per license; check music commercial rights.

## AI-Assisted Editing (use with judgment)
Transcription/captions, filler/silence removal, scene detection, highlight finding, auto-reframe, audio cleanup, upscaling, generative B-roll/extend. Always review outputs frame-by-frame for artifacts and accuracy; disclose synthetic media where required by platform/law; never fabricate speech of real people.

## Interchange & Handoffs
| To | Format |
|---|---|
| Colorist | XML/AAF/EDL + reference render, flatten effects not supported |
| Sound mixer | AAF/OMF with handles (≥ 1 s), reference video burn-in timecode |
| Motion/VFX | Round-trip via Dynamic Link / Fusion / ProRes 4444 with alpha |
| Client review | H.264 with burn-in timecode + frame.io/Vimeo review links |
| Archive | Project + consolidated media + manifest |
Burn-in timecode with ffmpeg: `-vf "drawtext=timecode='00\:00\:00\:00':rate=24:fontsize=36:fontcolor=white:box=1:boxcolor=black@0.5:x=20:y=h-60"`.

## Performance Troubleshooting
Choppy playback → proxies/optimized media, lower playback res, disable heavy effects, cache; crashes → clear cache, update GPU drivers, reduce plugins; relink issues → keep relative paths/consolidate; audio drift → conform sample rate/CFR; export mismatch → check render queue color settings, max render quality, GPU vs CPU encoder.
