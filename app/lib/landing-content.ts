import type { LucideIcon } from "lucide-react";
import {
  AudioLines,
  Clapperboard,
  Crop,
  Eye,
  Film,
  Images,
  LayoutGrid,
  Mic,
  MonitorPlay,
  Music4,
  Palette,
  PlaySquare,
  ServerCog,
  Smartphone,
  Sparkles,
  Square,
} from "lucide-react";

import { EDITOR_PATH } from "./site";

/**
 * Single source of truth for the marketing landing page. Section components and
 * the JSON-LD structured data both read from here, so the visible copy and the
 * schema can never drift apart. Future SEO routes (use-cases/*, guides/*) can
 * import these same structures.
 */

export type NavLink = { href: string; label: string };

export const NAV_LINKS: NavLink[] = [
  { href: "#features", label: "Features" },
  { href: "#use-cases", label: "Use Cases" },
  { href: "#formats", label: "Formats" },
  { href: "#how-it-works", label: "How It Works" },
  { href: "#faq", label: "FAQ" },
];

export type TrustMetric = { icon: LucideIcon; label: string };

export const TRUST_METRICS: TrustMetric[] = [
  { icon: LayoutGrid, label: "6 platform formats" },
  { icon: MonitorPlay, label: "1080p crisp output" },
  { icon: Film, label: "Up to 5 minutes" },
  { icon: Images, label: "Images, clips, and audio" },
  { icon: ServerCog, label: "Browser-based workflow" },
];

export type Showcase = {
  input: string;
  output: string;
  outcome: string;
  platform: string;
  duration: string;
  resolution: string;
  /** Aspect ratio of the output frame, as a CSS aspect-ratio value. */
  ratio: string;
};

export const SHOWCASES: Showcase[] = [
  {
    input: "Product photo",
    output: "Instagram Reel with music",
    outcome: "A flat product shot becomes a vertical Reel with a soundtrack, ready to post.",
    platform: "Instagram Reel",
    duration: "0:30",
    resolution: "1080 × 1920",
    ratio: "9 / 16",
  },
  {
    input: "Podcast cover",
    output: "YouTube video with audio",
    outcome: "Pair a cover image with your episode audio and publish straight to YouTube.",
    platform: "YouTube",
    duration: "Audio length",
    resolution: "1920 × 1080",
    ratio: "16 / 9",
  },
  {
    input: "Multiple photos",
    output: "TikTok slideshow with fades",
    outcome: "Several photos turn into a smooth slideshow with fade transitions for TikTok.",
    platform: "TikTok",
    duration: "0:10",
    resolution: "1080 × 1920",
    ratio: "9 / 16",
  },
];

export type UseCase = {
  /** Slug reserved for a future /use-cases/<slug> page. */
  slug: string;
  icon: LucideIcon;
  title: string;
  description: string;
};

export const USE_CASES: UseCase[] = [
  {
    slug: "photo-to-instagram-reel",
    icon: Smartphone,
    title: "Turn a photo into an Instagram Reel",
    description:
      "Create a vertical MP4 from a product image, announcement, quote, or personal photo.",
  },
  {
    slug: "tiktok-slideshow-maker",
    icon: Images,
    title: "Create a TikTok slideshow",
    description:
      "Upload multiple images and turn them into a smooth video timeline with fade transitions.",
  },
  {
    slug: "image-and-audio-to-video",
    icon: Mic,
    title: "Publish podcast audio as a video",
    description:
      "Add an MP3 file to your cover image and export a ready-to-upload YouTube video.",
  },
  {
    slug: "youtube-shorts-maker",
    icon: PlaySquare,
    title: "Make YouTube Shorts from images",
    description:
      "Use the vertical preset and export the correct dimensions without resizing manually.",
  },
  {
    slug: "image-to-mp4",
    icon: Palette,
    title: "Convert artwork into a looping-style video",
    description:
      "Turn illustrations, posters, and digital artwork into shareable MP4 content.",
  },
  {
    slug: "square-video-maker",
    icon: Square,
    title: "Create square videos for social posts",
    description:
      "Export clean 1:1 videos for social feeds, announcements, and branded content.",
  },
];

export type Feature = { icon: LucideIcon; title: string; body: string };

