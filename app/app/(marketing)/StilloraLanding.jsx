"use client";

import Link from "next/link";
import { Fragment, useEffect, useState } from "react";

import {
  ANDROID_DOWNLOAD_URL,
  APP_STORE_URL,
  MACOS_DOWNLOAD_URL,
  WINDOWS_DOWNLOAD_URL,
} from "@/lib/site";

import "./stillora-landing.css";

/* ------------------------------------------------------------------ *
 * Stillora landing page — one page, light/dark, EN · FR · AR (RTL).
 * All copy lives in T below. Swap the /stillora/*.jpg paths for your
 * own art in /public.
 * ------------------------------------------------------------------ */

/**
 * Fallback store links. The real ones are admin-managed (Admin → Downloads) and
 * arrive as the `stores` prop, so a new build can be published without a deploy;
 * these are only used when the page renders without them.
 */
const STORE = {
  ios: APP_STORE_URL,
  mac: MACOS_DOWNLOAD_URL,
  android: ANDROID_DOWNLOAD_URL,
  windows: WINDOWS_DOWNLOAD_URL,
  linux: "",
};

const LOCALES = [
  { id: "en", label: "EN", dir: "ltr" },
  { id: "fr", label: "FR", dir: "ltr" },
  { id: "ar", label: "ع", dir: "rtl" },
];

const RATIOS = [
  { id: "9:16", css: "9 / 16", img: "/stillora/format-9x16.jpg" },
  { id: "4:5", css: "4 / 5", img: "/stillora/format-4x5.jpg" },
  { id: "1:1", css: "1 / 1", img: "/stillora/format-1x1.jpg" },
  { id: "16:9", css: "16 / 9", img: "/stillora/format-16x9.jpg" },
];

const FX = [
  { id: "none", frame: {}, img: {} },
  { id: "kenburns", frame: {}, img: { animation: "st-ken 7s ease-in-out infinite alternate" } },
  { id: "glow", frame: { boxShadow: "0 0 0 3px rgba(217,70,239,.45), 0 0 46px rgba(124,92,255,.55)" }, img: { filter: "saturate(1.25) contrast(1.06)" } },
  { id: "float", frame: { animation: "st-float 4.4s ease-in-out infinite" }, img: {} },
  { id: "shake", frame: { animation: "st-shake .5s ease-in-out infinite" }, img: {} },
];

/* which sidebar rows take turns being "active": group index/item index */
const CYCLE_ITEMS_BY_LOCALE = (groups) => [`${groups[0][0]}/0`, `${groups[1][0]}/0`, `${groups[1][0]}/4`];

const CLIPS = ["/stillora/clip-1.jpg", "/stillora/clip-2.jpg", "/stillora/clip-3.jpg"];

const Glyph = ({ kind, size = 20 }) => {
  const paths = {
    mac: <><rect x="2.5" y="4" width="19" height="12.5" rx="1.8" /><path d="M1 19.5h22" /></>,
    ios: <><rect x="7" y="2.5" width="10" height="19" rx="2.4" /><path d="M10.6 5.1h2.8" /><path d="M10.8 18.9h2.4" /></>,
    android: <><path d="M7.6 5.2 6.2 3" /><path d="M16.4 5.2 17.8 3" /><rect x="5" y="5.2" width="14" height="8.4" rx="4.2" /><path d="M9.4 9h.01M14.6 9h.01" /><path d="M5 15.4h14v3.2a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2z" /></>,
    windows: <><rect x="3" y="3" width="7.6" height="7.6" rx="1" /><rect x="13.4" y="3" width="7.6" height="7.6" rx="1" /><rect x="3" y="13.4" width="7.6" height="7.6" rx="1" /><rect x="13.4" y="13.4" width="7.6" height="7.6" rx="1" /></>,
    linux: <><rect x="2.5" y="3.5" width="19" height="17" rx="2.4" /><path d="M6.8 9.5 9.4 12l-2.6 2.5" /><path d="M12 14.6h5" /></>,
  };
  return (
    <svg viewBox="0 0 24 24" width={size} height={size} fill="none" stroke="currentColor"
         strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" style={{ display: "block", flex: "none" }}>
      {paths[kind]}
    </svg>
  );
};
const WAVE = [40, 76, 54, 100, 62, 34, 84, 48, 70, 38];
const WAVE_COLORS = ["#7C5CFF", "#8f6dff", "#a882ff", "#22D3EE", "#a882ff", "#8f6dff", "#7C5CFF", "#D946EF", "#a882ff", "#8f6dff"];

/* tool ids drive both the grid and the matrix; y = shipping, n = next, x = n/a */
const TOOL_IDS = ["create", "html", "voice", "loop", "text", "convert", "library", "watermark", "silence", "speed", "compress", "pdf"];
const ALL_SIX = "yyyyyy";
const AVAIL = {
  create: ALL_SIX, html: ALL_SIX, voice: ALL_SIX, loop: ALL_SIX, convert: ALL_SIX,
  library: ALL_SIX, speed: ALL_SIX, text: ALL_SIX, watermark: ALL_SIX,
  silence: ALL_SIX, compress: ALL_SIX, pdf: ALL_SIX, settings: ALL_SIX,
};
const MATRIX_ORDER = ["create", "html", "voice", "loop", "convert", "library", "speed", "text", "watermark", "silence", "compress", "pdf", "settings"];

const SHOT_SIZES = {
  apple: ['iPhone 6.9" · 1290 × 2796', 'iPhone 6.5" · 1242 × 2688', 'iPad 12.9" · 2048 × 2732', "Up to 10 per size"],
  play: ["Phone · 1080 × 1920", 'Tablet 7" & 10"', "Feature graphic · 1024 × 500", "Icon · 512 × 512"],
};

const PRICE_ROWS = [
  ["tools", "y", "y"],
  ["local", "y", "y"],
  ["mark", "y", "y"],
  ["res", "720p", "1080p · 2K · 4K"],
  ["bitrate", "-", "y"],
  ["batch", "-", "y"],
  ["presets", "-", "y"],
  ["ads", "occasional", "removed"],
  ["account", "never", "never"],
];

