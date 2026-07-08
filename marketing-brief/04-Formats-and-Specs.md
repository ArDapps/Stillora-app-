# 04 · Formats, Presets & Technical Specs

## Supported file formats

| Type | Formats |
|---|---|
| **Images (in)** | JPEG, PNG, WebP · (Convert tool also reads HEIC, TIFF, BMP) |
| **Video clips (in)** | MP4, MOV, WebM, M4V (site copy also lists AVI) |
| **Audio (in)** | MP3, WAV, M4A, AAC, OGG (Android: M4A/AAC) |
| **Batch extra (web)** | PDF (first page rasterized to an image) |
| **Output** | H.264 MP4 (+ AAC audio) — no watermark |
| **Convert output** | JPEG or PNG |

## Platform / aspect-ratio presets

| Preset | Dimensions | Ratio | Use |
|---|---|---|---|
| Reels / TikTok / Stories | 1080×1920 | 9:16 | IG Reels, TikTok, Stories |
| YouTube Shorts | 1080×1920 | 9:16 | Shorts |
| YouTube Long | 1920×1080 | 16:9 | Standard YouTube |
| Square Post | 1080×1080 | 1:1 | Feed posts |
| Portrait Post | 1080×1350 | 4:5 | Feed portrait (HTML→Video & mobile) |
| Original | As uploaded | As-is | Preserve source |

## Quality tiers (mobile tools)

Consistent ladder across Create, HTML → Video, Loop Images, Speed, and Remove Silence, each with a **live estimated file size**:

- **720p** — "Smallest file"
- **1080p** — "Recommended"
- **2K** — "Sharper"
- **4K** — "Largest file"

(Web exports at 1080p.)

## Export engine specs (cite-able)

- **Codec:** H.264 video, AAC audio, yuv420p, `+faststart` (web-optimized playback).
- **Frame rate:** 30 fps default; HTML → Video supports 24 / 30 / 60 fps.
- **No watermark** on any export.
- **Framing:** Fill = scale + crop to cover; Fit = scale + pad (background fill).
- **Backgrounds (web):** black, white, custom color, or blurred-image background.
- **Fade transitions** auto-added between clips.
- **Upload limits (web):** up to 200 MB per file / 200 MB total; video clips up to 5 min.
- **Durations:** fixed 10–60s per project on web (timeline up to 5 min total); mobile supports quick-picks up to 30 min per clip.
- **HTML → Video limits:** up to 60s, up to 1920px max dimension, optional audio muxing.
- **Rendering:** native server-side FFmpeg (web) / native on-device engine (mobile) — HEVC with H.264 fallback on capable devices.

## Handy one-liners for spec sheets

- "H.264 MP4, up to 4K, no watermark."
- "Six platform presets built in — never guess dimensions again."
- "Images + video + audio → one MP4."
- "Renders on your device — files stay private."
