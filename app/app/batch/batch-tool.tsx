"use client";

import { Download, FileText, ImageIcon, Loader2, Sparkles, Trash2, Upload, X } from "lucide-react";
import { useCallback, useRef, useState } from "react";
import { AppNavbar } from "@/app/components/app-navbar";
import { AuthControls } from "@/app/components/auth-controls";
import { readImageDimensions } from "@/app/editor/editor-utils";
import { renderPdfFirstPage } from "./pdf";
import {
  BATCH_ACCEPT,
  CONCURRENCY,
  MAX_IMAGES,
  baseNameOf,
  isPdf,
  type BatchItem,
  type SourceKind,
} from "./batch-utils";
import { StatusBadge } from "./status-badge";
import {
  DEFAULT_DURATION_SECONDS,
  FIXED_DURATION_SECONDS,
  FitMode,
  IMAGE_MIME_TYPES,
  MAX_IMAGE_BYTES,
  OUTPUT_PRESETS,
  OutputPresetId,
  formatBytes,
} from "@/lib/stillora";

export function BatchTool() {
  const [items, setItems] = useState<BatchItem[]>([]);
  const [presetId, setPresetId] = useState<OutputPresetId>("reels");
  const [fitMode, setFitMode] = useState<FitMode>("fill");
  const [duration, setDuration] = useState<number>(DEFAULT_DURATION_SECONDS);
  const [isRunning, setIsRunning] = useState(false);
  const [isImporting, setIsImporting] = useState(false);
  const [needsAuth, setNeedsAuth] = useState(false);
  const [dragActive, setDragActive] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const addFiles = useCallback(async (fileList: FileList | File[]) => {
    const incoming = Array.from(fileList);
    const accepted: BatchItem[] = [];
    setIsImporting(true);

    for (const file of incoming) {
      if (file.size > MAX_IMAGE_BYTES) continue;

      let exportFile = file;
      let source: SourceKind = "image";
      let dims: { width: number; height: number } | null = null;

      if (isPdf(file)) {
        // Rasterize page 1 → PNG, then treat exactly like a static image.
        const rendered = await renderPdfFirstPage(file);
        if (!rendered) continue;
        exportFile = rendered.file;
        dims = { width: rendered.width, height: rendered.height };
        source = "pdf";
      } else {
        const okImage = IMAGE_MIME_TYPES.has(file.type) || /\.(jpe?g|png|webp)$/i.test(file.name);
        if (!okImage) continue;
        const probeUrl = URL.createObjectURL(exportFile);
        dims = await readImageDimensions(probeUrl);
        URL.revokeObjectURL(probeUrl);
      }

      if (!dims) continue;
      accepted.push({
        id: `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
        file: exportFile,
        url: URL.createObjectURL(exportFile),
        width: dims.width,
        height: dims.height,
        baseName: baseNameOf(file.name),
        source,
        status: "ready",
      });
    }

    setItems((prev) => [...prev, ...accepted].slice(0, MAX_IMAGES));
    setIsImporting(false);
  }, []);

  const removeItem = useCallback((id: string) => {
    setItems((prev) => {
      const item = prev.find((i) => i.id === id);
      if (item) {
        URL.revokeObjectURL(item.url);
        if (item.resultUrl) URL.revokeObjectURL(item.resultUrl);
      }
      return prev.filter((i) => i.id !== id);
    });
  }, []);

  const clearAll = useCallback(() => {
    setItems((prev) => {
      prev.forEach((i) => {
        URL.revokeObjectURL(i.url);
        if (i.resultUrl) URL.revokeObjectURL(i.resultUrl);
      });
      return [];
    });
  }, []);

  const patch = useCallback((id: string, next: Partial<BatchItem>) => {
    setItems((prev) => prev.map((i) => (i.id === id ? { ...i, ...next } : i)));
  }, []);

  const renderOne = useCallback(
    async (item: BatchItem) => {
      patch(item.id, { status: "rendering", error: undefined });
      try {
        const metadata = {
          sourceKind: "image" as const,
          presetId,
          fitMode,
          duration,
          imageWidth: item.width,
          imageHeight: item.height,
        };
        const formData = new FormData();
        formData.append("metadata", JSON.stringify(metadata));
        formData.append("source", item.file);

        const response = await fetch("/api/exports", { method: "POST", body: formData });
        if (response.status === 401) {
          setNeedsAuth(true);
          patch(item.id, { status: "error", error: "Sign in to export" });
          return;
        }
        if (!response.ok) {
          const data = await response.json().catch(() => null);
          patch(item.id, { status: "error", error: data?.error ?? "Export failed" });
          return;
        }
        const blob = await response.blob();
        patch(item.id, { status: "done", resultUrl: URL.createObjectURL(blob) });
      } catch {
        patch(item.id, { status: "error", error: "Network error" });
      }
    },
    [duration, fitMode, patch, presetId],
  );

  const convertAll = useCallback(async () => {
    setNeedsAuth(false);
    setIsRunning(true);
    // snapshot the queue (everything not already done)
    const queue = items.filter((i) => i.status !== "done");
    let cursor = 0;
    const worker = async () => {
      while (cursor < queue.length) {
        const item = queue[cursor++];
        await renderOne(item);
      }
    };
    await Promise.all(Array.from({ length: Math.min(CONCURRENCY, queue.length) }, worker));
    setIsRunning(false);
  }, [items, renderOne]);

  const downloadAll = useCallback(() => {
    items
      .filter((i) => i.status === "done" && i.resultUrl)
      .forEach((i, index) => {
        setTimeout(() => {
          const a = document.createElement("a");
          a.href = i.resultUrl!;
          a.download = `${i.baseName}.mp4`;
          document.body.appendChild(a);
          a.click();
          a.remove();
        }, index * 350);
      });
  }, [items]);

  const doneCount = items.filter((i) => i.status === "done").length;
  const canConvert = items.length > 0 && !isRunning;

  return (
    <main className="relative min-h-screen overflow-x-hidden bg-[image:var(--editor-page-bg)] text-foreground">
      <div className="pointer-events-none absolute inset-0 overflow-hidden">
        <div className="editor-orb editor-orb-primary" />
        <div className="editor-orb editor-orb-accent" />
        <div className="editor-grid-bg" />
      </div>

      <div className="relative z-10">
        <AppNavbar />
        <div className="mx-auto w-full max-w-5xl px-4 pb-16 pt-24 sm:px-6 sm:pt-28">
          <div className="mb-2 inline-flex items-center gap-2 rounded-full border border-primary/20 bg-primary/10 px-3 py-1 text-xs font-semibold text-primary">
            <Sparkles className="size-3.5" />
            Batch · Loop images
          </div>
          <h1 className="text-3xl font-extrabold tracking-tight sm:text-4xl">
            Turn images &amp; PDFs into <span className="gradient-text">separate MP4s</span>
          </h1>
          <p className="mt-3 max-w-2xl text-sm text-muted-foreground sm:text-base">
            Add up to {MAX_IMAGES} images or PDFs, pick one format and one duration, and Stillora
            renders <b className="text-foreground">one video per file</b> — they are not merged. Each
            image (or a PDF&apos;s first page) becomes its own MP4 of the duration you choose.
          </p>

          {/* settings */}
          <section className="editor-card mt-8 rounded-xl border p-5 sm:p-6">
            <h2 className="mb-4 text-sm font-bold uppercase tracking-wide text-muted-foreground">
              Applies to every image
            </h2>

            <p className="mb-2 text-xs font-semibold text-muted-foreground">Format preset</p>
            <div className="mb-5 grid grid-cols-1 gap-2 sm:grid-cols-2 lg:grid-cols-3">
              {OUTPUT_PRESETS.map((preset) => (
                <button
                  key={preset.id}
                  type="button"
                  onClick={() => setPresetId(preset.id)}
                  className={`rounded-lg border p-3 text-left transition ${
                    presetId === preset.id
                      ? "editor-active"
                      : "border-border/60 bg-card/50 hover:border-primary/40"
                  }`}
                >
                  <p className="text-sm font-semibold text-foreground">{preset.name}</p>
                  <p className="mt-0.5 font-mono text-[11px] text-muted-foreground">{preset.details}</p>
                </button>
              ))}
            </div>

            <div className="grid gap-5 sm:grid-cols-2">
              <div>
                <p className="mb-2 text-xs font-semibold text-muted-foreground">Image mode</p>
                <div className="inline-flex rounded-lg border border-border/60 p-1">
                  {(["fit", "fill"] as FitMode[]).map((mode) => (
                    <button
                      key={mode}
                      type="button"
                      onClick={() => setFitMode(mode)}
                      className={`rounded-md px-4 py-1.5 text-sm font-semibold capitalize transition ${
                        fitMode === mode ? "bg-primary text-primary-foreground" : "text-muted-foreground"
                      }`}
                    >
                      {mode}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <p className="mb-2 text-xs font-semibold text-muted-foreground">Duration (each)</p>
                <div className="flex flex-wrap gap-2">
                  {FIXED_DURATION_SECONDS.map((sec) => (
                    <button
                      key={sec}
                      type="button"
                      onClick={() => setDuration(sec)}
                      className={`rounded-md border px-3 py-1.5 text-sm font-semibold transition ${
                        duration === sec
                          ? "border-primary bg-primary/15 text-primary"
                          : "border-border/60 text-muted-foreground hover:border-primary/40"
                      }`}
                    >
                      {sec}s
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </section>

          {/* dropzone */}
          <section className="mt-6">
            <input
              ref={inputRef}
              type="file"
              accept={BATCH_ACCEPT}
              multiple
              hidden
              onChange={(e) => {
                if (e.target.files) void addFiles(e.target.files);
                e.target.value = "";
              }}
            />
            <button
              type="button"
              onClick={() => inputRef.current?.click()}
              onDragOver={(e) => {
                e.preventDefault();
                setDragActive(true);
              }}
              onDragLeave={() => setDragActive(false)}
              onDrop={(e) => {
                e.preventDefault();
                setDragActive(false);
                if (e.dataTransfer.files) void addFiles(e.dataTransfer.files);
              }}
              className={`flex w-full flex-col items-center justify-center gap-2 rounded-xl border-2 border-dashed p-8 text-center transition ${
                dragActive ? "border-primary bg-primary/10" : "border-border/70 bg-card/40 hover:border-primary/50"
              }`}
            >
              {isImporting ? <Loader2 className="size-7 animate-spin text-primary" /> : <Upload className="size-7 text-primary" />}
              <span className="text-sm font-semibold text-foreground">
                {isImporting ? "Importing…" : "Drop images or PDFs, or click to upload"}
              </span>
              <span className="text-xs text-muted-foreground">
                JPG, PNG, WebP, PDF (first page) · up to {MAX_IMAGES} files · {items.length}/{MAX_IMAGES} added
              </span>
            </button>
          </section>

          {/* actions */}
          {items.length > 0 ? (
            <div className="mt-6 flex flex-wrap items-center gap-3">
              <button
                type="button"
                disabled={!canConvert}
                onClick={() => void convertAll()}
                className="inline-flex items-center gap-2 rounded-full bg-primary px-6 py-3 text-sm font-bold text-primary-foreground shadow-lg shadow-primary/30 transition hover:opacity-90 disabled:opacity-50"
              >
                {isRunning ? <Loader2 className="size-4 animate-spin" /> : <Sparkles className="size-4" />}
                {isRunning ? "Converting…" : `Convert ${items.length} ${items.length === 1 ? "image" : "images"}`}
              </button>
              {doneCount > 0 ? (
                <button
                  type="button"
                  onClick={downloadAll}
                  className="inline-flex items-center gap-2 rounded-full border border-border bg-card px-5 py-3 text-sm font-semibold text-foreground transition hover:border-primary/50"
                >
                  <Download className="size-4" />
                  Download all ({doneCount})
                </button>
              ) : null}
              <button
                type="button"
                onClick={clearAll}
                disabled={isRunning}
                className="inline-flex items-center gap-2 rounded-full px-3 py-3 text-sm font-medium text-muted-foreground transition hover:text-foreground disabled:opacity-50"
              >
                <Trash2 className="size-4" />
                Clear
              </button>
            </div>
          ) : null}

          {needsAuth ? (
            <div className="mt-5 flex flex-wrap items-center gap-3 rounded-lg border border-amber-500/30 bg-amber-500/10 p-4 text-sm text-amber-200">
              <span className="font-semibold">Sign in to export your videos.</span>
              <AuthControls callbackUrl="/batch" />
            </div>
          ) : null}

          {/* results grid */}
          {items.length > 0 ? (
            <section className="mt-8 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
              {items.map((item) => (
                <article key={item.id} className="group relative overflow-hidden rounded-xl border border-border/60 bg-card/60">
                  <div className="relative aspect-[3/4] overflow-hidden bg-black/30">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img src={item.url} alt={item.baseName} className="size-full object-cover" />
                    <button
                      type="button"
                      onClick={() => removeItem(item.id)}
                      disabled={isRunning}
                      aria-label="Remove image"
                      className="absolute right-1.5 top-1.5 grid size-7 place-items-center rounded-full bg-black/60 text-white transition hover:bg-black/80 disabled:opacity-40"
                    >
                      <X className="size-4" />
                    </button>
                    {item.source === "pdf" ? (
                      <span className="absolute left-1.5 top-1.5 inline-flex items-center gap-1 rounded-md bg-black/60 px-1.5 py-0.5 text-[9px] font-bold text-white">
                        <FileText className="size-2.5" />
                        PDF p.1
                      </span>
                    ) : null}
                    <div className="absolute bottom-1.5 left-1.5">
                      <StatusBadge status={item.status} error={item.error} />
                    </div>
                  </div>
                  <div className="flex items-center justify-between gap-2 p-2.5">
                    <div className="min-w-0">
                      <p className="truncate text-xs font-semibold text-foreground">{item.baseName}.mp4</p>
                      <p className="font-mono text-[10px] text-muted-foreground">
                        {item.width}×{item.height} · {formatBytes(item.file.size)}
                      </p>
                    </div>
                    {item.status === "done" && item.resultUrl ? (
                      <a
                        href={item.resultUrl}
                        download={`${item.baseName}.mp4`}
                        className="inline-flex flex-shrink-0 items-center gap-1 rounded-md bg-primary px-2.5 py-1.5 text-xs font-bold text-primary-foreground transition hover:opacity-90"
                      >
                        <Download className="size-3.5" />
                        MP4
                      </a>
                    ) : null}
                  </div>
                </article>
              ))}
            </section>
          ) : (
            <div className="mt-10 flex flex-col items-center gap-2 text-center text-muted-foreground">
              <ImageIcon className="size-8 opacity-40" />
              <p className="text-sm">No images yet — add some above to get started.</p>
            </div>
          )}
        </div>
      </div>
    </main>
  );
}
