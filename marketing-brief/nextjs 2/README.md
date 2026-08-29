# Stillora landing page — Next.js drop-in

One page. Light/dark toggle. English · Français · العربية with real RTL.
Matches the design file `Stillora Landing Page.dc.html` in this project.

## Files

```
StilloraLanding.jsx     the whole page (client component)
stillora-landing.css    design tokens + every component style
```

## Install (App Router)

1. Copy both files into your project, e.g. `app/(marketing)/`.
2. Render it:

```jsx
// app/page.jsx
import StilloraLanding from "./StilloraLanding";

export default function Page() {
  return <StilloraLanding />;
}
```

3. Fonts — in `app/layout.jsx`:

```jsx
import { DM_Sans, DM_Mono, Noto_Kufi_Arabic } from "next/font/google";

const dm = DM_Sans({ subsets: ["latin"], weight: ["400", "500", "700"] });
const mono = DM_Mono({ subsets: ["latin"], weight: ["400", "500"] });
const kufi = Noto_Kufi_Arabic({ subsets: ["arabic"], weight: ["400", "700"] });
```

The CSS asks for the families `"DM Sans"`, `"DM Mono"` and `"Noto Kufi Arabic"` by
name, so a plain Google Fonts `<link>` works too.

## Assets — all included

```
public/stillora/mark.png            real Stillora logo mark  ✅ final
public/stillora/format-9x16.png     hero preview, vertical   ⬜ placeholder
public/stillora/format-4x5.png      hero preview, portrait   ⬜ placeholder
public/stillora/format-1x1.png      hero preview, square     ⬜ placeholder
public/stillora/format-16x9.png     hero preview, landscape  ⬜ placeholder
public/stillora/clip-1.png          timeline thumbnail       ⬜ placeholder
public/stillora/clip-2.png          timeline thumbnail       ⬜ placeholder
public/stillora/clip-3.png          timeline thumbnail       ⬜ placeholder
```

Copy `public/stillora/` into your project's `public/` and the page renders with
nothing missing. The eight image slots are gradient placeholders — overwrite them
with real photos at the same filenames and nothing else changes (CSS handles
framing). Swap `<img>` for `next/image` if you want optimisation.

**Icons need no files.** Every platform icon (macOS, iPhone, Android, Windows,
Linux), every checkmark, arrow and glyph is inline SVG or a text character drawn
with `currentColor`, so they follow the light/dark theme and load nothing.

## Sections, in order

nav · hero (images + audio + effects → one video, autoplaying) · store strip ·
four pillars · three steps · HTML → Video · 14-tool grid · **Store Screenshots
(in development)** · desktop studio window (animated) · mobile · platform matrix ·
no-account + comparison · languages · **Free & Pro** · final CTA · footer

## Where to edit

Everything is at the top of `StilloraLanding.jsx`:

- **`T`** — all copy, keyed by locale (`en`, `fr`, `ar`). Edit text here, never in the JSX.
- **`AVAIL`** — per-tool platform support. `y` = shipping, `n` = coming next, `x` = n/a.
  Column order: **web, macOS, Windows, Linux, iOS, Android**. Currently every tool is
  `ALL_SIX`. Drives the tool cards *and* the platform matrix, so they can't drift.
- **`PRICE_ROWS`** — the Free vs Pro table. `y` / `-` / a word key resolved through
  `T[locale].price.words`.
- **`SHOT_SIZES`** — App Store / Play screenshot dimensions.
- **`STORE`** — store URLs (currently search links; swap for real listings).
- **`RATIOS`** / **`FX`** — the hero's format presets and effect previews.

## Behaviour

- **Theme + locale** persist in `localStorage` (`stillora-theme`, `stillora-locale`).
  For SEO-friendly locales, move locale into the route (`/[lang]/`) and pass it as a
  prop — the component only reads `T[locale]`.
- **Hero autoplay** cycles effects every 2.6s and the format every third step, and
  stops permanently once the visitor taps a chip.
- **Desktop window** motion is pure CSS (sidebar selection, clip selection, export
  progress). All animation is disabled under `prefers-reduced-motion`.

## Before launch

- The platform icons are generic device glyphs, not brand marks. Apple and Google
  require their own badge art ("Download on the App Store", "Get it on Google Play") —
  drop those images into the store strip and footer slots.
- Photos are placeholders; replace with licensed or own shots.
- Claims currently on the page: all 14 tools on all six platforms · free to use ·
  **720p free, 1080p/2K/4K on Pro** · Stillora Pro $19.99 one-time, no subscription ·
  no sign-up/login · no watermark · on-device rendering · Fade baked into export while
  Glow / Pan & Zoom / Float / Shake are preview styles · Store Screenshots marked
  in development. Your `06-Accuracy-Flags.md` says no Pro tier is wired into the
  shipping app — reconcile that before publishing.
