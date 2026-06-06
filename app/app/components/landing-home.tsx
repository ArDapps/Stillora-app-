import {
  ArrowRight,
  Check,
  Download,
  Film,
  Globe,
  ImageIcon,
  Laptop,
  Layers,
  Maximize2,
  Monitor,
  Music,
  Palette,
  Play,
  Quote,
  Sliders,
  Smartphone,
  Sparkles,
  Square,
  Star,
  Timer,
  Upload,
  UploadCloud,
  Wand2,
  Zap,
} from "lucide-react";
import Image from "next/image";
import { AppNavbar, Logo, PrimaryCta } from "@/app/components/app-navbar";
import { TECNOBLOCKS_URL } from "@/lib/site";

const platforms = [
  { name: "Instagram Reels", sub: "Stories and feed", badge: "IG", gradient: "from-[#f09433] via-[#dc2743] to-[#bc1888]", dims: "1080x1920" },
  { name: "TikTok", sub: "For You feed", badge: "TK", gradient: "from-[#010101] to-[#69C9D0]", dims: "1080x1920" },
  { name: "YouTube", sub: "Shorts and long", badge: "YT", gradient: "from-[#FF0000] to-[#cc0000]", dims: "1080x1920 / 1920x1080" },
  { name: "Facebook", sub: "Reels and feed", badge: "FB", gradient: "from-[#1877F2] to-[#0a5bc4]", dims: "1080x1920" },
];

const appPlatforms = [
  {
    icon: Smartphone,
    name: "Mobile App",
    sub: "iOS and Android",
    status: "Live",
    color: "text-primary",
    bg: "bg-primary/10 border-primary/25",
    features: ["Full editor on the go", "Native camera upload", "Direct share to apps", "Offline export"],
  },
  {
    icon: Monitor,
    name: "Web App",
    sub: "All browsers",
    status: "Live",
    color: "text-accent",
    bg: "bg-accent/10 border-accent/25",
    features: ["No install needed", "Full-resolution export", "Drag-and-drop uploads", "Works on any device"],
  },
  {
    icon: Laptop,
    name: "Desktop App",
    sub: "Mac, Windows and Linux",
    status: "Soon",
    color: "text-amber-400",
    bg: "bg-amber-500/10 border-amber-500/25",
    features: ["Batch processing", "Local file access", "Faster FFmpeg encoding", "Pro-grade controls"],
  },
];

const steps = [
  {
    icon: Upload,
    number: "01",
    title: "Drop your media",
    description: "Drag and drop images, clips, or audio. Stillora reads the file details and prepares a clean preview.",
    detail: "JPG, PNG, WebP, MP4, MOV",
    color: "text-primary",
    bg: "bg-primary/10 border-primary/20",
  },
  {
    icon: Sliders,
    number: "02",
    title: "Choose your format",
    description: "Pick a platform preset, switch Fit or Fill, add optional audio, and choose the export duration.",
    detail: "5 presets, Fit and Fill, Audio",
    color: "text-accent",
    bg: "bg-accent/10 border-accent/20",
  },
  {
    icon: Download,
    number: "03",
    title: "Export your MP4",
    description: "Render a share-ready H.264 MP4 with AAC audio, then download it for any social platform.",
    detail: "H.264, 30 FPS, AAC audio",
    color: "text-green-400",
    bg: "bg-green-500/10 border-green-500/20",
  },
];

const formats = [
  { icon: Smartphone, label: "Reels / TikTok / Stories", dims: "1080 x 1920", ratio: "9:16", color: "text-pink-400", bg: "bg-pink-500/10 border-pink-500/20" },
  { icon: Smartphone, label: "YouTube Shorts", dims: "1080 x 1920", ratio: "9:16", color: "text-red-400", bg: "bg-red-500/10 border-red-500/20" },
  { icon: Monitor, label: "YouTube Long Video", dims: "1920 x 1080", ratio: "16:9", color: "text-blue-400", bg: "bg-blue-500/10 border-blue-500/20" },
  { icon: Square, label: "Square Post", dims: "1080 x 1080", ratio: "1:1", color: "text-purple-400", bg: "bg-purple-500/10 border-purple-500/20" },
  { icon: ImageIcon, label: "Original Image Size", dims: "As uploaded", ratio: "As-is", color: "text-green-400", bg: "bg-green-500/10 border-green-500/20" },
];

