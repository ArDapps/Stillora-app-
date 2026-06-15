# Stillora — Handoff for Claude Code

Drop this file into the next project. It tells Claude Code exactly which
download links to wire up on the Stillora landing page, and what the new
HTML‑to‑video feature is.

---

## 1. Download buttons — fill in the real URLs

Every store / installer button on the landing page is a real `<a>` tag with a
stable `id` and a `data-download` attribute. They currently point at `href="#"`
as placeholders. Replace each `href` with the live URL — **do not** change the
`id`, `class`, or markup.

| Element `id`          | `data-download` | Where it lives          | Put this URL in `href`                        |
|-----------------------|-----------------|-------------------------|-----------------------------------------------|
| `dl-app-store`        | `ios`           | Mobile App card         | Apple App Store listing URL                   |
| `dl-google-play`      | `android`       | Mobile App card         | Google Play listing URL                       |
| `dl-macos`            | `macos`         | Desktop App card        | macOS installer (`.dmg`) download URL         |
| `dl-windows`          | `windows`       | Desktop App card        | Windows installer (`.exe` / `.msi`) URL       |
| `dl-app-store-cta`    | `ios`           | Final call‑to‑action    | Apple App Store listing URL (same as above)   |

### Quick way to find them
```bash
grep -n 'data-download' "Stillora Landing.html"
```
Each one is preceded by an HTML comment saying what URL to drop in, e.g.
```html
<!-- DOWNLOAD LINK: replace href with the macOS installer (.dmg) URL -->
<a id="dl-macos" data-download="macos" href="#" class="appstore"> … </a>
```

### Optional: auto‑detect the visitor's OS
If you want the page to highlight the right desktop download, you can read
`navigator.userAgentData?.platform` (or `navigator.platform`) and add an
`is-recommended` class to `#dl-macos` or `#dl-windows`. Not required.

---

## 2. New feature: HTML → video

Stillora now accepts **HTML** as an input source alongside images, video
clips, and audio. A web page / animation / HTML snippet is rendered to a
polished MP4 (H.264 · AAC · 30 FPS), same export pipeline as the rest.

Already reflected on the landing page in two places:
- Hero media‑flow chips: an **HTML** chip now sits next to Images / Video
  clips / Audio tracks (before the "to MP4" arrow).
- Feature grid: a card titled **"HTML to video"** tagged **New**.

If you add real product copy or a demo, keep the same wording ("HTML to
video") so the page and the app stay consistent.

---

## 3. Don't break these

- Keep the design‑system look: violet `--violet` primary, gold `--gold`
  accent, `Geist` / `Geist Mono` type. Styles live in `stillora-landing.css`.
- The `.appstore` badge style is shared by all five download buttons — restyle
  it there once, not per button.
- Structured data (JSON‑LD) in `<head>` lists supported platforms and the
  feature list; if the download URLs become canonical store links, mirror them
  into the `SoftwareApplication` schema too.
