"use client";

import { AppNavbar } from "@/app/components/app-navbar";
import { Film, Layers, Sparkles, Timer } from "lucide-react";
import { AudioPanel } from "./components/audio-panel";
import { PreviewPanel } from "./components/preview-panel";
import { SettingsExportPanel } from "./components/settings-export-panel";
import { SourceMediaPanel } from "./components/source-media-panel";
import { useEditorModel } from "./use-editor-model";

export default function Editor() {
  const model = useEditorModel();

  return (
    <main className="relative min-h-screen overflow-x-hidden bg-[image:var(--editor-page-bg)] text-[var(--color-foreground)] lg:h-dvh lg:overflow-hidden">
      <div className="pointer-events-none absolute inset-0 overflow-hidden">
        <div className="editor-orb editor-orb-primary" />
        <div className="editor-orb editor-orb-accent" />
        <div className="editor-grid-bg" />
      </div>

      <div className="relative z-10 flex min-h-screen flex-col lg:h-full lg:min-h-0">
        <AppNavbar />
        <div className="mx-auto flex w-full max-w-[1440px] flex-1 flex-col px-3 pb-6 pt-24 sm:px-6 sm:pt-28 lg:min-h-0 lg:pb-5 lg:pt-24">
          <div className="grid flex-1 items-start gap-4 sm:gap-5 lg:min-h-0 lg:grid-cols-[minmax(320px,440px)_minmax(0,1fr)] lg:items-stretch">
            <aside className="editor-scroll-column contents lg:order-1 lg:block lg:min-h-0 lg:space-y-4 lg:overflow-y-auto lg:pr-1">
              <header className="editor-toolbar-panel editor-animate-in order-1 rounded-lg border px-4 py-4">
                <div className="mb-2 inline-flex items-center gap-2 rounded-full border border-primary/20 bg-primary/10 px-3 py-1 text-xs font-semibold text-primary">
                  <Sparkles className="size-3.5" />
                  Stillora editor
                </div>
                <h1 className="editor-title text-2xl font-extrabold tracking-tight">
                  Create your <span className="gradient-text">social MP4</span>
                </h1>
                <div className="mt-4 grid grid-cols-3 gap-2 text-xs">
                  {[
                    { icon: Layers, label: "Media", value: "Upload" },
                    { icon: Timer, label: "Timing", value: "10-60s" },
                    { icon: Film, label: "Export", value: "MP4" },
                  ].map((item) => (
                    <div className="editor-stat-chip rounded-lg border px-3 py-2" key={item.label}>
                      <item.icon className="mb-1 size-4 text-primary" />
                      <p className="font-bold text-foreground">{item.label}</p>
                      <p className="text-[11px] text-muted-foreground">{item.value}</p>
                    </div>
                  ))}
                </div>
              </header>

              <div className="editor-animate-in order-3 space-y-4 lg:order-none">
                <SourceMediaPanel model={model} />
                <AudioPanel model={model} />
              </div>
              <div className="order-4 lg:order-none">
                <SettingsExportPanel model={model} />
              </div>
            </aside>
            <section className="editor-scroll-column order-2 lg:min-h-0 lg:overflow-y-auto">
              <PreviewPanel model={model} />
            </section>
          </div>
        </div>
      </div>
    </main>
  );
}