const features = [
  { icon: Layers, title: "Mix media types", description: "Combine images, video clips, and audio tracks into one MP4 export.", tag: "3-in-1", color: "text-primary", bg: "bg-primary/10 border-primary/20" },
  { icon: UploadCloud, title: "Drag-and-drop upload", description: "Drop JPEG, PNG, WebP, MP4, or MOV files and preview them instantly.", tag: "Upload", color: "text-violet-400", bg: "bg-violet-500/10 border-violet-500/20" },
  { icon: Maximize2, title: "Smart Fit and Fill", description: "Fit shows the full frame. Fill crops neatly for each social format.", tag: "Framing", color: "text-blue-400", bg: "bg-blue-500/10 border-blue-500/20" },
  { icon: Music, title: "Audio track support", description: "Attach MP3, WAV, M4A, AAC, or OGG audio and trim it to the video.", tag: "Audio", color: "text-pink-400", bg: "bg-pink-500/10 border-pink-500/20" },
  { icon: Timer, title: "10s and 30s durations", description: "Use clean timing presets made for social posts, reels, and shorts.", tag: "Duration", color: "text-amber-400", bg: "bg-amber-500/10 border-amber-500/20" },
  { icon: Zap, title: "Fast FFmpeg encoding", description: "Render H.264, AAC, 30 FPS MP4s server-side with native FFmpeg.", tag: "FFmpeg", color: "text-green-400", bg: "bg-green-500/10 border-green-500/20" },
  { icon: Globe, title: "Web, mobile and desktop", description: "Use the web editor now, mobile app now, and desktop once it ships.", tag: "Platform", color: "text-cyan-400", bg: "bg-cyan-500/10 border-cyan-500/20" },
  { icon: Palette, title: "Background customization", description: "Use black, white, custom color, or blurred image backgrounds.", tag: "Canvas", color: "text-rose-400", bg: "bg-rose-500/10 border-rose-500/20" },
];

const testimonials = [
  { quote: "I used to open Premiere just to render a photo as a 10s clip for Shorts. Stillora saves me hours every week.", author: "Sarah J.", role: "Tech reviewer", avatar: "SJ", color: "from-violet-500 to-purple-600" },
  { quote: "The blurred background when fitting landscape photos to vertical reels is perfect. Clean export every time.", author: "Mike T.", role: "Music producer", avatar: "MT", color: "from-blue-500 to-cyan-500" },
  { quote: "Fastest workflow ever. Drag, pick format, download. Exactly what I needed for podcast snippets.", author: "Elena R.", role: "Podcaster", avatar: "ER", color: "from-pink-500 to-rose-500" },
];

const ctaPerks = [
  "100% free - no credit card ever",
  "No watermark on any export",
  "Web and mobile app available now",
  "All platform presets included",
  "Mix images, video and audio freely",
  "No account needed to start",
];

function SocialBadge({
  badge,
  gradient,
  label,
  size = "md",
}: {
  badge: string;
  gradient: string;
  label: string;
  size?: "sm" | "md";
}) {
  return (
    <span
      aria-label={label}
      className={`grid flex-shrink-0 place-items-center rounded-lg bg-gradient-to-br ${gradient} text-[10px] font-black text-white shadow-lg ${
        size === "sm" ? "size-7" : "size-11 sm:size-12"
      }`}
      title={label}
    >
      {badge}
    </span>
  );
}

function SectionHeading({
  eyebrow,
  title,
  highlight,
  body,
}: {
  eyebrow: string;
  title: string;
  highlight: string;
  body: string;
}) {
  return (
    <div className="mx-auto mb-12 max-w-2xl text-center sm:mb-16">
      <div className="mb-4 inline-flex items-center gap-2 rounded-full border border-primary/20 bg-primary/10 px-3 py-1 text-xs font-semibold text-primary">
        {eyebrow}
      </div>
      <h2 className="mb-4 text-3xl font-extrabold text-foreground sm:text-4xl md:text-5xl">
        {title} <span className="gradient-text">{highlight}</span>
      </h2>
      <p className="text-base text-muted-foreground sm:text-lg">{body}</p>
    </div>
  );
}

