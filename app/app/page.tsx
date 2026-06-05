import {
  ArrowRight,
  AudioLines,
  Check,
  Crop,
  Download,
  Film,
  Images,
  Play,
  Sparkles,
  Timer,
  UploadCloud,
  Wand2,
} from "lucide-react";
import Link from "next/link";
import { AuthControls } from "@/app/components/auth-controls";
import { ThemeToggle } from "@/app/components/theme-toggle";
import {
  MAX_AUDIO_BYTES,
  MAX_IMAGE_BYTES,
  MAX_SOURCE_VIDEO_BYTES,
  MAX_VIDEO_DURATION_SECONDS,
  OUTPUT_PRESETS,
} from "@/lib/stillora";

const features = [
  {
    icon: Film,
    title: "Images & clips to MP4",
    body: "Drop a photo or a short video and Stillora renders a clean, share-ready MP4 — no timeline software, no installs.",
  },
  {
    icon: Images,
    title: "Multi-image timelines",
    body: "Upload several images, set seconds per slide, and Stillora stitches them with smooth fade transitions automatically.",
  },
  {
    icon: AudioLines,
    title: "Add a soundtrack",
    body: "Layer in MP3, WAV, M4A, AAC, or OGG audio. Snap the video length to the track with one tap.",
  },
  {
    icon: Crop,
    title: "Fit or fill framing",
    body: "Keep the whole image with Fit, or crop edges to cover the frame with Fill — previewed exactly as it exports.",
  },
  {
    icon: Timer,
    title: "Smart durations",
    body: "Fixed 10s and 30s presets, or fit the runtime to your audio or source video right up to five minutes.",
  },
  {
    icon: Crop,
    title: "Pixel-true preview",
    body: "The live preview matches the final frame so you never stretch, squash, or guess the output dimensions.",
  },
];

const steps = [
  {
    icon: UploadCloud,
    title: "Upload your media",
    body: "Drag in an image, a stack of images, or a short video — plus optional audio.",
  },
  {
    icon: Wand2,
    title: "Pick format & timing",
    body: "Choose a platform preset, set fit or fill, and dial in the duration or slide timings.",
  },
  {
    icon: Download,
    title: "Export the MP4",
    body: "Render on the server and download a ready-to-post video in seconds.",
  },
];

const mb = (bytes: number) => `${Math.round(bytes / (1024 * 1024))} MB`;

const specs = [
  { label: "Images", value: `JPG, PNG, WebP · ${mb(MAX_IMAGE_BYTES)}` },
  { label: "Video", value: `MP4, MOV, M4V, WebM · ${mb(MAX_SOURCE_VIDEO_BYTES)}` },
  { label: "Audio", value: `MP3, WAV, M4A, AAC, OGG · ${mb(MAX_AUDIO_BYTES)}` },
  { label: "Length", value: `Up to ${MAX_VIDEO_DURATION_SECONDS / 60} minutes` },
];