export const FEATURES: Feature[] = [
  {
    icon: Clapperboard,
    title: "Skip complicated video editors",
    body: "Upload an image or clip and export a finished MP4 without learning a timeline.",
  },
  {
    icon: LayoutGrid,
    title: "Match every platform automatically",
    body: "Choose Reels, TikTok, Stories, Shorts, YouTube, square, or original dimensions.",
  },
  {
    icon: AudioLines,
    title: "Add your soundtrack",
    body: "Upload MP3, WAV, M4A, AAC, or OGG audio and align the video duration with your track.",
  },
  {
    icon: Images,
    title: "Create image slideshows",
    body: "Upload multiple images, control the timing, and export smooth fade transitions.",
  },
  {
    icon: Eye,
    title: "Preview before you export",
    body: "Use Fit or Fill framing and see how the final output will appear.",
  },
  {
    icon: ServerCog,
    title: "Render securely on the server",
    body: "Create your MP4 in the browser without installing desktop software.",
  },
];

export type ComparisonRow = {
  capability: string;
  stillora: string;
  traditional: string;
};

export const COMPARISON_ROWS: ComparisonRow[] = [
  { capability: "Timeline setup", stillora: "Not needed", traditional: "Usually required" },
  { capability: "Social format presets", stillora: "One click", traditional: "Manual resizing" },
  {
    capability: "Image to MP4 workflow",
    stillora: "Focused and simple",
    traditional: "Often multiple steps",
  },
  {
    capability: "Optional audio merging",
    stillora: "Built in",
    traditional: "Timeline editing required",
  },
  { capability: "Installation", stillora: "Browser-based", traditional: "Often required" },
  { capability: "Learning curve", stillora: "Minimal", traditional: "Can be complex" },
];

export type HowStep = { icon: LucideIcon; title: string; body: string };

export const HOW_STEPS: HowStep[] = [
  {
    icon: Images,
    title: "Upload your media",
    body: "Drop in an image, multiple images, or a short clip. Add optional audio when needed.",
  },
  {
    icon: Crop,
    title: "Choose your format",
    body: "Pick Reels, TikTok, Shorts, YouTube, square, or original dimensions. Select Fit or Fill and choose your timing.",
  },
  {
    icon: Music4,
    title: "Export your MP4",
    body: "Render your video on the server and download a ready-to-post MP4.",
  },
];

export type FaqItem = { question: string; answer: string };

export const FAQ_ITEMS: FaqItem[] = [
  {
    question: "Can I turn a single image into an MP4 video?",
    answer:
      "Yes. Upload an image, select the video duration and format, then export a share-ready MP4.",
  },
  {
    question: "Can I add MP3 audio to an image?",
    answer:
      "Yes. Stillora can combine an image or slideshow with MP3, WAV, M4A, AAC, or OGG audio.",
  },
  {
    question: "Can I create videos for Instagram Reels and TikTok?",
    answer:
      "Yes. Use the 9:16 vertical preset to export a 1080 × 1920 MP4 suitable for Reels, TikTok, Stories, and YouTube Shorts.",
  },
  {
    question: "Can I turn multiple images into a slideshow video?",
    answer:
      "Yes. Upload multiple images, configure the slide duration, and export a video with smooth transitions.",
  },
  {
    question: "Do I need to install video-editing software?",
    answer: "No. Stillora runs in your browser and renders the final MP4 on the server.",
  },
  {
    question: "What is the maximum video length?",
    answer: "Stillora currently supports videos up to five minutes.",
  },
  {
    question: "What image formats are supported?",
    answer: "Stillora supports JPG, PNG, and WebP images.",
  },
  {
    question: "What audio formats are supported?",
    answer: "Stillora supports MP3, WAV, M4A, AAC, and OGG audio files.",
  },
  {
    question: "What video format does Stillora export?",
    answer: "Stillora exports MP4 videos that are ready to publish.",
  },
];

export type FooterLink = { href: string; label: string; external?: boolean };

export const FOOTER_PRODUCT_LINKS: FooterLink[] = [
  { href: EDITOR_PATH, label: "Open Editor" },
  { href: "#features", label: "Features" },
  { href: "#formats", label: "Formats" },
  { href: "#how-it-works", label: "How It Works" },
  { href: "#faq", label: "FAQ" },
];

// Use-case footer links point at on-page anchors today; each `slug` is reserved
// for a dedicated /use-cases/<slug> page in the future.
export const FOOTER_USE_CASE_LINKS: FooterLink[] = [
  { href: "#use-cases", label: "Image to MP4" },
  { href: "#use-cases", label: "Photo to Reel" },
  { href: "#use-cases", label: "Image and MP3 to Video" },
  { href: "#use-cases", label: "TikTok Slideshow Maker" },
  { href: "#use-cases", label: "YouTube Video from Image" },
];

export const HERO_HIGHLIGHT_ICON = Sparkles;