function AppMockup() {
  return (
    <div className="relative mx-auto w-full max-w-sm">
      <div className="animate-spin-slow pointer-events-none absolute inset-[-20px] rounded-full border border-dashed border-primary/10" />
      <div
        className="pointer-events-none absolute inset-[-40px] rounded-full border border-accent/10"
        style={{ animation: "spin-slow 30s linear infinite reverse" }}
      />

      <div className="animate-float relative mx-auto w-56 overflow-hidden rounded-[2.5rem] border-4 border-white/10 bg-card shadow-2xl shadow-primary/20 sm:w-64">
        <div className="flex h-6 items-center justify-center bg-muted/50">
          <div className="h-1.5 w-16 rounded-full bg-white/20" />
        </div>

        <div className="relative flex aspect-[9/16] flex-col overflow-hidden bg-gradient-to-b from-[#0f0c29] via-[#302b63] to-[#24243e]">
          <div className="z-10 flex flex-shrink-0 items-center justify-between bg-black/30 px-3 py-2 backdrop-blur-sm">
            <span className="text-[9px] font-semibold text-white/80">Stillora</span>
            <div className="flex gap-1">
              {["Reels", "Shorts", "TikTok"].map((format, index) => (
                <span
                  key={format}
                  className={`rounded-full px-1.5 py-0.5 text-[7px] font-medium ${
                    index === 0 ? "bg-primary/80 text-white" : "bg-white/10 text-white/70"
                  }`}
                >
                  {format}
                </span>
              ))}
            </div>
          </div>

          <div className="absolute right-2 top-10 z-20">
            <span className="rounded-full bg-blue-500/80 px-2 py-0.5 text-[7px] font-bold text-white">
              Video
            </span>
          </div>

          <div className="relative flex flex-1 items-center justify-center">
            <div className="absolute inset-0 bg-gradient-to-br from-purple-900/60 via-blue-900/40 to-indigo-900/60" />
            <svg
              viewBox="0 0 200 280"
              className="absolute inset-0 size-full opacity-80"
              preserveAspectRatio="xMidYMid slice"
              aria-hidden
            >
              <defs>
                <linearGradient id="hero-phone-sky" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#1a0533" />
                  <stop offset="50%" stopColor="#2d1b69" />
                  <stop offset="100%" stopColor="#0f3460" />
                </linearGradient>
                <linearGradient id="hero-phone-mountain-one" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#7c3aed" />
                  <stop offset="100%" stopColor="#312e81" />
                </linearGradient>
                <linearGradient id="hero-phone-mountain-two" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#5b21b6" />
                  <stop offset="100%" stopColor="#1e1b4b" />
                </linearGradient>
              </defs>
              <rect width="200" height="280" fill="url(#hero-phone-sky)" />
              {[20, 50, 90, 140, 170, 30, 80, 160, 190, 10, 120].map((x, index) => (
                <circle
                  key={`${x}-${index}`}
                  cx={x}
                  cy={(index * 7) % 60 + 5}
                  r="1"
                  fill="white"
                  opacity="0.7"
                />
              ))}
              <path
                d="M0 100 Q50 60 100 90 Q150 120 200 80 L200 130 Q150 160 100 130 Q50 100 0 140Z"
                fill="#7c3aed"
                opacity="0.15"
              />
              <path
                d="M0 220 L40 140 L80 170 L120 120 L160 155 L200 130 L200 280 L0 280Z"
                fill="url(#hero-phone-mountain-two)"
                opacity="0.8"
              />
              <path
                d="M0 260 L50 180 L90 210 L130 160 L170 195 L200 170 L200 280 L0 280Z"
                fill="url(#hero-phone-mountain-one)"
              />
              <path d="M130 160 L140 175 L150 168 L155 178 L130 160Z" fill="white" opacity="0.8" />
              <ellipse cx="100" cy="272" rx="60" ry="10" fill="#2563eb" opacity="0.25" />
            </svg>

            <div className="animate-pulse-glow absolute bottom-4 left-1/2 flex -translate-x-1/2 items-center gap-1.5 rounded-full bg-primary/90 px-3 py-1.5 shadow-lg backdrop-blur-sm">
              <Film className="size-2.5 text-white" />
              <span className="text-[8px] font-bold text-white">Exporting MP4...</span>
            </div>
            <div className="absolute bottom-12 left-3 right-3">
              <div className="h-0.5 overflow-hidden rounded-full bg-white/10">
                <div className="animate-progress h-full rounded-full bg-gradient-to-r from-primary to-accent" />
              </div>
            </div>
          </div>

          <div className="flex flex-shrink-0 gap-1 bg-black/40 px-2 py-1.5 backdrop-blur-sm">
            {[
              { label: "Reels", active: true },
              { label: "Shorts", active: false },
              { label: "Square", active: false },
            ].map((format) => (
              <span
                key={format.label}
                className={`flex-1 rounded-md py-1 text-center text-[8px] font-semibold ${
                  format.active ? "bg-primary text-white" : "text-white/50"
                }`}
              >
                {format.label}
              </span>
            ))}
          </div>
        </div>
      </div>

      <div
        className="animate-badge-pop absolute -left-6 top-12 flex items-center gap-2 rounded-lg border border-border/80 bg-card px-3 py-2 shadow-xl sm:-left-10"
        style={{ animationDelay: "0.8s" }}
      >
        <div className="grid size-7 flex-shrink-0 place-items-center rounded-md bg-green-500/20">
          <Zap className="size-3.5 text-green-400" />
        </div>
        <div>
          <p className="text-[10px] font-bold text-foreground">Free forever</p>
          <p className="text-[9px] text-muted-foreground">No credit card</p>
        </div>
      </div>

      <div
        className="animate-badge-pop absolute -right-6 top-1/3 flex items-center gap-2 rounded-lg border border-border/80 bg-card px-3 py-2 shadow-xl sm:-right-10"
        style={{ animationDelay: "1.1s" }}
      >
        <div className="grid size-7 flex-shrink-0 place-items-center rounded-md bg-primary/20">
          <Film className="size-3.5 text-primary" />
        </div>
        <div>
          <p className="text-[10px] font-bold text-foreground">1080x1920</p>
          <p className="text-[9px] text-muted-foreground">9:16 Vertical</p>
        </div>
      </div>

      <div
        className="animate-badge-pop absolute -left-4 bottom-16 flex items-center gap-2 rounded-lg border border-border/80 bg-card px-3 py-2 shadow-xl sm:-left-8"
        style={{ animationDelay: "1.4s" }}
      >
        <div className="grid size-7 flex-shrink-0 place-items-center rounded-md bg-pink-500/20">
          <Music className="size-3.5 text-pink-400" />
        </div>
        <div>
          <p className="text-[10px] font-bold text-foreground">Image + Audio</p>
          <p className="text-[9px] text-muted-foreground">Mixed in one file</p>
        </div>
      </div>
    </div>
  );
}