export default function Landing() {
  return (
    <div className="min-h-screen bg-[var(--color-background)] text-[var(--color-foreground)]">
      {/* Header */}
      <header className="sticky top-0 z-20 border-b border-[var(--color-border)] bg-[var(--color-header)] backdrop-blur">
        <div className="mx-auto flex w-full max-w-7xl items-center justify-between gap-4 px-5 py-4">
          <Link href="/" className="flex items-center gap-3">
            <div className="grid size-10 place-items-center rounded-lg bg-[var(--color-primary)] text-[var(--color-primary-text)] shadow-sm shadow-[var(--shadow-primary)]">
              <Sparkles size={20} strokeWidth={2.4} />
            </div>
            <div>
              <p className="text-lg font-semibold leading-tight">Stillora</p>
              <p className="text-sm text-[var(--color-muted-strong)]">Built by Tecno Blocks</p>
            </div>
          </Link>
          <nav className="hidden items-center gap-7 text-sm font-medium text-[var(--color-muted)] md:flex">
            <a className="transition hover:text-[var(--color-foreground)]" href="#features">Features</a>
            <a className="transition hover:text-[var(--color-foreground)]" href="#formats">Formats</a>
            <a className="transition hover:text-[var(--color-foreground)]" href="#how">How it works</a>
          </nav>
          <div className="flex items-center gap-2 sm:gap-3">
            <ThemeToggle />
            <AuthControls callbackUrl="/editor" />
            <Link
              href="/editor"
              className="hidden items-center gap-2 rounded-md bg-[var(--color-primary)] px-4 py-2 text-sm font-semibold text-[var(--color-primary-text)] shadow-sm shadow-[var(--shadow-primary)] transition hover:bg-[var(--color-primary-hover)] sm:inline-flex"
            >
              Open editor
              <ArrowRight size={16} />
            </Link>
          </div>
        </div>
      </header>

      <main>
        {/* Hero */}
        <section className="relative overflow-hidden">
          <div
            aria-hidden
            className="pointer-events-none absolute inset-0"
            style={{
              background:
                "radial-gradient(60% 60% at 20% 0%, rgb(124 58 237 / 22%), transparent 60%), radial-gradient(50% 50% at 90% 10%, rgb(184 134 11 / 14%), transparent 55%)",
            }}
          />
          <div className="relative mx-auto grid w-full max-w-7xl items-center gap-12 px-5 py-20 lg:grid-cols-[1.05fr_0.95fr] lg:py-28">
            <div>
              <span className="inline-flex items-center gap-2 rounded-full border border-[var(--color-border)] bg-[var(--color-card)] px-3 py-1 text-xs font-medium tracking-wide text-[var(--color-muted)]">
                <Sparkles size={14} className="text-[var(--color-primary)]" />
                Professional video, without the editor
              </span>
              <h1 className="mt-6 text-4xl font-bold leading-[1.05] tracking-tight sm:text-5xl lg:text-6xl">
                Turn images into
                <span className="block bg-gradient-to-r from-[#7c3aed] to-[#b8860b] bg-clip-text text-transparent">
                  share-ready videos
                </span>
              </h1>
              <p className="mt-6 max-w-xl text-lg leading-relaxed text-[var(--color-muted)]">
                Stillora renders your photos, image timelines, and clips into polished, perfectly-sized
                social videos in seconds. Add audio, choose a platform format, and export a clean MP4.
              </p>
              <div className="mt-8 flex flex-wrap items-center gap-3">
                <Link
                  href="/editor"
                  className="inline-flex items-center gap-2 rounded-md bg-[var(--color-primary)] px-6 py-3 text-base font-semibold text-[var(--color-primary-text)] shadow-sm shadow-[var(--shadow-primary)] transition hover:bg-[var(--color-primary-hover)]"
                >
                  Start creating — it&apos;s free
                  <ArrowRight size={18} />
                </Link>
                <a
                  href="#how"
                  className="inline-flex items-center gap-2 rounded-md border border-[var(--color-border)] px-6 py-3 text-base font-semibold text-[var(--color-foreground)] transition hover:border-[var(--color-primary)]"
                >
                  See how it works
                </a>
              </div>
              <dl className="mt-12 grid max-w-md grid-cols-3 gap-6">
                {[
                  { value: "5", label: "platform formats" },
                  { value: "1080p", label: "crisp output" },
                  { value: "Seconds", label: "to export" },
                ].map((stat) => (
                  <div key={stat.label}>
                    <dt className="text-2xl font-bold text-[var(--color-foreground)]">{stat.value}</dt>
                    <dd className="mt-1 text-sm text-[var(--color-muted-strong)]">{stat.label}</dd>
                  </div>
                ))}
              </dl>
            </div>

            {/* Hero mock — a 9:16 preview frame */}
            <div className="relative mx-auto w-full max-w-sm">
              <div className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-card)] p-4 shadow-2xl shadow-[var(--shadow-card)]">
                <div className="mb-3 flex items-center justify-between px-1">
                  <span className="text-sm font-semibold">Preview</span>
                  <span className="rounded-md bg-[var(--color-primary-soft)] px-2 py-1 text-xs font-medium text-[var(--color-primary)]">
                    Reels · 9:16
                  </span>
                </div>
                <div
                  className="relative grid aspect-[9/16] w-full place-items-center overflow-hidden rounded-xl bg-[var(--color-preview-panel)]"
                  style={{
                    background:
                      "linear-gradient(160deg, #1b1144 0%, #060e20 55%, #2a1a05 100%)",
                  }}
                >
                  <div className="flex flex-col items-center gap-3 text-[var(--color-overlay-text)]">
                    <div className="grid size-16 place-items-center rounded-full bg-white/10 backdrop-blur">
                      <Play size={26} className="ml-1" />
                    </div>
                    <p className="text-sm font-medium opacity-80">Your story, in motion</p>
                  </div>
                  <div className="absolute inset-x-0 bottom-0 bg-[var(--color-overlay)] px-4 py-3 backdrop-blur">
                    <div className="mb-2 flex justify-between text-xs text-[var(--color-overlay-text)]">
                      <span>0:00</span>
                      <span>0:30</span>
                    </div>
                    <div className="h-1.5 overflow-hidden rounded-full bg-[var(--color-overlay-track)]">
                      <div className="h-full w-2/5 rounded-full bg-[var(--color-overlay-fill)]" />
                    </div>
                  </div>
                </div>
                <div className="mt-3 flex items-center justify-between gap-2 rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)] px-3 py-2.5">
                  <span className="flex items-center gap-2 text-sm font-medium">
                    <Download size={16} className="text-[var(--color-primary)]" />
                    final.mp4
                  </span>
                  <span className="text-xs text-[var(--color-muted-strong)]">1080 × 1920</span>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Features */}
        <section id="features" className="border-t border-[var(--color-border)]">
          <div className="mx-auto w-full max-w-7xl px-5 py-20">
            <div className="max-w-2xl">
              <h2 className="text-3xl font-semibold tracking-tight sm:text-4xl">
                Everything you need to ship a post
              </h2>
              <p className="mt-4 text-lg text-[var(--color-muted)]">
                A focused toolkit that does the heavy lifting — so a single image becomes a finished video
                without leaving your browser.
              </p>
            </div>
            <div className="mt-12 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
              {features.map((feature) => (
                <div
                  key={feature.title}
                  className="rounded-xl border border-[var(--color-border)] bg-[var(--color-card)] p-6 shadow-sm transition hover:border-[var(--color-primary)]"
                >
                  <div className="grid size-11 place-items-center rounded-lg bg-[var(--color-primary-soft)] text-[var(--color-primary)]">
                    <feature.icon size={22} />
                  </div>
                  <h3 className="mt-5 text-lg font-semibold">{feature.title}</h3>
                  <p className="mt-2 text-sm leading-relaxed text-[var(--color-muted)]">{feature.body}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Formats */}
        <section id="formats" className="border-t border-[var(--color-border)] bg-[var(--color-surface)]">
          <div className="mx-auto w-full max-w-7xl px-5 py-20">
            <div className="max-w-2xl">
              <h2 className="text-3xl font-semibold tracking-tight sm:text-4xl">
                One upload, every aspect ratio
              </h2>
              <p className="mt-4 text-lg text-[var(--color-muted)]">
                Render straight into the exact dimensions each platform expects — or keep your original size.
              </p>
            </div>
            <div className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {OUTPUT_PRESETS.map((preset) => (
                <div
                  key={preset.id}
                  className="flex items-center justify-between gap-4 rounded-xl border border-[var(--color-border)] bg-[var(--color-card)] p-5 shadow-sm"
                >
                  <div>
                    <p className="font-semibold">{preset.name}</p>
                    <p className="mt-1 text-sm text-[var(--color-muted-strong)]">{preset.details}</p>
                  </div>
                  <span className="rounded-md bg-[var(--color-secondary-soft)] px-2.5 py-1 text-xs font-semibold text-[var(--color-secondary-text)]">
                    {preset.orientation}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* How it works */}
        <section id="how" className="border-t border-[var(--color-border)]">
          <div className="mx-auto w-full max-w-7xl px-5 py-20">
            <div className="max-w-2xl">
              <h2 className="text-3xl font-semibold tracking-tight sm:text-4xl">Three steps to done</h2>
              <p className="mt-4 text-lg text-[var(--color-muted)]">
                No accounts to wrangle, no timeline to learn. Upload, set it, export.
              </p>
            </div>
            <div className="mt-12 grid gap-6 md:grid-cols-3">
              {steps.map((step, index) => (
                <div key={step.title} className="relative rounded-xl border border-[var(--color-border)] bg-[var(--color-card)] p-6 shadow-sm">
                  <span className="text-sm font-semibold text-[var(--color-muted-strong)]">
                    Step {index + 1}
                  </span>
                  <div className="mt-4 grid size-11 place-items-center rounded-lg bg-[var(--color-primary-soft)] text-[var(--color-primary)]">
                    <step.icon size={22} />
                  </div>
                  <h3 className="mt-5 text-lg font-semibold">{step.title}</h3>
                  <p className="mt-2 text-sm leading-relaxed text-[var(--color-muted)]">{step.body}</p>
                </div>
              ))}
            </div>

            {/* Specs */}
            <div className="mt-10 grid gap-4 rounded-2xl border border-[var(--color-border)] bg-[var(--color-card)] p-6 sm:grid-cols-2 lg:grid-cols-4">
              {specs.map((spec) => (
                <div key={spec.label} className="flex items-start gap-3">
                  <Check size={18} className="mt-0.5 shrink-0 text-[var(--color-primary)]" />
                  <div>
                    <p className="text-sm font-semibold">{spec.label}</p>
                    <p className="mt-0.5 text-sm text-[var(--color-muted-strong)]">{spec.value}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* CTA band */}
        <section className="border-t border-[var(--color-border)]">
          <div className="mx-auto w-full max-w-7xl px-5 py-20">
            <div
              className="relative overflow-hidden rounded-3xl border border-[var(--color-border)] bg-[var(--color-card)] px-6 py-14 text-center shadow-sm sm:px-12"
            >
              <div
                aria-hidden
                className="pointer-events-none absolute inset-0"
                style={{
                  background:
                    "radial-gradient(60% 120% at 50% 0%, rgb(124 58 237 / 18%), transparent 70%)",
                }}
              />
              <div className="relative">
                <h2 className="mx-auto max-w-2xl text-3xl font-semibold tracking-tight sm:text-4xl">
                  Your next post is one upload away
                </h2>
                <p className="mx-auto mt-4 max-w-xl text-lg text-[var(--color-muted)]">
                  Open the editor and turn an image into a finished video right now.
                </p>
                <Link
                  href="/editor"
                  className="mt-8 inline-flex items-center gap-2 rounded-md bg-[var(--color-primary)] px-7 py-3 text-base font-semibold text-[var(--color-primary-text)] shadow-sm shadow-[var(--shadow-primary)] transition hover:bg-[var(--color-primary-hover)]"
                >
                  Open the editor
                  <ArrowRight size={18} />
                </Link>
              </div>
            </div>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="border-t border-[var(--color-border)]">
        <div className="mx-auto flex w-full max-w-7xl flex-col items-center justify-between gap-4 px-5 py-8 sm:flex-row">
          <div className="flex items-center gap-3">
            <div className="grid size-8 place-items-center rounded-md bg-[var(--color-primary)] text-[var(--color-primary-text)]">
              <Sparkles size={16} strokeWidth={2.4} />
            </div>
            <p className="text-sm text-[var(--color-muted)]">
              Stillora — Built by{" "}
              <a
                className="font-medium text-[var(--color-foreground)] underline-offset-4 hover:underline"
                href="https://tecnoblocks.com"
                rel="noreferrer"
                target="_blank"
              >
                Tecno Blocks
              </a>
            </p>
          </div>
          <p className="text-sm text-[var(--color-muted-strong)]">
            © {new Date().getFullYear()} Stillora. All rights reserved.
          </p>
        </div>
      </footer>
    </div>
  );
}