const T = {
  en: {
    shots: {
      badge: "IN DEVELOPMENT", eyebrow: "Store Screenshots",
      h2: "Turn any image into App Store and Google Play screenshots.",
      body: "Drop in one image or a whole folder. Stillora resizes, pads and frames each one to every size the stores demand — then exports the full set in a single pass, correctly named for upload.",
      bullets: [
        "Every required size, generated at once",
        "Optional device frame, background colour and caption",
        "Files named per store so upload just works",
        "Same deal: on-device, no watermark, no login",
      ],
      cta: "Notify me when it ships", free: "Free, like the rest.",
      apple: "App Store", play: "Google Play",
      note: "Not in the app yet — this section previews what's coming. Everything above it ships today on all six platforms.",
    },
    price: {
      eyebrow: "Free & Pro", h2: "Free forever. Pro once, if you want more.",
      lead: "Every tool works on the free tier, with no watermark and nothing uploaded. Pro is a single payment that lifts the export limits and removes the sponsored banners.",
      freeName: "Free", freeTag: "NO ACCOUNT", freeAmount: "$0", freeUnit: "forever",
      freeList: [
        "All fourteen tools, on all six platforms",
        "No watermark on any export",
        "Local processing — files stay on your device",
        "Every platform preset and aspect ratio, at 720p",
      ],
      freeAside: "Occasional sponsored banner in-app", freeCta: "Start free — no sign-up",
      proName: "Stillora Pro", proTag: "PAY ONCE", proAmount: "$19.99", proUnit: "lifetime · no subscription",
      proList: [
        ["Higher resolution exports", "1080p, 2K and 4K where the platform supports them"],
        ["Advanced media tools", "bitrate, thresholds, custom speeds, file-size targets"],
        ["Batch processing", "run a whole folder through a tool in one pass"],
        ["Premium controls & presets", "saved presets, extra transitions and effects"],
        ["Remove ads forever", "sponsored content disappears the moment you unlock"],
      ],
      proCta: "Unlock Lifetime Pro — $19.99",
      proNote: "One-time purchase. Restore anytime on your other devices.",
      cols: ["Feature", "Free", "Pro Lifetime"],
      rows: {
        tools: "All fourteen tools", local: "Local processing · files stay on device",
        mark: "No Stillora watermark", res: "Export resolution",
        bitrate: "Bitrate, thresholds & file-size targets", batch: "Folder batch processing",
        presets: "Saved presets, extra transitions & effects", ads: "Sponsored banners", account: "Account required",
      },
      words: { occasional: "Occasional", removed: "Removed", never: "Never" },
    },
    nav: { tools: "Tools", desktop: "Desktop", mobile: "Mobile", platforms: "Platforms", faq: "FAQ", pricing: "Pricing", cta: "Start free" },
    hero: {
      kicker: "The flagship · Create",
      h1a: "Turn your images into video — with ", h1b: "audio", h1c: " and ", h1d: "effects.",
      sub: "Drop in photos, add a soundtrack or your own voice, pick an effect — Stillora renders one share-ready MP4 on your device. No sign-up, no login, no watermark.",
      cta: "Convert my images free", demo: "▶ Watch demo",
      bullets: [
        "Images, clips and audio in one timeline",
        "Music or in-app voice narration, fit to the cut",
        "Glow, Pan & Zoom, Float, Shake + 7 transitions",
        "Free to use · one-time $19.99 unlock · no subscription",
      ],
      s1: "Your images", s1meta: "3 selected · 12s", s2: "Audio", fitAudio: "Fit to audio",
      s3: "Effect", tap: "tap to preview", specs: "· MP4 · no watermark", fitFill: "Fit or Fill · 720p free · 4K on Pro",
    },
    fx: { none: "None", kenburns: "Pan & Zoom", glow: "Glow", float: "Float", shake: "Shake" },
    stores: { title: "Get Stillora", mac: ["macOS", "Mac App Store"], ios: ["iPhone & iPad", "App Store"], android: ["Android", "Google Play"], windows: ["Windows", "Microsoft Store"], linux: ["Linux", "Flathub"] },
    pillars: [
      ["Free to use", "Every tool, free forever. One-time $19.99 Pro for the rest — never a subscription."],
      ["3-in-1", "Images, video, audio. Mix every media type in one file."],
      ["6 formats", "Platform presets. The right dimensions, every feed."],
      ["Everywhere", "Web, desktop & mobile. Mac, Windows, Linux, iOS, Android."],
    ],
    steps: {
      h2: "Three steps, on any device you own.",
      lead: "Drag to reorder, trim per clip, add a soundtrack or record narration, then export. The mobile and desktop apps run entirely on-device.",
      items: [
        ["Upload", "Photos, clips or both. Per-clip duration from 1s to 30m, per-clip volume for video."],
        ["Audio", "Add a track or record narration in-app. “Fit to audio” matches the cut to the song."],
        ["Export", "Pick a preset and quality tier, see the size estimate, get a clean MP4."],
      ],
    },
    html: {
      h2: "Render an animated web page straight to MP4.",
      body: "Paste HTML, upload a file, or point at a URL. Frame-accurate capture steps CSS animations, timers and scripts in lockstep — few competitors have this at all.",
      chips: ["Paste · Upload · URL", "24 / 30 / 60 fps", "Up to 60s"],
    },
    tools: {
      h2: "Fourteen tools. No fluff.", live: "Live everywhere", first: "Desktop-first", all: "All platforms",
      seeAll: "See all 14 →", extra: ["Batch Converter · Settings & Info", "Web batch with PDF input and “Download all” (30 files), plus language, privacy and terms."],
      create: "Photos and clips into one MP4 — slideshow transitions, narration, fit-to-audio, per-clip volume, 720p free and up to 4K on Pro.",
      html: "Paste, upload or link a page. 60s, 60fps, four ratios.",
      voice: "Record in-app with a live waveform, then balance it against the music.",
      loop: "Batch renderer — one MP4 per image, never merged. PDF input on web.",
      text: "Animated captions and titles burned in — drag to place, set timing and fade.",
      convert: "HEIC, WebP, TIFF, BMP → JPEG or PNG, in batches.",
      library: "Every export, stored on-device. Grid, list, multi-select delete.",
      watermark: "Stack logos or video over a base clip, each with a time window.",
      silence: "Auto-cut dead air, Gentle → Aggressive, plus 1×–4× speed.",
      speed: "1× to 4× with the resulting length shown before render.",
      compress: "Shrink a video toward a target size with bitrate control, audio intact.",
      pdf: "Rasterize a PDF page into an image, then loop it into an MP4.",
      webDesktop: "Web & desktop", desktop: "Desktop", desktopIos: "Desktop · iOS",
      mobileNext: "Mobile next", androidNext: "Android next", androidSoon: "Android soon",
    },
    desk: {
      eyebrow: "Desktop Studio · macOS · Windows · Linux",
      h2: "A real window, with real file access.",
      lead: "Every tool in one sidebar, a live preview beside the controls, and exports that land in whatever folder you choose.",
      win: "Stillora — Create · Desktop Studio",
      groups: [["CREATE", ["Create", "Text", "Loop images", "HTML"]], ["VIDEO TOOLS", ["Watermark", "Remove Silence", "Speed", "Compress", "Convert"]], ["YOUR CONTENT", ["Library"]]],
      local: "Files stay on this computer.",
      source: "Source media", items: "3 items · 12s", sound: "Soundscape", optional: "optional",
      rec: "Record voice", up: "Upload audio", presets: "Presets",
      presetList: [["Reels / Shorts / TikTok", "9:16"], ["Square post", "1:1"], ["Portrait post", "4:5"], ["YouTube landscape", "16:9"]],
      ready: "READY TO EXPORT", kv: [["Preset", "Reels 9:16"], ["Quality", "1080p"], ["Est. size", "≈ 2.4 MB"], ["Account", "None needed"]],
      convert: "Convert to MP4", preview: "Live preview — exactly what gets exported",
      chips: ["Full file access", "Export to any folder", "Live preview panel", "Colour correction", "Original → 4K on Pro", "No login", "Also on web and mobile"],
    },
    mob: {
      eyebrow: "On your phone", h2: "Same three steps, pocket-sized.",
      lead: "iPhone and Android render locally and save straight to your camera roll, with a live size estimate before you export. Guest by default: there is no sign-up screen to get past.",
      bullets: ["720p free, up to 4K on Pro — with a live size estimate", "Record narration with the device mic", "Saves to Photos, shares to any app", "Works offline, no account, no watermark"],
      guest: "Guest", export: "Export MP4", library: "Library",
      rows: [["Reels · 1080×1920", "12s · today"], ["Square · 1080×1080", "8s · yesterday"], ["YouTube · 1920×1080", "20s · Aug 17"]],
      stored: "Exports are stored on this phone. Nothing here depends on cloud storage.",
    },
    plat: {
      h2: "Web, desktop and mobile.",
      lead: "A few tools are desktop-first while mobile export lands. We’d rather show you than surprise you.",
      cols: ["Tool", "Web", "macOS", "Windows", "Linux", "iOS", "Android"], next: "next",
      names: { create: "Create", html: "HTML → Video", voice: "Voice Narration", loop: "Loop Images", convert: "Convert", library: "Library", speed: "Speed", text: "Text", watermark: "Watermark / Overlay", silence: "Remove Silence", compress: "Compress", pdf: "PDF Converter · Batch", settings: "Settings & Info" },
    },
    trust: {
      eyebrow: "No account, no upload", h2: "Open the app and start. That’s the whole onboarding.",
      body: "There is no sign-up screen, no email field and no password to forget. Rendering runs on the device in front of you and exports land in your Library or a folder you pick.",
      bullets: ["No login on mobile, desktop or web", "No watermark on any export, ever", "Works offline once installed", "Mic audio used only for that conversion"],
      cmpTitle: "Stillora vs the usual free app", us: "Stillora", them: "Typical app",
      rows: [["Sign-up required", "Never", "Day one"], ["Watermark", "Never", "Paywalled"], ["4K exports", "$19.99 once", "Monthly plan"], ["Tools included", "14", "1–2"]],
      note: "Every tool is free to use. Stillora Pro is a one-time $19.99 unlock for higher resolutions, advanced controls and an ad-free app — no plans, no renewals, no trials.",
    },
    lang: {
      eyebrow: "Three languages, one build", h2: "English, Français, العربية — with real RTL.",
      body: "The whole interface mirrors for Arabic: timeline direction, step order, sliders and icons all flip.",
    },
    faq: {
      h2: "Questions, answered",
      items: [
        ["Do I need an account?", "No. There is no sign-up, no login and no password anywhere in Stillora — open it and export."],
        ["What costs money?", "Most of the app is free to use with no watermark. Stillora Pro is one payment of $19.99: higher-resolution exports, advanced controls, folder batch processing and no sponsored banners. No subscription, no renewal."],
        ["Which effects end up in the file?", "Fade transitions are baked into the export today. Glow, Pan & Zoom, Float and Shake are in-app preview styles for now."],
        ["Why are some tools desktop-first?", "Watermark, Remove Silence, Compress and Text need heavier encoding. Desktop ships first; iPhone and Android export is next."],
        ["What resolution can I export?", "720p on the free tier, with a live size estimate. Pro unlocks 1080p, 2K and 4K wherever the platform supports them."],
        ["Which languages are supported?", "English, French and Arabic, including full right-to-left layout on every screen."],
      ],
    },
    end: {
      h2: "Start creating for free today.",
      p: "No sign-up · No login · No watermark · One-time $19.99 Pro, no subscription",
      about: "Turn photos, slideshows and clips into share-ready MP4s. Free to use on web, desktop and mobile — no account.",
      cols: [["Tools", ["Create", "HTML → Video", "Loop Images", "Convert"]], ["Download", ["App Store", "Google Play", "Microsoft Store", "Flathub"]], ["Legal", ["Privacy Policy", "Terms of Use", "Licences", "Contact"]], ["Language", ["English", "Français", "العربية"]]],
      rights: "Rendered on your device. Always.",
    },
  },

  fr: {
    shots: {
      badge: "EN DÉVELOPPEMENT", eyebrow: "Captures pour les stores",
      h2: "Transformez une image en captures App Store et Google Play.",
      body: "Ajoutez une image ou un dossier entier. Stillora redimensionne, complète et encadre chaque visuel à toutes les tailles exigées par les stores, puis exporte la série complète en une passe, correctement nommée.",
      bullets: [
        "Toutes les tailles requises, générées d’un coup",
        "Cadre d’appareil, couleur de fond et légende en option",
        "Fichiers nommés par store : l’envoi fonctionne du premier coup",
        "Comme le reste : en local, sans filigrane, sans compte",
      ],
      cta: "Me prévenir à la sortie", free: "Gratuit, comme le reste.",
      apple: "App Store", play: "Google Play",
      note: "Pas encore dans l’app — cette section présente ce qui arrive. Tout ce qui précède est disponible aujourd’hui sur les six plateformes.",
    },
    price: {
      eyebrow: "Gratuit & Pro", h2: "Gratuit à vie. Pro une seule fois, si vous voulez plus.",
      lead: "Tous les outils fonctionnent en version gratuite, sans filigrane et sans upload. Pro est un paiement unique qui lève les limites d’export et supprime les bannières sponsorisées.",
      freeName: "Gratuit", freeTag: "SANS COMPTE", freeAmount: "0 $", freeUnit: "à vie",
      freeList: [
        "Les quatorze outils, sur les six plateformes",
        "Aucun filigrane sur les exports",
        "Traitement local — les fichiers restent sur votre appareil",
        "Tous les préréglages et formats, en 720p",
      ],
      freeAside: "Bannière sponsorisée occasionnelle dans l’app", freeCta: "Commencer — sans inscription",
      proName: "Stillora Pro", proTag: "PAIEMENT UNIQUE", proAmount: "19,99 $", proUnit: "à vie · sans abonnement",
      proList: [
        ["Exports haute résolution", "1080p, 2K et 4K selon la plateforme"],
        ["Outils avancés", "débit, seuils, vitesses personnalisées, taille cible"],
        ["Traitement par lot", "un dossier entier en une seule passe"],
        ["Contrôles & préréglages premium", "préréglages enregistrés, transitions et effets en plus"],
        ["Sans publicité, à vie", "le contenu sponsorisé disparaît dès le déblocage"],
      ],
      proCta: "Débloquer Pro à vie — 19,99 $",
      proNote: "Achat unique. Restaurable à tout moment sur vos autres appareils.",
      cols: ["Fonction", "Gratuit", "Pro à vie"],
      rows: {
        tools: "Les quatorze outils", local: "Traitement local · fichiers sur l’appareil",
        mark: "Aucun filigrane Stillora", res: "Résolution d’export",
        bitrate: "Débit, seuils et taille cible", batch: "Traitement par lot de dossiers",
        presets: "Préréglages, transitions et effets en plus", ads: "Bannières sponsorisées", account: "Compte requis",
      },
      words: { occasional: "Occasionnelles", removed: "Supprimées", never: "Jamais" },
    },
    nav: { tools: "Outils", desktop: "Bureau", mobile: "Mobile", platforms: "Plateformes", faq: "FAQ", pricing: "Tarifs", cta: "Commencer" },
    hero: {
      kicker: "L’outil phare · Create",
      h1a: "Transformez vos images en vidéo — avec ", h1b: "audio", h1c: " et ", h1d: "effets.",
      sub: "Ajoutez vos photos, une musique ou votre voix, choisissez un effet — Stillora produit un MP4 prêt à publier, directement sur votre appareil. Sans inscription, sans compte, sans filigrane.",
      cta: "Convertir mes images", demo: "▶ Voir la démo",
      bullets: [
        "Images, clips et audio sur une même timeline",
        "Musique ou voix off enregistrée dans l’app, calée sur le montage",
        "Glow, Pan & Zoom, Float, Shake + 7 transitions",
        "Gratuit à l’usage · déblocage unique à 19,99 $ · sans abonnement",
      ],
      s1: "Vos images", s1meta: "3 sélectionnées · 12s", s2: "Audio", fitAudio: "Caler sur l’audio",
      s3: "Effet", tap: "touchez pour voir", specs: "· MP4 · sans filigrane", fitFill: "Fit ou Fill · 720p gratuit · 4K avec Pro",
    },
    fx: { none: "Aucun", kenburns: "Pan & Zoom", glow: "Glow", float: "Float", shake: "Shake" },
    stores: { title: "Télécharger", mac: ["macOS", "Mac App Store"], ios: ["iPhone & iPad", "App Store"], android: ["Android", "Google Play"], windows: ["Windows", "Microsoft Store"], linux: ["Linux", "Flathub"] },
    pillars: [
      ["Gratuit à l’usage", "La plupart des outils sont gratuits à vie. Déblocage unique à 19,99 $ pour le reste — jamais d’abonnement."],
      ["3-en-1", "Images, vidéo, audio. Tous les médias dans un seul fichier."],
      ["6 formats", "Des préréglages par plateforme. Les bonnes dimensions, à chaque fois."],
      ["Partout", "Web, bureau et mobile. Mac, Windows, Linux, iOS, Android."],
    ],
    steps: {
      h2: "Trois étapes, sur tous vos appareils.",
      lead: "Réorganisez, coupez chaque clip, ajoutez une musique ou une voix off, puis exportez. Les apps mobile et bureau fonctionnent entièrement en local.",
      items: [
        ["Import", "Photos, clips ou les deux. Durée par clip de 1s à 30 min, volume par clip pour la vidéo."],
        ["Audio", "Ajoutez une piste ou enregistrez une voix off. « Caler sur l’audio » ajuste le montage à la musique."],
        ["Export", "Choisissez un préréglage et une qualité, voyez la taille estimée, obtenez un MP4 propre."],
      ],
    },
    html: {
      h2: "Transformez une page web animée en MP4.",
      body: "Collez du HTML, importez un fichier ou indiquez une URL. La capture image par image synchronise animations CSS, minuteurs et scripts — très peu de concurrents le proposent.",
      chips: ["Coller · Importer · URL", "24 / 30 / 60 fps", "Jusqu’à 60s"],
    },
    tools: {
      h2: "Quatorze outils. Rien de superflu.", live: "Partout", first: "Bureau d’abord", all: "Toutes les plateformes",
      seeAll: "Voir les 14 →", extra: ["Convertisseur par lot · Réglages & Infos", "Traitement par lot sur le web avec import PDF et « Tout télécharger » (30 fichiers), plus langue, confidentialité et conditions."],
      create: "Photos et clips en un seul MP4 — transitions, voix off, calage audio, volume par clip, 720p gratuit et jusqu’à 4K avec Pro.",
      html: "Collez, importez ou liez une page. 60s, 60fps, quatre formats.",
      voice: "Enregistrez dans l’app avec forme d’onde en direct, puis équilibrez avec la musique.",
      loop: "Rendu par lot — un MP4 par image, jamais fusionnés. Import PDF sur le web.",
      text: "Titres et sous-titres animés incrustés — placez, réglez le timing et le fondu.",
      convert: "HEIC, WebP, TIFF, BMP → JPEG ou PNG, par lot.",
      library: "Tous vos exports, stockés sur l’appareil. Grille, liste, suppression multiple.",
      watermark: "Superposez logos ou vidéos sur un clip, chacun avec sa plage horaire.",
      silence: "Coupe automatique des silences, Doux → Agressif, plus vitesse 1×–4×.",
      speed: "De 1× à 4×, avec la durée finale affichée avant le rendu.",
      compress: "Réduisez une vidéo vers une taille cible, contrôle du débit, audio intact.",
      pdf: "Convertissez une page PDF en image, puis en MP4.",
      webDesktop: "Web et bureau", desktop: "Bureau", desktopIos: "Bureau · iOS",
      mobileNext: "Mobile bientôt", androidNext: "Android bientôt", androidSoon: "Android bientôt",
    },
    desk: {
      eyebrow: "Studio bureau · macOS · Windows · Linux",
      h2: "Une vraie fenêtre, un vrai accès aux fichiers.",
      lead: "Tous les outils dans une barre latérale, un aperçu en direct à côté des réglages, et des exports dans le dossier de votre choix.",
      win: "Stillora — Create · Studio bureau",
      groups: [["CRÉATION", ["Create", "Texte", "Loop images", "HTML"]], ["OUTILS VIDÉO", ["Filigrane", "Remove Silence", "Vitesse", "Compression", "Conversion"]], ["VOS CONTENUS", ["Bibliothèque"]]],
      local: "Les fichiers restent sur cet ordinateur.",
      source: "Médias source", items: "3 éléments · 12s", sound: "Ambiance sonore", optional: "optionnel",
      rec: "Enregistrer", up: "Importer un audio", presets: "Préréglages",
      presetList: [["Reels / Shorts / TikTok", "9:16"], ["Post carré", "1:1"], ["Post portrait", "4:5"], ["YouTube paysage", "16:9"]],
      ready: "PRÊT À EXPORTER", kv: [["Préréglage", "Reels 9:16"], ["Qualité", "1080p"], ["Taille est.", "≈ 2,4 Mo"], ["Compte", "Inutile"]],
      convert: "Convertir en MP4", preview: "Aperçu en direct — exactement ce qui sera exporté",
      chips: ["Accès complet aux fichiers", "Export où vous voulez", "Aperçu en direct", "Étalonnage", "Original → 4K avec Pro", "Sans compte", "Aussi sur le web et mobile"],
    },
    mob: {
      eyebrow: "Sur votre téléphone", h2: "Les mêmes trois étapes, format poche.",
      lead: "iPhone et Android font le rendu en local et enregistrent directement dans la pellicule, avec estimation de taille avant export. Mode invité par défaut : aucun écran d’inscription.",
      bullets: ["720p gratuit, jusqu’à 4K avec Pro — estimation en direct", "Voix off avec le micro de l’appareil", "Enregistre dans Photos, partage partout", "Fonctionne hors ligne, sans compte, sans filigrane"],
      guest: "Invité", export: "Exporter le MP4", library: "Bibliothèque",
      rows: [["Reels · 1080×1920", "12s · aujourd’hui"], ["Carré · 1080×1080", "8s · hier"], ["YouTube · 1920×1080", "20s · 17 août"]],
      stored: "Les exports sont stockés sur ce téléphone. Rien ne dépend du cloud.",
    },
    plat: {
      h2: "Web, bureau et mobile.",
      lead: "Quelques outils arrivent d’abord sur bureau, le temps que l’export mobile suive. Autant vous le dire clairement.",
      cols: ["Outil", "Web", "macOS", "Windows", "Linux", "iOS", "Android"], next: "bientôt",
      names: { create: "Create", html: "HTML → Vidéo", voice: "Voix off", loop: "Loop Images", convert: "Conversion", library: "Bibliothèque", speed: "Vitesse", text: "Texte", watermark: "Filigrane / Overlay", silence: "Remove Silence", compress: "Compression", pdf: "Convertisseur PDF · Lot", settings: "Réglages & Infos" },
    },
    trust: {
      eyebrow: "Sans compte, sans upload", h2: "Ouvrez l’app et commencez. C’est tout l’onboarding.",
      body: "Pas d’écran d’inscription, pas de champ e-mail, pas de mot de passe à oublier. Le rendu se fait sur votre appareil et les exports vont dans votre bibliothèque ou le dossier choisi.",
      bullets: ["Aucun compte sur mobile, bureau ou web", "Jamais de filigrane sur un export", "Fonctionne hors ligne après installation", "Le micro ne sert qu’à cette conversion"],
      cmpTitle: "Stillora face aux apps gratuites habituelles", us: "Stillora", them: "App typique",
      rows: [["Inscription requise", "Jamais", "Dès le début"], ["Filigrane", "Jamais", "Payant"], ["Exports 4K", "19,99 $ une fois", "Formule mensuelle"], ["Outils inclus", "14", "1–2"]],
      note: "L’essentiel de Stillora est gratuit. Stillora Pro est un déblocage unique à 19,99 $ — sans formule, sans renouvellement, sans essai.",
    },
    lang: {
      eyebrow: "Trois langues, une seule app", h2: "English, Français, العربية — avec un vrai RTL.",
      body: "Toute l’interface se met en miroir pour l’arabe : sens de la timeline, ordre des étapes, curseurs et icônes.",
    },
    faq: {
      h2: "Questions fréquentes",
      items: [
        ["Faut-il un compte ?", "Non. Aucune inscription, aucun identifiant, aucun mot de passe dans Stillora — ouvrez et exportez."],
        ["Qu’est-ce qui est payant ?", "L’essentiel de l’app est gratuit, sans filigrane. Un paiement unique de 20 $ débloque le reste définitivement — sans abonnement ni renouvellement."],
        ["Quels effets sont dans le fichier final ?", "Les transitions en fondu sont intégrées à l’export. Glow, Pan & Zoom, Float et Shake restent pour l’instant des styles d’aperçu."],
        ["Pourquoi certains outils sont-ils réservés au bureau ?", "Filigrane, Remove Silence, Compression et Texte demandent plus d’encodage. Le bureau arrive d’abord ; iPhone et Android suivent."],
        ["Quelle résolution d’export ?", "720p sur la version gratuite, avec estimation de taille. Pro débloque 1080p, 2K et 4K selon la plateforme."],
        ["Quelles langues sont prises en charge ?", "Anglais, français et arabe, avec une mise en page de droite à gauche complète."],
      ],
    },
    end: {
      h2: "Créez gratuitement, dès maintenant.",
      p: "Sans inscription · Sans compte · Sans filigrane · Pro à vie à 19,99 $, sans abonnement",
      about: "Transformez photos, diaporamas et clips en MP4 prêts à publier. Gratuit sur web, bureau et mobile — sans compte.",
      cols: [["Outils", ["Create", "HTML → Vidéo", "Loop Images", "Conversion"]], ["Télécharger", ["App Store", "Google Play", "Microsoft Store", "Flathub"]], ["Légal", ["Confidentialité", "Conditions", "Licences", "Contact"]], ["Langue", ["English", "Français", "العربية"]]],
      rights: "Rendu sur votre appareil. Toujours.",
    },
  },

  ar: {
    shots: {
      badge: "قيد التطوير", eyebrow: "صور المتاجر",
      h2: "حوّل أي صورة إلى لقطات جاهزة لمتجري App Store وGoogle Play.",
      body: "أضف صورة واحدة أو مجلدًا كاملًا. يعيد Stillora تحجيم كل صورة وتأطيرها بكل المقاسات التي يطلبها المتجران، ثم يصدّر المجموعة كاملة في خطوة واحدة بأسماء ملفات صحيحة للرفع.",
      bullets: [
        "كل المقاسات المطلوبة تُنشأ مرة واحدة",
        "إطار جهاز ولون خلفية وتعليق اختياريًا",
        "أسماء ملفات مطابقة لكل متجر ليعمل الرفع مباشرة",
        "كالمعتاد: على الجهاز، بلا علامة مائية وبلا حساب",
      ],
      cta: "أبلغوني عند الإطلاق", free: "مجانًا، كبقية الأدوات.",
      apple: "App Store", play: "Google Play",
      note: "غير متوفرة في التطبيق بعد — هذا القسم يعرض ما هو قادم. كل ما سبقه متاح اليوم على المنصات الست.",
    },
    price: {
      eyebrow: "المجاني و Pro", h2: "مجاني للأبد. و Pro بدفعة واحدة إن أردت المزيد.",
      lead: "كل الأدوات تعمل في النسخة المجانية، بلا علامة مائية وبلا رفع. أما Pro فدفعة واحدة ترفع حدود التصدير وتزيل البانرات الدعائية.",
      freeName: "المجاني", freeTag: "بلا حساب", freeAmount: "٠ $", freeUnit: "للأبد",
      freeList: [
        "الأدوات الأربع عشرة على المنصات الست",
        "بلا علامة مائية على أي تصدير",
        "معالجة محلية — الملفات تبقى على جهازك",
        "كل المقاسات والإعدادات الجاهزة بدقة 720p",
      ],
      freeAside: "بانر دعائي من حين لآخر داخل التطبيق", freeCta: "ابدأ مجانًا — بلا تسجيل",
      proName: "Stillora Pro", proTag: "دفعة واحدة", proAmount: "١٩٫٩٩ $", proUnit: "مدى الحياة · بلا اشتراك",
      proList: [
        ["تصدير بدقة أعلى", "1080p و2K و4K حسب دعم المنصة"],
        ["أدوات وسائط متقدمة", "معدل البِت، الحدود، سرعات مخصصة، حجم مستهدف"],
        ["معالجة بالدفعات", "مجلد كامل عبر الأداة في خطوة واحدة"],
        ["تحكم وإعدادات متقدمة", "إعدادات محفوظة وانتقالات ومؤثرات إضافية"],
        ["إزالة الإعلانات للأبد", "يختفي المحتوى الدعائي لحظة الترقية"],
      ],
      proCta: "افتح Pro مدى الحياة — ١٩٫٩٩ $",
      proNote: "شراء لمرة واحدة، ويمكن استعادته على أجهزتك الأخرى في أي وقت.",
      cols: ["الميزة", "المجاني", "Pro مدى الحياة"],
      rows: {
        tools: "الأدوات الأربع عشرة", local: "معالجة محلية · الملفات على الجهاز",
        mark: "بلا علامة مائية", res: "دقة التصدير",
        bitrate: "معدل البِت والحدود والحجم المستهدف", batch: "معالجة مجلدات بالدفعات",
        presets: "إعدادات وانتقالات ومؤثرات إضافية", ads: "البانرات الدعائية", account: "الحساب مطلوب",
      },
      words: { occasional: "أحيانًا", removed: "مُزالة", never: "أبدًا" },
    },
    nav: { tools: "الأدوات", desktop: "الكمبيوتر", mobile: "الهاتف", platforms: "المنصات", faq: "الأسئلة", pricing: "الأسعار", cta: "ابدأ مجانًا" },
    hero: {
      kicker: "الأداة الرئيسية · Create",
      h1a: "حوّل صورك إلى فيديو — مع ", h1b: "الصوت", h1c: " و", h1d: "المؤثرات.",
      sub: "أضف صورك، ثم موسيقى أو تسجيلك الصوتي، واختر مؤثرًا — ينتج Stillora ملف MP4 جاهزًا للنشر على جهازك. بدون تسجيل، بدون حساب، وبدون علامة مائية.",
      cta: "حوّل صوري مجانًا", demo: "▶ شاهد العرض",
      bullets: [
        "صور ومقاطع وصوت في مسار زمني واحد",
        "موسيقى أو تعليق صوتي داخل التطبيق، مضبوط على المونتاج",
        "Glow وPan & Zoom وFloat وShake + ٧ انتقالات",
        "مجاني للاستخدام · دفعة واحدة ٢٠ دولارًا · بدون اشتراك",
      ],
      s1: "صورك", s1meta: "٣ مختارة · ١٢ ثانية", s2: "الصوت", fitAudio: "مطابقة الصوت",
      s3: "المؤثر", tap: "اضغط للمعاينة", specs: "· MP4 · بدون علامة مائية", fitFill: "احتواء أو تعبئة · 720p مجانًا · 4K مع Pro",
    },
    fx: { none: "بدون", kenburns: "تحريك وتكبير", glow: "توهّج", float: "تعويم", shake: "اهتزاز" },
    stores: { title: "حمّل التطبيق", mac: ["macOS", "متجر ماك"], ios: ["آيفون وآيباد", "App Store"], android: ["أندرويد", "Google Play"], windows: ["ويندوز", "متجر مايكروسوفت"], linux: ["لينكس", "Flathub"] },
    pillars: [
      ["مجاني للاستخدام", "معظم الأدوات مجانية للأبد. دفعة واحدة ٢٠ دولارًا لبقية الأدوات — بلا اشتراك."],
      ["٣ في ١", "صور وفيديو وصوت. كل الوسائط في ملف واحد."],
      ["٦ مقاسات", "إعدادات جاهزة لكل منصة، بالأبعاد الصحيحة دائمًا."],
      ["في كل مكان", "الويب والكمبيوتر والهاتف. ماك، ويندوز، لينكس، iOS، أندرويد."],
    ],
    steps: {
      h2: "ثلاث خطوات، على أي جهاز تملكه.",
      lead: "أعد الترتيب بالسحب، اقتطع كل مقطع، أضف موسيقى أو تعليقًا صوتيًا، ثم صدّر. تطبيقات الهاتف والكمبيوتر تعمل بالكامل على جهازك.",
      items: [
        ["الإضافة", "صور أو مقاطع أو كلاهما. مدة كل مقطع من ثانية إلى ٣٠ دقيقة، مع تحكم في الصوت."],
        ["الصوت", "أضف مقطعًا صوتيًا أو سجّل تعليقك. «مطابقة الصوت» تضبط طول الفيديو على الأغنية."],
        ["التصدير", "اختر المقاس والجودة، شاهد الحجم المتوقع، واحصل على MP4 نظيف."],
      ],
    },
    html: {
      h2: "حوّل صفحة ويب متحركة إلى MP4 مباشرة.",
      body: "الصق كود HTML، أو ارفع ملفًا، أو أدخل رابطًا. التصوير إطارًا بإطار يزامن حركات CSS والمؤقتات والسكربتات — ميزة لا يقدّمها إلا القليل.",
      chips: ["لصق · رفع · رابط", "٢٤ / ٣٠ / ٦٠ إطارًا", "حتى ٦٠ ثانية"],
    },
    tools: {
      h2: "أربع عشرة أداة. بلا زيادات.", live: "متاحة في كل مكان", first: "الكمبيوتر أولًا", all: "كل المنصات",
      seeAll: "← اعرض الـ ١٤", extra: ["التحويل بالدفعات · الإعدادات والمعلومات", "تحويل بالدفعات على الويب مع دعم PDF و«تنزيل الكل» (٣٠ ملفًا)، مع اللغة والخصوصية والشروط."],
      create: "صور ومقاطع في ملف MP4 واحد — انتقالات، تعليق صوتي، مطابقة الصوت، تحكم بالصوت، بدقة 720p مجانًا وحتى 4K مع Pro.",
      html: "الصق أو ارفع أو اربط صفحة. ٦٠ ثانية، ٦٠ إطارًا، أربعة مقاسات.",
      voice: "سجّل داخل التطبيق مع موجة صوتية مباشرة، ثم وازن الصوت مع الموسيقى.",
      loop: "تحويل بالدفعات — ملف MP4 لكل صورة، بلا دمج. دعم PDF على الويب.",
      text: "عناوين وتعليقات متحركة مدمجة في الفيديو — حدّد الموضع والتوقيت والتلاشي.",
      convert: "HEIC وWebP وTIFF وBMP إلى JPEG أو PNG، بالدفعات.",
      library: "كل ما صدّرته، محفوظ على جهازك. شبكة أو قائمة، وحذف متعدد.",
      watermark: "ضع شعارات أو فيديو فوق المقطع، لكل عنصر فترة ظهور خاصة.",
      silence: "قص الصمت تلقائيًا، من لطيف إلى قوي، مع تسريع ١×–٤×.",
      speed: "من ١× إلى ٤× مع عرض المدة النهائية قبل التصدير.",
      compress: "قلّل حجم الفيديو نحو حجم مستهدف بالتحكم في البِت ريت، مع الحفاظ على الصوت.",
      pdf: "حوّل صفحة PDF إلى صورة ثم إلى فيديو MP4.",
      webDesktop: "الويب والكمبيوتر", desktop: "الكمبيوتر", desktopIos: "الكمبيوتر · iOS",
      mobileNext: "الهاتف قريبًا", androidNext: "أندرويد قريبًا", androidSoon: "أندرويد قريبًا",
    },
    desk: {
      eyebrow: "استوديو الكمبيوتر · macOS · Windows · Linux",
      h2: "نافذة حقيقية، ووصول كامل للملفات.",
      lead: "كل الأدوات في شريط جانبي واحد، ومعاينة مباشرة بجانب الإعدادات، وتصدير إلى أي مجلد تختاره.",
      win: "Stillora — Create · استوديو الكمبيوتر",
      groups: [["الإنشاء", ["Create", "نص", "Loop images", "HTML"]], ["أدوات الفيديو", ["علامة مائية", "Remove Silence", "السرعة", "الضغط", "التحويل"]], ["محتواك", ["المكتبة"]]],
      local: "الملفات تبقى على هذا الجهاز.",
      source: "الوسائط المصدر", items: "٣ عناصر · ١٢ ثانية", sound: "المسار الصوتي", optional: "اختياري",
      rec: "تسجيل صوتي", up: "رفع ملف صوتي", presets: "المقاسات",
      presetList: [["Reels / Shorts / TikTok", "9:16"], ["منشور مربع", "1:1"], ["منشور طولي", "4:5"], ["يوتيوب أفقي", "16:9"]],
      ready: "جاهز للتصدير", kv: [["المقاس", "Reels 9:16"], ["الجودة", "1080p"], ["الحجم التقديري", "≈ ٢٫٤ م.ب"], ["الحساب", "غير مطلوب"]],
      convert: "تحويل إلى MP4", preview: "معاينة مباشرة — هذا بالضبط ما سيُصدَّر",
      chips: ["وصول كامل للملفات", "تصدير لأي مجلد", "لوحة معاينة مباشرة", "تصحيح الألوان", "الأصلي → 4K مع Pro", "بدون حساب", "متوفر أيضًا على الويب والهاتف"],
    },
    mob: {
      eyebrow: "على هاتفك", h2: "نفس الخطوات الثلاث، بحجم الجيب.",
      lead: "يعالج الآيفون والأندرويد الفيديو محليًا ويحفظه في ألبوم الصور مباشرة، مع تقدير للحجم قبل التصدير. الوضع الافتراضي زائر: لا شاشة تسجيل تعترضك.",
      bullets: ["720p مجانًا وحتى 4K مع Pro — مع تقدير مباشر للحجم", "سجّل التعليق الصوتي بميكروفون الجهاز", "يحفظ في الصور ويشارك لأي تطبيق", "يعمل دون إنترنت، بلا حساب وبلا علامة مائية"],
      guest: "زائر", export: "تصدير MP4", library: "المكتبة",
      rows: [["Reels · 1080×1920", "١٢ ثانية · اليوم"], ["مربع · 1080×1080", "٨ ثوان · أمس"], ["يوتيوب · 1920×1080", "٢٠ ثانية · ١٧ أغسطس"]],
      stored: "الملفات المصدَّرة محفوظة على هذا الهاتف، ولا شيء يعتمد على التخزين السحابي.",
    },
    plat: {
      h2: "الويب والكمبيوتر والهاتف.",
      lead: "بعض الأدوات تصل إلى الكمبيوتر أولًا حتى يجهز التصدير على الهاتف. نفضّل أن نوضّح ذلك بدلًا من مفاجأتك.",
      cols: ["الأداة", "الويب", "macOS", "Windows", "Linux", "iOS", "أندرويد"], next: "قريبًا",
      names: { create: "Create", html: "HTML → فيديو", voice: "التعليق الصوتي", loop: "Loop Images", convert: "التحويل", library: "المكتبة", speed: "السرعة", text: "النص", watermark: "العلامة المائية", silence: "Remove Silence", compress: "الضغط", pdf: "محوّل PDF · دفعات", settings: "الإعدادات والمعلومات" },
    },
    trust: {
      eyebrow: "بلا حساب وبلا رفع", h2: "افتح التطبيق وابدأ. هذه كل خطوات البداية.",
      body: "لا شاشة تسجيل، ولا خانة بريد إلكتروني، ولا كلمة مرور تُنسى. المعالجة تجري على جهازك، والملفات تُحفظ في مكتبتك أو في مجلد تختاره.",
      bullets: ["بلا حساب على الهاتف أو الكمبيوتر أو الويب", "بلا علامة مائية على أي تصدير", "يعمل دون إنترنت بعد التثبيت", "الميكروفون يُستخدم لهذا التحويل فقط"],
      cmpTitle: "Stillora مقابل التطبيقات المجانية المعتادة", us: "Stillora", them: "تطبيق معتاد",
      rows: [["التسجيل مطلوب", "أبدًا", "من البداية"], ["علامة مائية", "أبدًا", "خلف الدفع"], ["تصدير 4K", "١٩٫٩٩ دولارًا مرة", "خطة شهرية"], ["عدد الأدوات", "١٤", "١–٢"]],
      note: "معظم Stillora مجاني للاستخدام. دفعة واحدة بقيمة ١٩٫٩٩ دولارًا تفتح Pro للأبد — بلا خطط ولا تجديد ولا فترة تجريبية.",
    },
    lang: {
      eyebrow: "ثلاث لغات، تطبيق واحد", h2: "English وFrançais والعربية — بدعم كامل للاتجاه من اليمين لليسار.",
      body: "تنعكس الواجهة بالكامل للعربية: اتجاه المسار الزمني، وترتيب الخطوات، وأشرطة التمرير، والأيقونات.",
    },
    faq: {
      h2: "أسئلة وأجوبة",
      items: [
        ["هل أحتاج إلى حساب؟", "لا. لا تسجيل ولا دخول ولا كلمة مرور في Stillora — افتح التطبيق وصدّر."],
        ["ما الذي يُدفع مقابله؟", "معظم التطبيق مجاني وبلا علامة مائية. دفعة واحدة بقيمة ٢٠ دولارًا تفتح الباقي نهائيًا — بلا اشتراك أو تجديد."],
        ["أي المؤثرات تظهر في الملف النهائي؟", "انتقالات التلاشي مدمجة في التصدير حاليًا. أما Glow وPan & Zoom وFloat وShake فهي أنماط معاينة داخل التطبيق."],
        ["لماذا بعض الأدوات على الكمبيوتر أولًا؟", "العلامة المائية وRemove Silence والضغط والنص تحتاج معالجة أثقل. الكمبيوتر أولًا، ثم الآيفون والأندرويد."],
        ["ما دقة التصدير؟", "720p في النسخة المجانية مع تقدير للحجم. ويفتح Pro دقات 1080p و2K و4K حسب دعم المنصة."],
        ["ما اللغات المدعومة؟", "الإنجليزية والفرنسية والعربية، مع تخطيط كامل من اليمين إلى اليسار."],
      ],
    },
    end: {
      h2: "ابدأ الإنشاء مجانًا اليوم.",
      p: "بلا تسجيل · بلا حساب · بلا علامة مائية · دفعة واحدة ٢٠ دولارًا بلا اشتراك",
      about: "حوّل الصور والعروض والمقاطع إلى ملفات MP4 جاهزة للنشر. مجاني على الويب والكمبيوتر والهاتف — بلا حساب.",
      cols: [["الأدوات", ["Create", "HTML → فيديو", "Loop Images", "التحويل"]], ["التحميل", ["App Store", "Google Play", "متجر مايكروسوفت", "Flathub"]], ["قانوني", ["سياسة الخصوصية", "شروط الاستخدام", "التراخيص", "اتصل بنا"]], ["اللغة", ["English", "Français", "العربية"]]],
      rights: "المعالجة على جهازك. دائمًا.",
    },
  },
};