function Hero() {
  return (
    <section className="relative overflow-hidden pb-16 pt-28 sm:pb-24 sm:pt-36">
      <div className="pointer-events-none absolute inset-0 overflow-hidden">
        <div className="animate-orb absolute left-1/2 top-0 h-[500px] w-[900px] -translate-x-1/2 rounded-full bg-primary/15 blur-[140px]" />
        <div className="animate-orb-reverse absolute left-1/4 top-1/4 h-[300px] w-[400px] rounded-full bg-accent/10 blur-[100px]" />
        <div
          className="absolute inset-0 opacity-[0.035]"
          style={{
            backgroundImage:
              "linear-gradient(var(--color-border-subtle) 1px, transparent 1px), linear-gradient(90deg, var(--color-border-subtle) 1px, transparent 1px)",
            backgroundSize: "64px 64px",
          }}
        />
      </div>

      <div className="relative z-10 mx-auto grid w-full max-w-7xl grid-cols-1 items-center gap-12 px-4 sm:px-6 lg:grid-cols-2 lg:gap-16">
        <div className="text-center lg:text-left">
          <div className="mb-5 inline-flex items-center gap-2 rounded-full border border-primary/20 bg-primary/10 px-3 py-1.5 text-primary">
            <Wand2 className="size-3.5" />
            <span className="text-xs font-semibold tracking-wide">Free - Web - Mobile - Desktop soon</span>
          </div>
          <h1 className="mb-5 text-4xl font-extrabold leading-[1.08] tracking-tight text-foreground sm:text-5xl md:text-6xl lg:text-5xl xl:text-6xl">
            Mix images, video and audio into one <span className="gradient-text-animated">polished MP4</span>
          </h1>
          <p className="mx-auto mb-6 max-w-lg text-base leading-relaxed text-muted-foreground sm:text-lg lg:mx-0">
            Stillora combines still images, video clips, and audio tracks into a single export-ready video formatted for Reels, Shorts, TikTok, YouTube, and more.
          </p>
          <div className="mb-6 flex flex-wrap items-center justify-center gap-1.5 rounded-full border border-border/60 bg-card/80 px-3 py-1.5 backdrop-blur-sm lg:inline-flex">
            {[
              { icon: ImageIcon, label: "Images" },
              { icon: Film, label: "Video clips" },
              { icon: Music, label: "Audio tracks" },
            ].map((item) => (
              <span key={item.label} className="flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-semibold text-muted-foreground">
                <item.icon className="size-3" />
                {item.label}
              </span>
            ))}
            <span className="ml-1 text-[10px] text-muted-foreground/70">to MP4</span>
          </div>
          <div className="mb-8 flex items-center justify-center gap-3 lg:justify-start">
            <span className="text-xs font-medium text-muted-foreground">Works for</span>
            <div className="flex items-center gap-2">
              {platforms.slice(0, 3).map((platform) => (
                <SocialBadge key={platform.name} {...platform} label={platform.name} size="sm" />
              ))}
              <span className="ml-1 text-xs text-muted-foreground">and more</span>
            </div>
          </div>
          <div className="flex flex-col items-center justify-center gap-3 sm:flex-row lg:justify-start">
            <PrimaryCta className="w-full py-4 text-base sm:w-auto">
              <Upload className="mr-2 size-4" />
              Start Free - No Sign-up
              <ArrowRight className="ml-2 size-4" />
            </PrimaryCta>
            <a
              href="#formats"
              className="inline-flex w-full items-center justify-center rounded-full border border-border/60 px-7 py-4 text-base font-semibold text-foreground transition hover:bg-foreground/5 sm:w-auto"
            >
              <Play className="mr-2 size-4 fill-primary text-primary" />
              Watch Demo
            </a>
          </div>
          <p className="mt-5 text-xs text-muted-foreground">
            100% free - Web, mobile and desktop - No watermark - No account needed
          </p>
        </div>

        <div className="flex justify-center">
          <AppMockup />
        </div>
      </div>

      <div className="mx-auto mt-16 grid max-w-3xl grid-cols-2 gap-4 px-4 sm:mt-20 md:grid-cols-4">
        {[
          ["Free", "Always, no paywall"],
          ["3-in-1", "Images, video, audio"],
          ["5 formats", "Platform presets"],
          ["Web + App", "Desktop coming soon"],
        ].map(([value, label]) => (
          <div key={label} className="rounded-lg border border-border/60 bg-card/60 p-4 text-center backdrop-blur-sm">
            <div className="gradient-text mb-0.5 text-xl font-extrabold sm:text-2xl">{value}</div>
            <div className="text-xs text-muted-foreground">{label}</div>
          </div>
        ))}
      </div>
    </section>
  );
}

