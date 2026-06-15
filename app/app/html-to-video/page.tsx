"use client";

import { useRef, useState } from "react";
import { Code2, Download, FileUp, Link2, Loader2, Sparkles, X } from "lucide-react";
import { AppNavbar } from "@/app/components/app-navbar";
import { stepBadgeClass } from "@/app/editor/components/shared";

type Mode = "paste" | "file" | "url";
type Status = "idle" | "loading" | "done" | "error";

const SIZES = [
  { id: "9:16", label: "Vertical", ratio: "9:16", w: 1080, h: 1920 },
  { id: "1:1", label: "Square", ratio: "1:1", w: 1080, h: 1080 },
  { id: "16:9", label: "Landscape", ratio: "16:9", w: 1920, h: 1080 },
  { id: "4:5", label: "Portrait", ratio: "4:5", w: 1080, h: 1350 },
];
const FPS = [24, 30, 60];

export default function HtmlToVideoPage() {
  const [mode, setMode] = useState<Mode>("paste");
  const [html, setHtml] = useState("");
  const [url, setUrl] = useState("");
  const [fileName, setFileName] = useState<string | null>(null);
  const [size, setSize] = useState(SIZES[0]);
  const [duration, setDuration] = useState(10);
  const [fps, setFps] = useState(30);
  const [status, setStatus] = useState<Status>("idle");
  const [error, setError] = useState("");
  const [videoUrl, setVideoUrl] = useState<string | null>(null);
  const abortRef = useRef<AbortController | null>(null);

  const loading = status === "loading";

  async function onPickFile(file: File) {
    setHtml(await file.text());
    setFileName(file.name);
    setError("");
  }

  async function convert() {
    const trimmedHtml = html.trim();
    const trimmedUrl = url.trim();
    if (mode === "url" && !trimmedUrl) {
      setError("Enter a URL to render.");
      return;
    }
    if (mode !== "url" && !trimmedHtml) {
      setError(mode === "file" ? "Pick an .html file first." : "Paste some HTML first.");
      return;
    }

    const controller = new AbortController();
    abortRef.current = controller;
    setStatus("loading");
    setError("");

    try {
      const res = await fetch("/api/convert/html", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        signal: controller.signal,
        body: JSON.stringify({
          ...(mode === "url" ? { url: trimmedUrl } : { html: trimmedHtml }),
          width: size.w,
          height: size.h,
          durationMs: duration * 1000,
          fps,
        }),
      });
      if (!res.ok) {
        const data = (await res.json().catch(() => null)) as { error?: string } | null;
        throw new Error(data?.error ?? "Render failed.");
      }
      const blob = await res.blob();
      setVideoUrl((prev) => {
        if (prev) URL.revokeObjectURL(prev);
        return URL.createObjectURL(blob);
      });
      setStatus("done");
    } catch (err) {
      if (controller.signal.aborted) {
        setStatus("idle");
        return;
      }
      setError(err instanceof Error ? err.message : "Render failed.");
      setStatus("error");
    }
  }

  function cancel() {
    abortRef.current?.abort();
  }

  return (
    <main className="relative min-h-screen overflow-x-hidden bg-[image:var(--editor-page-bg)] text-[var(--color-foreground)]">
      <div className="pointer-events-none absolute inset-0 overflow-hidden">
        <div className="editor-orb editor-orb-primary" />
        <div className="editor-orb editor-orb-accent" />
        <div className="editor-grid-bg" />
      </div>

      <div className="relative z-10 flex min-h-screen flex-col">
        <AppNavbar />
        <div className="mx-auto w-full max-w-[1280px] px-4 pb-12 pt-24 sm:px-6 sm:pt-28">
          <div className="mb-2 inline-flex items-center gap-2 rounded-full border border-primary/20 bg-primary/10 px-3 py-1 text-xs font-semibold text-primary">
            <Sparkles className="size-3.5" />
            NEW RENDER
          </div>
          <h1 className="text-3xl font-extrabold tracking-tight sm:text-4xl">
            HTML to <span className="gradient-text">share-ready video</span>
          </h1>
          <p className="mt-2 max-w-xl text-sm text-muted-foreground">
            Paste markup, drop an .html file, or enter a URL. Stillora renders the
            animation frame-by-frame into a clean MP4.
          </p>

          <div className="mt-6 grid gap-5 lg:grid-cols-[minmax(0,1fr)_minmax(360px,460px)]">
            {/* Controls */}
            <div className="space-y-4">
              <Card step="1" title="Source" tag="required">
                <div className="grid grid-cols-3 gap-2">
                  {(
                    [
                      ["paste", "Paste", Code2],
                      ["file", "File", FileUp],
                      ["url", "URL", Link2],
                    ] as const
                  ).map(([value, label, Icon]) => (
                    <button
                      key={value}
                      type="button"
                      onClick={() => {
                        setMode(value);
                        setError("");
                      }}
                      className={`flex items-center justify-center gap-1.5 rounded-lg border px-3 py-2 text-sm font-semibold transition ${
                        mode === value ? "editor-active" : "editor-control-soft hover:border-fuchsia-300"
                      }`}
                    >
                      <Icon className="size-4" />
                      {label}
                    </button>
                  ))}
                </div>
                <div className="mt-3">
                  {mode === "paste" && (
                    <textarea
                      value={html}
                      onChange={(e) => setHtml(e.target.value)}
                      rows={8}
                      placeholder="<html>…</html>"
                      className="editor-control-soft w-full rounded-lg border p-3 font-mono text-xs focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]"
                    />
                  )}
                  {mode === "file" && (
                    <label className="editor-control-soft flex cursor-pointer flex-col items-center gap-2 rounded-lg border border-dashed px-4 py-8 text-center transition hover:border-fuchsia-300">
                      <FileUp className="size-7 text-fuchsia-300" />
                      <span className="text-sm font-semibold">
                        {fileName ?? "Drop an .html file"}
                      </span>
                      <span className="text-xs text-muted-foreground">
                        or click to browse · .html .htm
                      </span>
                      <input
                        type="file"
                        accept=".html,.htm,text/html"
                        className="hidden"
                        onChange={(e) => {
                          const file = e.target.files?.[0];
                          if (file) void onPickFile(file);
                        }}
                      />
                    </label>
                  )}
                  {mode === "url" && (
                    <input
                      type="url"
                      value={url}
                      onChange={(e) => setUrl(e.target.value)}
                      placeholder="https://example.com/animation.html"
                      className="editor-control-soft w-full rounded-lg border px-3 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]"
                    />
                  )}
                </div>
              </Card>

              <Card step="2" title="Output size" tag={`${size.w}×${size.h}`}>
                <div className="grid grid-cols-2 gap-2">
                  {SIZES.map((option) => (
                    <button
                      key={option.id}
                      type="button"
                      onClick={() => setSize(option)}
                      className={`flex items-center gap-3 rounded-lg border p-3 text-left transition ${
                        option.id === size.id ? "editor-active" : "editor-control-soft hover:border-fuchsia-300"
                      }`}
                    >
                      <span
                        className={`grid size-5 place-items-center rounded border ${
                          option.id === size.id
                            ? "border-fuchsia-400 bg-fuchsia-500 text-white"
                            : "border-[var(--color-border)]"
                        }`}
                      >
                        {option.id === size.id ? "✓" : ""}
                      </span>
                      <span>
                        <span className="block text-sm font-semibold">{option.label}</span>
                        <span className="block text-xs text-muted-foreground">{option.ratio}</span>
                      </span>
                    </button>
                  ))}
                </div>
              </Card>

              <Card step="3" title="Duration & frame rate">
                <div className="flex items-center justify-between">
                  <span className="text-sm font-semibold text-muted-foreground">Duration</span>
                  <span className="text-sm font-bold text-primary">{duration} s</span>
                </div>
                <input
                  type="range"
                  min={1}
                  max={60}
                  value={duration}
                  onChange={(e) => setDuration(Number(e.target.value))}
                  className="mt-2 w-full accent-fuchsia-500"
                />
                <div className="mt-4 text-sm font-semibold text-muted-foreground">Frame rate</div>
                <div className="mt-2 grid grid-cols-3 gap-2">
                  {FPS.map((value) => (
                    <button
                      key={value}
                      type="button"
                      onClick={() => setFps(value)}
                      className={`rounded-lg border px-3 py-2 text-sm font-semibold transition ${
                        value === fps ? "editor-active" : "editor-control-soft hover:border-fuchsia-300"
                      }`}
                    >
                      {value} fps
                    </button>
                  ))}
                </div>
              </Card>

              {error && (
                <p className="rounded-lg border border-[var(--color-danger)]/40 bg-[var(--color-danger)]/10 px-4 py-3 text-sm text-[var(--color-danger)]">
                  {error}
                </p>
              )}
            </div>

            {/* Preview */}
            <aside className="editor-card flex flex-col rounded-lg border p-4">
              <div className="flex items-center justify-between">
                <span className="rounded-full bg-primary/15 px-3 py-1 text-xs font-bold text-primary">
                  {size.label} · {size.ratio}
                </span>
                <span className="font-mono text-xs text-muted-foreground">
                  {size.w} × {size.h}
                </span>
              </div>

              <div className="mt-4 flex flex-1 items-center justify-center">
                <div
                  className="relative w-full overflow-hidden rounded-xl border border-[var(--color-border)] bg-[repeating-linear-gradient(45deg,transparent,transparent_12px,rgba(255,255,255,0.03)_12px,rgba(255,255,255,0.03)_13px)]"
                  style={{ aspectRatio: `${size.w} / ${size.h}`, maxHeight: 460 }}
                >
                  {videoUrl ? (
                    <video
                      key={videoUrl}
                      src={videoUrl}
                      controls
                      autoPlay
                      loop
                      muted
                      className="absolute inset-0 size-full object-contain"
                    />
                  ) : (
                    <div className="absolute inset-0 grid place-items-center">
                      {loading ? (
                        <span className="flex flex-col items-center gap-2 text-sm text-muted-foreground">
                          <Loader2 className="size-6 animate-spin" />
                          Rendering…
                        </span>
                      ) : (
                        <span className="font-mono text-sm text-muted-foreground">
                          your video renders here
                        </span>
                      )}
                    </div>
                  )}
                </div>
              </div>

              <div className="mt-4 flex items-center justify-between rounded-lg border border-[var(--color-border)] px-3 py-2 font-mono text-xs text-muted-foreground">
                <span>stillora.mp4</span>
                <span>
                  {size.h >= 1080 ? "1080p" : "720p"} · H.264 · {fps} fps
                </span>
              </div>

              {loading ? (
                <button
                  type="button"
                  onClick={cancel}
                  className="mt-4 flex items-center justify-center gap-2 rounded-lg border border-[var(--color-border)] px-4 py-3 text-sm font-bold transition hover:border-[var(--color-danger)]"
                >
                  <X className="size-4" />
                  Cancel
                </button>
              ) : (
                <button
                  type="button"
                  onClick={() => void convert()}
                  className="mt-4 flex items-center justify-center gap-2 rounded-lg bg-[linear-gradient(145deg,#a855f7,#6366f1)] px-4 py-3 text-sm font-bold text-white shadow-[0_0_24px_rgb(168_85_247_/_0.4)] transition hover:opacity-90"
                >
                  <Sparkles className="size-4" />
                  Convert to MP4
                </button>
              )}

              {videoUrl && !loading && (
                <a
                  href={videoUrl}
                  download="stillora.mp4"
                  className="editor-control-soft mt-2 flex items-center justify-center gap-2 rounded-lg border px-4 py-3 text-sm font-bold transition hover:border-fuchsia-300"
                >
                  <Download className="size-4" />
                  Download
                </a>
              )}
            </aside>
          </div>
        </div>
      </div>
    </main>
  );
}

function Card({
  step,
  title,
  tag,
  children,
}: {
  step: string;
  title: string;
  tag?: string;
  children: React.ReactNode;
}) {
  return (
    <section className="editor-card rounded-lg border p-4">
      <div className="flex items-center gap-3">
        <span className={stepBadgeClass}>{step}</span>
        <h2 className="editor-title flex-1 text-base font-semibold">{title}</h2>
        {tag && (
          <span className="rounded-full border border-[var(--color-border)] px-2 py-0.5 font-mono text-[11px] text-muted-foreground">
            {tag}
          </span>
        )}
      </div>
      <div className="mt-4">{children}</div>
    </section>
  );
}