/* ------------------------------------------------------------------ */

/**
 * @param {{ stores?: Partial<Record<"ios"|"mac"|"android"|"windows"|"linux", string>> }} [props]
 */
export default function StilloraLanding({ stores: storeOverrides } = {}) {
  const [theme, setTheme] = useState("light");
  const [locale, setLocale] = useState("en");
  const [ratio, setRatio] = useState(0);
  const [fx, setFx] = useState(1);
  const [manual, setManual] = useState(false);

  const t = T[locale];
  const dir = LOCALES.find((l) => l.id === locale).dir;
  const active = RATIOS[ratio];
  const effect = FX[fx];
  const arabic = locale === "ar";
  const CYCLE_ITEMS = CYCLE_ITEMS_BY_LOCALE(t.desk.groups);

  // Restoring the visitor's saved theme and language can only happen after
  // mount — the server cannot read their localStorage, and rendering their
  // choice during SSR would mismatch. One pass, guarded by an empty dep array.
  /* eslint-disable react-hooks/set-state-in-effect */
  useEffect(() => {
    const savedTheme = window.localStorage.getItem("stillora-theme");
    const savedLocale = window.localStorage.getItem("stillora-locale");
    if (savedTheme === "dark" || savedTheme === "light") setTheme(savedTheme);
    if (savedLocale && T[savedLocale]) setLocale(savedLocale);
  }, []);
  /* eslint-enable react-hooks/set-state-in-effect */

  useEffect(() => {
    if (manual) return;
    let step = 0;
    const id = setInterval(() => {
      step += 1;
      setFx(step % FX.length);
      if (step % 3 === 0) setRatio((r) => (r + 1) % RATIOS.length);
    }, 2600);
    return () => clearInterval(id);
  }, [manual]);

  const pick = (key, value, set) => {
    set(value);
    window.localStorage.setItem(`stillora-${key}`, value);
  };

  const links = { ...STORE, ...storeOverrides };
  const stores = [
    { k: "mac", href: links.mac },
    { k: "ios", href: links.ios },
    { k: "android", href: links.android },
    { k: "windows", href: links.windows },
    { k: "linux", href: links.linux },
  ].filter((store) => Boolean(store.href));

  const availTag = () => <div className="st-tag">{t.tools.all}</div>;

  return (
    <div
      className="st"
      data-theme={theme}
      dir={dir}
      lang={locale}
      style={
        arabic
          ? {
              fontFamily:
                "var(--font-noto-kufi-arabic), var(--font-dm-sans), system-ui, sans-serif",
            }
          : undefined
      }
    >
      <nav className="st-nav">
        <Link className="st-brand" href="/">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/stillora/mark.png" alt="" />
          Stillora
        </Link>
        <div className="st-navlinks">
          <a href="#tools">{t.nav.tools}</a>
          <a href="#desktop">{t.nav.desktop}</a>
          <a href="#mobile">{t.nav.mobile}</a>
          <a href="#platforms">{t.nav.platforms}</a>
          <a href="#pricing">{t.nav.pricing}</a>
          <a href="#faq">{t.nav.faq}</a>
          <div className="st-seg" role="group" aria-label="Language">
            {LOCALES.map((l) => (
              <button key={l.id} type="button" data-on={locale === l.id} onClick={() => pick("locale", l.id, setLocale)}>
                {l.label}
              </button>
            ))}
          </div>
          <div className="st-seg" role="group" aria-label="Theme">
            <button type="button" data-on={theme === "light"} onClick={() => pick("theme", "light", setTheme)}>☀</button>
            <button type="button" data-on={theme === "dark"} onClick={() => pick("theme", "dark", setTheme)}>☾</button>
          </div>
          <a className="st-btn-grad" href={STORE.ios}>{t.nav.cta}</a>
        </div>
      </nav>

      {/* hero — images + audio + effects → one video */}
      <header className="st-hero">
        <div className="st-hero-copy">
          <div className="st-kicker">{t.hero.kicker}</div>
          <h1>
            {t.hero.h1a}
            <span className="st-swash st-swash-cy">{t.hero.h1b}</span>
            {t.hero.h1c}
            <span className="st-swash">{t.hero.h1d}</span>
          </h1>
          <p className="st-hero-sub">{t.hero.sub}</p>
          <div className="st-hero-cta">
            <a className="st-btn" href={STORE.ios}>{t.hero.cta}</a>
            <button className="st-btn-ghost" type="button">{t.hero.demo}</button>
          </div>
          <div className="st-hero-list">
            {t.hero.bullets.map((b) => (
              <span key={b}><i>✓</i>{b}</span>
            ))}
          </div>
        </div>

        <div className="st-hero-panel">
          <div className="st-step-row">
            <i>1</i><b>{t.hero.s1}</b><span>{t.hero.s1meta}</span>
          </div>
          <div className="st-row" style={{ gap: 8 }}>
            {CLIPS.map((src, i) => (
              <span className="st-hero-thumb" key={src} data-on={i === 0}>
                <img src={src} alt="" />
              </span>
            ))}
            <span className="st-hero-thumb st-hero-add">+</span>
          </div>

          <div className="st-step-row">
            <i>2</i><b>{t.hero.s2}</b>
            <span className="st-chip-cy">{t.hero.fitAudio}</span>
          </div>
          <div className="st-track">
            <i>▶</i>
            <span className="st-wave">
              {WAVE.map((h, i) => (
                <span key={i} style={{ height: `${h}%`, background: WAVE_COLORS[i], animationDelay: `${i * 0.15}s` }} />
              ))}
            </span>
            <b>0:12</b>
          </div>

          <div className="st-step-row">
            <i>3</i><b>{t.hero.s3}</b><span>{t.hero.tap}</span>
          </div>
          <div className="st-ratios">
            {FX.map((f, i) => (
              <button key={f.id} type="button" data-fx={i === fx} onClick={() => { setManual(true); setFx(i); }}>
                {t.fx[f.id]}
              </button>
            ))}
          </div>

          <div className="st-stage">
            <div className="st-frame" style={{ height: 300, aspectRatio: active.css, ...effect.frame }}>
              <img src={active.img} alt="" style={effect.img} />
            </div>
          </div>

          <div className="st-ratios">
            {RATIOS.map((r, i) => (
              <button key={r.id} type="button" data-on={i === ratio} onClick={() => { setManual(true); setRatio(i); }}>
                {r.id}
              </button>
            ))}
          </div>
          <div className="st-specs">
            <b>{active.id} {t.hero.specs}</b>
            <span>{t.hero.fitFill}</span>
          </div>
        </div>
      </header>

      {/* stores */}
      <section className="st-stores">
        <b>{t.stores.title}</b>
        <div className="st-stores-list">
          {stores.map((s) => (
            <a className="st-store" key={s.k} href={s.href}>
              <Glyph kind={s.k} />
              <span>
                <b>{t.stores[s.k][0]}</b>
                <span>{t.stores[s.k][1]}</span>
              </span>
            </a>
          ))}
        </div>
      </section>

      {/* pillars */}
      <section className="st-sec" style={{ paddingTop: 64 }}>
        <div className="st-grid st-g4">
          {t.pillars.map(([title, body]) => (
            <div className="st-card" key={title}>
              <h3>{title}</h3>
              <p style={{ marginBottom: 0, fontSize: 13.5 }}>{body}</p>
            </div>
          ))}
        </div>
      </section>

      {/* three steps */}
      <section className="st-sec">
        <div className="st-between" style={{ marginBottom: 30 }}>
          <h2 className="st-h2">{t.steps.h2}</h2>
          <p className="st-lead" style={{ maxWidth: 350 }}>{t.steps.lead}</p>
        </div>
        <div className="st-grid st-g3">
          {t.steps.items.map(([title, body], i) => (
            <div className="st-step" key={title}>
              <div className="st-step-h">
                <span className="st-step-n" style={{ background: ["#D946EF", "#7C5CFF", "#22D3EE"][i], color: i === 2 ? "#07070c" : "#fff" }}>
                  {i + 1}
                </span>
                {title}
              </div>
              <p>{body}</p>
              {i === 0 && (
                <div className="st-thumbs">
                  {CLIPS.map((src) => <span key={src}><img src={src} alt="" /></span>)}
                  <span className="st-add">+</span>
                </div>
              )}
              {i === 1 && (
                <div className="st-wave" style={{ height: 46 }}>
                  {WAVE.slice(0, 8).map((h, j) => (
                    <span key={j} style={{ height: `${h}%`, background: WAVE_COLORS[j], animationDelay: `${j * 0.2}s` }} />
                  ))}
                </div>
              )}
              {i === 2 && (
                <div className="st-shapes">
                  <span style={{ width: 22, height: 40, borderColor: "var(--cy)" }} />
                  <span style={{ width: 34, height: 34 }} />
                  <span style={{ width: 28, height: 36 }} />
                  <span style={{ width: 46, height: 26 }} />
                </div>
              )}
            </div>
          ))}
        </div>
      </section>

      {/* HTML → video */}
      <section className="st-banner">
        <div>
          <div className="st-row" style={{ marginBottom: 16 }}>
            <span className="st-badge">NEW</span>
            <span className="st-eyebrow" style={{ color: "var(--cy)" }}>HTML → Video</span>
          </div>
          <h2 className="st-h2" style={{ fontSize: 38, marginBottom: 14 }}>{t.html.h2}</h2>
          <p style={{ maxWidth: 460, marginBottom: 22, fontSize: 15.5, lineHeight: 1.6, color: "var(--t2)" }}>{t.html.body}</p>
          <div className="st-row" style={{ flexWrap: "wrap" }}>
            {t.html.chips.map((c) => <span className="st-pill st-pill-out" key={c}>{c}</span>)}
          </div>
        </div>
        <div className="st-row" style={{ gap: 14 }}>
          <div className="st-code" dir="ltr">
            <div className="st-code-bar">
              <span style={{ background: "#D946EF" }} />
              <span style={{ background: "#7C5CFF" }} />
              <span style={{ background: "#22D3EE" }} />
            </div>
            <pre>{`<div class="promo">
  <h1>Sale ends tonight</h1>
</div>
@keyframes rise { to { y: 0 } }`}</pre>
          </div>
          <span style={{ fontSize: 22, color: "var(--cy)" }}>→</span>
          <div className="st-phone-mini"><div>Sale ends tonight</div></div>
        </div>
      </section>

      {/* tools */}
      <section className="st-sec" id="tools">
        <div className="st-between" style={{ marginBottom: 26 }}>
          <h2 className="st-h2">{t.tools.h2}</h2>
          <div className="st-row" style={{ gap: 14, fontSize: 12, color: "var(--t4)" }}>
            <span className="st-row" style={{ gap: 6 }}><span className="st-dot-cy" />{t.tools.live}</span>
            <span className="st-row" style={{ gap: 6 }}><span className="st-dot-mute" />{t.tools.first}</span>
          </div>
        </div>
        <div className="st-grid st-g4">
          {TOOL_IDS.map((id) => (
            <div
              className={`st-card${id === "create" ? " st-span2 st-card-flag" : ""}`}
              key={id}
            >
              <div className="st-row" style={{ gap: 9, marginBottom: 10 }}>
                <h3 style={{ marginBottom: 0, fontSize: id === "create" ? 19 : 17 }}>{t.plat.names[id]}</h3>
                {id === "create" && <span className="st-flag">FLAGSHIP</span>}
                {id === "html" && <span className="st-badge st-badge-sm">NEW</span>}
              </div>
              <p>{t.tools[id]}</p>
              {availTag()}
            </div>
          ))}
          <div className="st-card st-span2 st-card-dashed">
            <div>
              <h3 style={{ fontSize: 16, marginBottom: 6 }}>{t.tools.extra[0]}</h3>
              <p style={{ marginBottom: 0 }}>{t.tools.extra[1]}</p>
            </div>
            <span className="st-seeall">{t.tools.seeAll}</span>
          </div>
        </div>
      </section>

      {/* store screenshots — in development */}
      <section className="st-sec" id="store">
        <div className="st-shots">
          <div className="st-shots-body">
            <div className="st-row" style={{ marginBottom: 16 }}>
              <span className="st-badge st-badge-acc">{t.shots.badge}</span>
              <span className="st-eyebrow" style={{ color: "var(--t4)" }}>{t.shots.eyebrow}</span>
            </div>
            <div className="st-grid" style={{ gridTemplateColumns: "1.02fr .98fr", gap: 44, alignItems: "center" }}>
              <div>
                <h2 className="st-h2" style={{ fontSize: 40, marginBottom: 14 }}>{t.shots.h2}</h2>
                <p style={{ maxWidth: 470, marginBottom: 20, fontSize: 15.5, lineHeight: 1.6, color: "var(--t3)" }}>{t.shots.body}</p>
                <div className="st-hero-list" style={{ marginBottom: 24 }}>
                  {t.shots.bullets.map((b) => <span key={b}><i>✓</i>{b}</span>)}
                </div>
                <div className="st-row" style={{ gap: 11 }}>
                  <span className="st-btn" style={{ padding: "15px 24px", fontSize: 14 }}>{t.shots.cta}</span>
                  <span style={{ fontSize: 12.5, color: "var(--t4)" }}>{t.shots.free}</span>
                </div>
              </div>
              <div className="st-grid st-g2" style={{ gap: 14 }}>
                <div className="st-shot-card">
                  <div className="st-row" style={{ gap: 9, marginBottom: 14 }}>
                    <Glyph kind="ios" size={22} />
                    <b style={{ fontSize: 14 }}>{t.shots.apple}</b>
                  </div>
                  <div className="st-shot-previews">
                    <span style={{ aspectRatio: "9 / 19.5" }}><img src={RATIOS[0].img} alt="" /></span>
                    <span style={{ aspectRatio: "9 / 19.5" }}><img src={CLIPS[0]} alt="" /></span>
                    <span style={{ aspectRatio: "3 / 4", alignSelf: "flex-start" }}><img src={RATIOS[1].img} alt="" /></span>
                  </div>
                  <div className="st-shot-sizes">
                    {SHOT_SIZES.apple.map((x) => <span key={x}>{x}</span>)}
                  </div>
                </div>
                <div className="st-shot-card">
                  <div className="st-row" style={{ gap: 9, marginBottom: 14 }}>
                    <Glyph kind="android" size={22} />
                    <b style={{ fontSize: 14 }}>{t.shots.play}</b>
                  </div>
                  <div className="st-shot-previews">
                    <span style={{ aspectRatio: "9 / 16" }}><img src={CLIPS[1]} alt="" /></span>
                    <span style={{ aspectRatio: "9 / 16" }}><img src={CLIPS[2]} alt="" /></span>
                    <span style={{ aspectRatio: "1024 / 500", alignSelf: "flex-start" }}><img src={RATIOS[3].img} alt="" /></span>
                  </div>
                  <div className="st-shot-sizes">
                    {SHOT_SIZES.play.map((x) => <span key={x}>{x}</span>)}
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div className="st-shots-note"><span />{t.shots.note}</div>
        </div>
      </section>

      {/* desktop */}
      <section className="st-sec" id="desktop">
        <div className="st-between" style={{ marginBottom: 32 }}>
          <div>
            <div className="st-eyebrow" style={{ marginBottom: 13 }}>{t.desk.eyebrow}</div>
            <h2 className="st-h2 st-anim-h2">
              {t.desk.h2.split(", ").map((line, i, arr) => (
                <span key={line}>{line}{i < arr.length - 1 ? "," : null}{i === arr.length - 1 ? <i className="st-caret" /> : null}</span>
              ))}
            </h2>
          </div>
          <p className="st-lead" style={{ maxWidth: 360 }}>{t.desk.lead}</p>
        </div>

        <div className="st-win">
          <div className="st-win-bar">
            <i style={{ background: "#ff5f57" }} />
            <i style={{ background: "#febc2e" }} />
            <i style={{ background: "#28c840" }} />
            <span>{t.desk.win}</span>
          </div>
          <div className="st-win-body">
            <div className="st-side">
              {t.desk.groups.map(([group, items]) => (
                <div key={group}>
                  <div className="st-side-h">{group}</div>
                  {items.map((item, i) => (
                    <div
                      className="st-side-i"
                      key={item}
                      data-cycle={CYCLE_ITEMS.indexOf(`${group}/${i}`) >= 0 ? CYCLE_ITEMS.indexOf(`${group}/${i}`) : undefined}
                    >
                      <i />{item}
                    </div>
                  ))}
                </div>
              ))}
              <div className="st-side-foot"><i />{t.desk.local}</div>
            </div>

            <div className="st-main">
              <div className="st-block">
                <div className="st-block-h"><i>1</i>{t.desk.source}<span>{t.desk.items}</span></div>
                <div className="st-clips">
                  {CLIPS.map((src, i) => (
                    <div className="st-clip" key={src} data-on={i === 0}>
                      <div><img src={src} alt="" /></div>
                      <b>4s</b>
                    </div>
                  ))}
                  <div className="st-clip-add">+</div>
                </div>
              </div>
              <div className="st-block">
                <div className="st-block-h">
                  <i>2</i>{t.desk.sound}<span className="st-chip-mute">{t.desk.optional}</span>
                </div>
                <div className="st-row" style={{ gap: 9 }}>
                  <span className="st-opt">{t.desk.rec}</span>
                  <span className="st-opt">{t.desk.up}</span>
                </div>
              </div>
              <div className="st-block">
                <div className="st-block-h"><i>3</i>{t.desk.presets}</div>
                <div className="st-grid st-g2" style={{ gap: 9 }}>
                  {t.desk.presetList.map(([name, ar], i) => (
                    <span className="st-opt" key={name} data-on={i === 0}>
                      {name}<span>{ar}</span>
                    </span>
                  ))}
                </div>
              </div>
            </div>

            <div className="st-aside">
              <b>{t.desk.ready}</b>
              {t.desk.kv.map(([k, v], i) => (
                <div className="st-kv" key={k}>
                  <span>{k}</span>
                  <b style={i === 3 ? { color: "var(--cy)" } : undefined}>{v}</b>
                </div>
              ))}
              <div className="st-aside-cta"><em /><b>{t.desk.convert}</b></div>
              <div className="st-stage" style={{ minHeight: 0, padding: "10px 0" }}>
                <div className="st-frame" style={{ height: 200, aspectRatio: "9 / 16" }}>
                  <img src={RATIOS[0].img} alt="" />
                </div>
              </div>
              <div className="st-aside-note">{t.desk.preview}</div>
            </div>
          </div>
        </div>

        <div className="st-row" style={{ marginTop: 22, flexWrap: "wrap" }}>
          {t.desk.chips.map((c) => <span className="st-pill st-pill-out" key={c}>{c}</span>)}
        </div>
      </section>

      {/* mobile */}
      <section className="st-sec" id="mobile">
        <div className="st-grid" style={{ gridTemplateColumns: "1.05fr .95fr", gap: 44, alignItems: "center" }}>
          <div>
            <div className="st-eyebrow" style={{ marginBottom: 13 }}>{t.mob.eyebrow}</div>
            <h2 className="st-h2" style={{ fontSize: 38, marginBottom: 14 }}>{t.mob.h2}</h2>
            <p className="st-lead" style={{ maxWidth: 440, marginBottom: 20 }}>{t.mob.lead}</p>
            {t.mob.bullets.map((b) => (
              <div className="st-check" key={b}><span>✓</span>{b}</div>
            ))}
          </div>

          <div className="st-row" style={{ justifyContent: "center", gap: 18, alignItems: "flex-start" }}>
            <div className="st-phone">
              <div className="st-screen">
                <div className="st-row" style={{ padding: "16px 16px 10px", gap: 8 }}>
                  <span className="st-app-icon" />
                  <b style={{ fontSize: 13 }}>Create</b>
                  <span style={{ marginInlineStart: "auto", fontSize: 9.5, color: "var(--t4)" }}>{t.mob.guest}</span>
                </div>
                <div className="st-dots">
                  <i style={{ background: "#D946EF" }}>1</i><span />
                  <i style={{ background: "#7C5CFF" }}>2</i><span />
                  <i style={{ background: "#22D3EE", color: "#07070c" }}>3</i>
                </div>
                <div className="st-phone-preview">
                  <img src={RATIOS[0].img} alt="" />
                  <span>9:16 · 12s · Fill</span>
                </div>
                <div className="st-thumbs" style={{ padding: "0 12px 12px" }}>
                  {CLIPS.map((src) => <span key={src} style={{ height: 38 }}><img src={src} alt="" /></span>)}
                </div>
                <div className="st-phone-cta">{t.mob.export}</div>
              </div>
            </div>

            <div className="st-phone st-phone-sm">
              <div className="st-screen">
                <div style={{ padding: "14px 14px 10px", fontSize: 12, fontWeight: 700 }}>{t.mob.library}</div>
                <div style={{ display: "flex", flexDirection: "column", gap: 7, padding: "0 12px" }}>
                  {t.mob.rows.map(([title, meta], i) => (
                    <div className="st-lib" key={title}>
                      <i><img src={[RATIOS[0].img, RATIOS[2].img, RATIOS[3].img][i]} alt="" /></i>
                      <span>
                        <b>{title}</b>
                        <span>{meta}</span>
                      </span>
                    </div>
                  ))}
                </div>
                <div className="st-lib-note">{t.mob.stored}</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* platform matrix */}
      <section className="st-sec" id="platforms">
        <h2 className="st-h2" style={{ marginBottom: 8 }}>{t.plat.h2}</h2>
        <p className="st-lead" style={{ marginBottom: 24 }}>{t.plat.lead}</p>
        <div className="st-matrix">
          <div className="st-matrix-grid st-matrix-head">
            {t.plat.cols.map((c) => <div key={c}>{c}</div>)}
          </div>
          <div className="st-matrix-grid st-matrix-body">
            {MATRIX_ORDER.map((id, row) => {
              const cls = row % 2 === 1 ? "st-odd" : undefined;
              return (
                <Fragment key={id}>
                  <div className={cls}>{t.plat.names[id]}</div>
                  {AVAIL[id].split("").map((c, i) => (
                    <div className={cls} key={i}>
                      {c === "y" ? <span className="st-yes">✓</span> : c === "n" ? <span className="st-next">{t.plat.next}</span> : <span className="st-no">—</span>}
                    </div>
                  ))}
                </Fragment>
              );
            })}
          </div>
        </div>
      </section>

      {/* trust + comparison */}
      <section className="st-sec">
        <div className="st-grid" style={{ gridTemplateColumns: "1.1fr .9fr" }}>
          <div className="st-card st-card-cy">
            <div className="st-eyebrow" style={{ color: "var(--cy)", marginBottom: 15 }}>{t.trust.eyebrow}</div>
            <h3 className="st-h3" style={{ marginBottom: 14 }}>{t.trust.h2}</h3>
            <p style={{ marginBottom: 20, fontSize: 14.5, lineHeight: 1.65 }}>{t.trust.body}</p>
            {t.trust.bullets.map((b) => <div className="st-check" key={b}><span>✓</span>{b}</div>)}
          </div>

          <div className="st-card st-card-quiet">
            <div className="st-eyebrow" style={{ color: "var(--mg)", marginBottom: 15 }}>{t.trust.cmpTitle}</div>
            <div className="st-compare">
              <div className="st-ch">&nbsp;</div>
              <div className="st-ch st-ch-us">{t.trust.us}</div>
              <div className="st-ch">{t.trust.them}</div>
              {t.trust.rows.map(([label, us, them]) => (
                <Fragment key={label}>
                  <div>{label}</div>
                  <div className="st-us">{us}</div>
                  <div className="st-them">{them}</div>
                </Fragment>
              ))}
            </div>
            <p className="st-note">{t.trust.note}</p>
          </div>
        </div>
      </section>

      {/* languages */}
      <section className="st-sec">
        <div className="st-grid st-g2" style={{ alignItems: "center" }}>
          <div className="st-card st-card-vio">
            <div className="st-eyebrow" style={{ color: "var(--vio)", marginBottom: 14 }}>{t.lang.eyebrow}</div>
            <h3 className="st-h3" style={{ marginBottom: 12 }}>{t.lang.h2}</h3>
            <p style={{ fontSize: 14.5, lineHeight: 1.65 }}>{t.lang.body}</p>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            {[
              ["EN", T.en.hero.h1a + T.en.hero.h1b + T.en.hero.h1c + T.en.hero.h1d, "ltr"],
              ["FR", T.fr.hero.h1a + T.fr.hero.h1b + T.fr.hero.h1c + T.fr.hero.h1d, "ltr"],
              ["AR · RTL", T.ar.hero.h1a + T.ar.hero.h1b + T.ar.hero.h1c + T.ar.hero.h1d, "rtl"],
            ].map(([tag, line, d]) => (
              <div key={tag} dir={d} className={`st-card st-sample${d === "rtl" ? " st-sample-ar" : ""}`}>
                <div className="st-sample-tag">{tag}</div>
                <div className="st-sample-line">{line}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* pricing */}
      <section className="st-sec" id="pricing">
        <div className="st-between" style={{ marginBottom: 30 }}>
          <div>
            <div className="st-eyebrow" style={{ marginBottom: 13 }}>{t.price.eyebrow}</div>
            <h2 className="st-h2">{t.price.h2}</h2>
          </div>
          <p className="st-lead" style={{ maxWidth: 350 }}>{t.price.lead}</p>
        </div>

        <div className="st-grid st-g2" style={{ marginBottom: 16 }}>
          <div className="st-plan">
            <div className="st-row" style={{ gap: 10, marginBottom: 6, alignItems: "baseline" }}>
              <b className="st-plan-name">{t.price.freeName}</b>
              <span className="st-chip-mute" style={{ marginInlineStart: 0 }}>{t.price.freeTag}</span>
            </div>
            <div className="st-plan-price">
              <b>{t.price.freeAmount}</b><span>{t.price.freeUnit}</span>
            </div>
            <div className="st-plan-list">
              {t.price.freeList.map((x) => <span key={x}><i>✓</i>{x}</span>)}
              <span className="st-plan-aside"><i>·</i>{t.price.freeAside}</span>
            </div>
            <span className="st-plan-cta st-plan-cta-ghost">{t.price.freeCta}</span>
          </div>

          <div className="st-plan st-plan-pro">
            <span className="st-plan-tag">{t.price.proTag}</span>
            <b className="st-plan-name" style={{ marginBottom: 6, display: "block" }}>{t.price.proName}</b>
            <div className="st-plan-price">
              <b>{t.price.proAmount}</b><span>{t.price.proUnit}</span>
            </div>
            <div className="st-plan-list">
              {t.price.proList.map(([title, desc]) => (
                <span key={title}><i className="st-vio">✦</i><span><strong>{title}</strong> — {desc}</span></span>
              ))}
            </div>
            <span className="st-plan-cta st-plan-cta-grad">{t.price.proCta}</span>
            <span className="st-plan-note">{t.price.proNote}</span>
          </div>
        </div>

        <div className="st-matrix">
          <div className="st-matrix-grid st-price-grid st-matrix-head">
            {t.price.cols.map((c, i) => (
              <div key={c} style={i === 2 ? { color: "var(--vio)" } : undefined}>{c}</div>
            ))}
          </div>
          <div className="st-matrix-grid st-price-grid st-matrix-body">
            {PRICE_ROWS.map(([key, free, pro], row) => {
              const cls = row % 2 === 1 ? "st-odd" : undefined;
              const cell = (v, isPro) => {
                if (v === "y") return <span className="st-yes">✓</span>;
                if (v === "-") return <span className="st-no">—</span>;
                const word = t.price.words[v] || v;
                return <span className={isPro ? "st-pro-word" : "st-free-word"}>{word}</span>;
              };
              return (
                <Fragment key={key}>
                  <div className={cls}>{t.price.rows[key]}</div>
                  <div className={cls}>{cell(free, false)}</div>
                  <div className={cls}>{cell(pro, true)}</div>
                </Fragment>
              );
            })}
          </div>
        </div>
      </section>

      {/* faq */}
      <section className="st-sec" id="faq">
        <h2 className="st-h2" style={{ marginBottom: 22 }}>{t.faq.h2}</h2>
        <div className="st-grid st-g2" style={{ gap: 12 }}>
          {t.faq.items.map(([q, a], i) => (
            <details className="st-faq" key={q} open={i === 0}>
              <summary>{q}</summary>
              <p>{a}</p>
            </details>
          ))}
        </div>
      </section>

      <section className="st-cta">
        <div>
          <h2>{t.end.h2}</h2>
          <p>{t.end.p}</p>
        </div>
        <div className="st-row" style={{ gap: 9, flex: "none" }}>
          <a href={STORE.ios}>App Store</a>
          <a href={STORE.android}>Google Play</a>
        </div>
      </section>

      <footer>
        <div className="st-foot">
          <div style={{ maxWidth: 290 }}>
            <div className="st-brand" style={{ fontSize: 17, marginBottom: 13 }}>
              <img src="/stillora/mark.png" alt="" style={{ width: 28 }} />
              Stillora
            </div>
            <p className="st-foot-about">{t.end.about}</p>
          </div>
          <div className="st-foot-cols">
            {t.end.cols.map(([title, items]) => (
              <div key={title}>
                <b>{title}</b>
                <div>{items.map((i) => <span key={i}>{i}</span>)}</div>
              </div>
            ))}
          </div>
        </div>
        <div className="st-legal">
          <span>© {new Date().getFullYear()} Stillora</span>
          <span>{t.end.rights}</span>
        </div>
      </footer>
    </div>
  );
}