function PlatformPresets() {
  return (
    <section className="relative overflow-hidden border-y border-border/40 py-10 sm:py-14">
      <div className="pointer-events-none absolute inset-0 bg-gradient-to-r from-primary/5 via-transparent to-accent/5" />
      <div className="relative z-10 mx-auto w-full max-w-7xl px-4 sm:px-6">
        <p className="mb-8 text-center text-xs font-semibold uppercase tracking-widest text-muted-foreground sm:text-sm">
          Perfect presets for every platform
        </p>
        <div className="mx-auto grid max-w-4xl grid-cols-2 gap-3 sm:gap-4 md:grid-cols-4">
          {platforms.map((platform) => (
            <div key={platform.name} className="group flex cursor-default flex-col items-center gap-3 rounded-lg border border-border/60 bg-card/60 p-4 text-center transition hover:-translate-y-1 hover:border-primary/40 hover:bg-card sm:p-5">
              <SocialBadge {...platform} label={platform.name} />
              <div>
                <p className="text-sm font-semibold leading-tight text-foreground">{platform.name}</p>
                <p className="mt-0.5 text-xs text-muted-foreground">{platform.sub}</p>
                <p className="mt-1 font-mono text-[10px] text-primary/70">{platform.dims}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function CrossPlatform() {
  return (
    <section className="relative overflow-hidden py-20 sm:py-28">
      <div className="mx-auto w-full max-w-7xl px-4 sm:px-6">
        <SectionHeading
          eyebrow="Available everywhere"
          title="Web, mobile and"
          highlight="desktop - free"
          body="Start in your browser. Continue on your phone. Power up on desktop when it launches."
        />
        <div className="mb-16 grid grid-cols-1 gap-5 sm:mb-20 sm:gap-6 md:grid-cols-3">
          {appPlatforms.map((platform) => (
            <div key={platform.name} className={`relative rounded-lg border bg-card/60 p-6 transition hover:-translate-y-2 hover:bg-card sm:p-8 ${platform.bg}`}>
              <div className="absolute right-4 top-4">
                <span className={`rounded-full border px-2 py-0.5 text-[10px] font-semibold ${platform.status === "Live" ? "border-green-500/25 bg-green-500/15 text-green-400" : "border-amber-500/25 bg-amber-500/15 text-amber-400"}`}>
                  {platform.status}
                </span>
              </div>
              <div className={`mb-5 grid size-14 place-items-center rounded-lg border ${platform.bg}`}>
                <platform.icon className={`size-7 ${platform.color}`} />
              </div>
              <h3 className="mb-1 text-xl font-bold text-foreground">{platform.name}</h3>
              <p className="mb-5 text-sm text-muted-foreground">{platform.sub}</p>
              <ul className="space-y-2">
                {platform.features.map((feature) => (
                  <li key={feature} className="flex items-center gap-2.5">
                    <span className="grid size-4 flex-shrink-0 place-items-center rounded-full border border-green-500/20 bg-green-500/15">
                      <Check className="size-2.5 text-green-400" />
                    </span>
                    <span className="text-sm text-muted-foreground">{feature}</span>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
        <div className="text-center">
          <h3 className="mb-3 text-2xl font-extrabold text-foreground sm:text-3xl">
            Mix any media into <span className="gradient-text">one MP4 file</span>
          </h3>
          <p className="mx-auto mb-8 max-w-xl text-sm text-muted-foreground sm:text-base">
            Combine a still photo, a video clip, and a backing audio track. Stillora renders it all into one polished export.
          </p>
          <div className="mx-auto grid max-w-3xl grid-cols-1 gap-4 sm:grid-cols-3">
            {[
              { icon: ImageIcon, label: "Images", desc: "JPEG, PNG and WebP", color: "text-violet-300", bg: "from-violet-500/20 to-purple-600/20 border-violet-500/20" },
              { icon: Film, label: "Video clips", desc: "MP4, MOV and AVI", color: "text-blue-300", bg: "from-blue-500/20 to-cyan-600/20 border-blue-500/20" },
              { icon: Music, label: "Audio tracks", desc: "MP3, WAV, M4A, AAC and OGG", color: "text-pink-300", bg: "from-pink-500/20 to-rose-600/20 border-pink-500/20" },
            ].map((item) => (
              <div key={item.label} className={`rounded-lg border bg-gradient-to-br p-5 text-center ${item.bg}`}>
                <item.icon className={`mx-auto mb-3 size-8 ${item.color}`} />
                <p className={`mb-1 text-base font-bold ${item.color}`}>{item.label}</p>
                <p className="font-mono text-xs text-muted-foreground">{item.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}

function HowItWorks() {
  return (
    <section id="how-it-works" className="relative overflow-hidden py-20 sm:py-28">
      <div className="mx-auto w-full max-w-7xl px-4 sm:px-6">
        <SectionHeading
          eyebrow="Simple workflow"
          title="Three steps to a"
          highlight="ready-to-post video"
          body="No timelines, no keyframes. Just your media and the video you need."
        />
        <div className="grid grid-cols-1 gap-6 sm:gap-8 md:grid-cols-3">
          {steps.map((step) => (
            <div key={step.number} className="relative rounded-lg border border-border/60 bg-card/60 p-6 text-center transition hover:-translate-y-2 hover:bg-card sm:p-8 sm:text-left">
              <div className="pointer-events-none absolute right-5 top-4 select-none text-5xl font-black text-foreground/[0.04]">{step.number}</div>
              <div className={`mx-auto mb-5 grid size-14 place-items-center rounded-lg border shadow-xl sm:mx-0 ${step.bg}`}>
                <step.icon className={`size-7 ${step.color}`} />
              </div>
              <div className={`mb-3 inline-flex rounded-full border px-2 py-0.5 font-mono text-[10px] font-bold ${step.bg} ${step.color}`}>
                Step {step.number}
              </div>
              <h3 className="mb-3 text-xl font-bold text-foreground">{step.title}</h3>
              <p className="mb-4 text-sm leading-relaxed text-muted-foreground">{step.description}</p>
              <div className={`inline-flex rounded-full border border-border/60 bg-card px-3 py-1 font-mono text-[11px] ${step.color}`}>
                {step.detail}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function Formats() {
  return (
    <section id="formats" className="relative overflow-hidden py-20 sm:py-28">
      <div className="mx-auto w-full max-w-7xl px-4 sm:px-6">
        <SectionHeading
          eyebrow="Platform presets"
          title="Built for"
          highlight="every feed"
          body="Stop guessing dimensions. Every major platform preset is built in."
        />
        <div className="mx-auto grid max-w-5xl grid-cols-1 items-center gap-8 lg:grid-cols-2 lg:gap-12">
          <div className="flex flex-col gap-2.5">
            {formats.map((format) => (
              <div key={format.label} className="flex items-center gap-4 rounded-lg border border-border/50 bg-card/40 p-4">
                <div className={`grid size-10 flex-shrink-0 place-items-center rounded-md border ${format.bg}`}>
                  <format.icon className={`size-5 ${format.color}`} />
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-semibold leading-tight text-foreground">{format.label}</p>
                  <p className="mt-0.5 font-mono text-xs text-muted-foreground">
                    {format.dims} - {format.ratio}
                  </p>
                </div>
              </div>
            ))}
          </div>
          <div className="relative overflow-hidden rounded-lg border border-border/60 bg-card/60 p-2 shadow-2xl shadow-primary/10">
            <Image
              src="/marketing/stillora-showcase-app.png"
              alt="Stillora upload and format selection interface"
              width={1280}
              height={896}
              className="h-auto w-full rounded-md"
            />
          </div>
        </div>
      </div>
    </section>
  );
}

function Features() {
  return (
    <section id="features" className="relative overflow-hidden py-20 sm:py-28">
      <div className="mx-auto w-full max-w-7xl px-4 sm:px-6">
        <SectionHeading
          eyebrow="Everything included - free"
          title="No fluff."
          highlight="Just the essentials."
          body="All features are free. No plans, no paywalls - just the tools creators need to ship great content."
        />
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-5 lg:grid-cols-4">
          {features.map((feature) => (
            <div key={feature.title} className="rounded-lg border border-border/60 bg-card/60 p-5 transition hover:-translate-y-1.5 hover:border-primary/30 hover:bg-card sm:p-6">
              <div className="mb-4 flex items-start justify-between gap-3">
                <div className={`grid size-11 flex-shrink-0 place-items-center rounded-md border ${feature.bg}`}>
                  <feature.icon className={`size-5 ${feature.color}`} />
                </div>
                <span className={`rounded-full border border-border/60 bg-card px-2 py-0.5 text-[10px] font-semibold ${feature.color}`}>
                  {feature.tag}
                </span>
              </div>
              <h3 className="mb-2 text-base font-bold text-foreground">{feature.title}</h3>
              <p className="text-sm leading-relaxed text-muted-foreground">{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function SocialProof() {
  return (
    <section id="testimonials" className="relative overflow-hidden py-20 sm:py-28">
      <div className="mx-auto w-full max-w-7xl px-4 sm:px-6">
        <SectionHeading
          eyebrow="Creator love"
          title="Loved by"
          highlight="content creators"
          body="Creators use Stillora to turn static content into platform-ready videos without opening a complicated editor."
        />
        <div className="mx-auto mb-12 grid max-w-3xl grid-cols-2 gap-4 md:grid-cols-4">
          {[
            ["10,000+", "Videos exported"],
            ["4.9/5", "Average rating"],
            ["3s", "Avg setup time"],
            ["5 presets", "Platform formats"],
          ].map(([value, label]) => (
            <div key={label} className="rounded-lg border border-border/60 bg-card/60 p-4 text-center">
              <div className="gradient-text mb-0.5 text-xl font-extrabold sm:text-2xl">{value}</div>
              <div className="text-xs text-muted-foreground">{label}</div>
            </div>
          ))}
        </div>
        <div className="grid grid-cols-1 gap-5 sm:gap-6 md:grid-cols-3">
          {testimonials.map((testimonial) => (
            <div key={testimonial.author} className="relative rounded-lg border border-border/60 bg-card/70 p-6 sm:p-8">
              <Quote className="absolute right-5 top-5 size-6 text-primary/15" />
              <div className="mb-5 flex gap-1">
                {Array.from({ length: 5 }).map((_, index) => (
                  <Star key={index} className="size-4 fill-amber-400 text-amber-400" />
                ))}
              </div>
              <p className="mb-6 text-sm leading-relaxed text-foreground/90 sm:text-base">&quot;{testimonial.quote}&quot;</p>
              <div className="flex items-center gap-3">
                <div className={`grid size-10 flex-shrink-0 place-items-center rounded-full bg-gradient-to-br ${testimonial.color}`}>
                  <span className="text-xs font-bold text-white">{testimonial.avatar}</span>
                </div>
                <div>
                  <p className="text-sm font-semibold text-foreground">{testimonial.author}</p>
                  <p className="text-xs text-muted-foreground">{testimonial.role}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function FinalCta() {
  return (
    <section className="relative overflow-hidden py-20 sm:py-28">
      <div className="mx-auto w-full max-w-7xl px-4 sm:px-6">
        <div className="gradient-border mx-auto max-w-4xl rounded-lg">
          <div className="relative overflow-hidden rounded-lg bg-card/90 p-8 text-center backdrop-blur-xl sm:p-12 md:p-16">
            <div className="animate-float mx-auto mb-6 grid size-16 place-items-center rounded-lg bg-[image:var(--brand-mark)] shadow-2xl shadow-primary/40 sm:mb-8 sm:size-20">
              <Sparkles className="size-8 text-white sm:size-10" />
            </div>
            <h2 className="mb-4 text-3xl font-extrabold text-foreground sm:text-4xl md:text-5xl">
              Start creating for <span className="gradient-text-animated">free today</span>
            </h2>
            <p className="mx-auto mb-8 max-w-2xl text-base text-muted-foreground sm:text-lg md:text-xl">
              Mix images, video clips, and audio tracks into platform-ready MP4s. Web and mobile app are available now.
            </p>
            <div className="mx-auto mb-8 grid max-w-xl grid-cols-1 gap-2 text-left sm:grid-cols-2 sm:gap-3">
              {ctaPerks.map((perk) => (
                <div key={perk} className="flex items-center gap-2.5">
                  <span className="grid size-5 flex-shrink-0 place-items-center rounded-full border border-green-500/30 bg-green-500/20">
                    <Check className="size-3 text-green-400" />
                  </span>
                  <span className="text-sm text-muted-foreground">{perk}</span>
                </div>
              ))}
            </div>
            <PrimaryCta className="px-10 py-4 text-base sm:px-12 sm:text-lg">
              Start Free
              <ArrowRight className="ml-3 size-5" />
            </PrimaryCta>
          </div>
        </div>
      </div>
    </section>
  );
}

function Footer() {
  return (
    <footer className="relative overflow-hidden border-t border-border/40 pb-8 pt-12 sm:pt-16">
      <div className="relative z-10 mx-auto w-full max-w-7xl px-4 sm:px-6">
        <div className="mb-10 grid grid-cols-2 gap-8 sm:mb-12 sm:grid-cols-4 sm:gap-12">
          <div className="col-span-2">
            <Logo />
            <p className="mt-4 max-w-xs text-sm leading-relaxed text-muted-foreground">
              Mix images, video clips, and audio tracks into one platform-ready MP4. Free on web, mobile, and desktop soon.
            </p>
          </div>
          <div>
            <h4 className="mb-4 text-sm font-semibold text-foreground">Product</h4>
            <ul className="space-y-2.5">
              {[
                { label: "Features", href: "/#features" },
                { label: "Formats", href: "/#formats" },
                { label: "How it works", href: "/#how-it-works" },
              ].map((link) => (
                <li key={link.href}>
                  <a href={link.href} className="text-sm text-muted-foreground transition-colors hover:text-foreground">
                    {link.label}
                  </a>
                </li>
              ))}
            </ul>
          </div>
          <div>
            <h4 className="mb-4 text-sm font-semibold text-foreground">Legal</h4>
            <ul className="space-y-2.5">
              {[
                { label: "Privacy Policy", href: "/privacy" },
                { label: "Terms of Service", href: "/terms" },
                { label: "Contact", href: "mailto:support@tecnoblocks.com" },
              ].map((link) => (
                <li key={link.href}>
                  <a href={link.href} className="text-sm text-muted-foreground transition-colors hover:text-foreground">
                    {link.label}
                  </a>
                </li>
              ))}
            </ul>
          </div>
        </div>
        <div className="flex flex-col items-center justify-between gap-3 border-t border-border/30 pt-6 sm:flex-row">
          <p className="text-xs text-muted-foreground/70">© {new Date().getFullYear()} Stillora. Free to use. All rights reserved.</p>
          <p className="text-xs text-muted-foreground/70">
            Built by{" "}
            <a href={TECNOBLOCKS_URL} target="_blank" rel="noopener noreferrer" className="font-medium text-primary hover:underline">
              Tecno Blocks
            </a>
          </p>
        </div>
      </div>
    </footer>
  );
}

export function LandingHome() {
  return (
    <div className="min-h-screen overflow-hidden bg-background text-foreground">
      <AppNavbar />
      <main>
        <Hero />
        <PlatformPresets />
        <CrossPlatform />
        <HowItWorks />
        <Formats />
        <Features />
        <SocialProof />
        <FinalCta />
      </main>
      <Footer />
    </div>
  );
}
