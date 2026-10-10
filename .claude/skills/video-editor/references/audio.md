# Audio: Dialogue, Music, SFX, Mix

## Order of Operations
1. **Dialogue edit** (cuts, crossfades, room tone) → 2. **Repair** (denoise, de-click, de-reverb) → 3. **Tone** (EQ, de-ess, compression) → 4. **Music & SFX** → 5. **Mix balance & ducking** → 6. **Master** (limiter, loudness) → 7. **Check** on laptop speakers, phone, earbuds, headphones, mono.

## Dialogue Chain (starting points — tune by ear)
| Stage | Setting |
|---|---|
| High-pass | 70–100 Hz (12 dB/oct) |
| Denoise | Light first; broadband reduction 6–12 dB; avoid "underwater" artifacts |
| De-hum | Notch 50/60 Hz + harmonics if present |
| EQ | Cut 200–400 Hz mud (−2…−4 dB), boost 3–5 kHz presence (+2…+3 dB), air shelf 10–12 kHz (+1…+2 dB) |
| De-ess | Target 5–8 kHz, 3–6 dB reduction |
| Compressor | 2.5–3:1, attack 10–20 ms, release 80–150 ms, 3–6 dB gain reduction |
| Limiter | Ceiling −1 dBTP |

Dialogue sits around **−12 to −6 dBFS peaks** pre-master; mix target by LUFS, not by feel.

## Cutting & Smoothing
- Cut at zero crossings or add **2–5 frame (≈ 40–100 ms) crossfades** to kill pops.
- Add **room tone** (10–30 s captured on set) under gaps; never leave digital silence.
- Match perspective (reverb/EQ) when mixing lav + boom or ADR.
- Fix plosives with HPF + manual gain dips; clicks with de-click.

## Music
- Pick music for emotion and structure, not just genre; match tempo to cut rhythm.
- Edit to the beat: land cuts and graphics on downbeats; use drops/risers for reveals.
- **Ducking:** reduce music 8–12 dB under dialogue (side-chain, or keyframes with 150–300 ms attack/400–800 ms release). Raise in gaps.
- Cut songs at phrase boundaries; use stems or loops to extend; crossfade 1–2 beats.
- Licensing: verify commercial rights; keep license receipts; Content ID risk for popular tracks.

## SFX & Sound Design
Layers: **foley** (touch, movement), **hard FX** (impacts, doors), **ambience/bed** (room, street), **designed** (whooshes, risers, hits, stingers). Rules: sync to the frame; low-pass/EQ whooshes so they don't mask voice; vary pitch and pick between repeats; use ambience to glue cuts. For social: subtle risers/hits on text pop-ins, transitions, and punchlines — never louder than dialogue.

## Loudness Targets (integrated, True Peak)
| Destination | Target | True Peak |
|---|---|---|
| YouTube / streaming | −14 LUFS | ≤ −1 dBTP |
| Instagram / TikTok / Shorts | −14 to −12 LUFS | ≤ −1 dBTP |
| Spotify / podcasts | −16 LUFS (stereo) / −19 (mono) | ≤ −1 dBTP |
| Broadcast EU (EBU R128) | −23 LUFS (±0.5) | ≤ −1 dBTP |
| Broadcast US (ATSC A/85) | −24 LKFS (±2) | ≤ −2 dBTP |
| Cinema | Calibrated (85 dBC reference), dialnorm per spec | per spec |

Measure with `ffmpeg -af ebur128` (see cookbook) or `scripts/qc.sh`. Two-pass `loudnorm` for accuracy.

## Mix Balance (relative to dialogue = 0)
Music under dialogue: −15…−20 dB; music alone: up to −8…−6 dB below master peak; SFX accents: −3…−8; ambience: −25…−30. Keep a clear center for voice, widen music/ambience.

## Troubleshooting
| Problem | Fix |
|---|---|
| Echo/reverb | De-reverb plugin, closer mic next time, EQ + gate, add controlled ambience to mask |
| Wind/rumble | HPF 100–150 Hz, spectral repair |
| Clipped audio | De-clip; if severe, ADR/re-record |
| Thin voice | Boost 120–200 Hz (+2), add warmth saturation |
| Harsh sibilance | De-ess; dip 6–8 kHz |
| Music overpowers | Lower, notch 1–4 kHz under voice, shorter ducking release |
| Sync drift | Check VFR/sample rate; conform to 48 kHz; slip audio in frames |
| Pumping/breathing | Reduce compressor ratio, slower release, less denoise |

## Format Hygiene
Work at **48 kHz / 24-bit** (video standard); export AAC 192–320 kbps (or PCM/ProRes for masters); mono-compatibility check; stems export (DX/MX/FX) for broadcast/clients; keep the music-and-effects (M&E) mix for localization.
