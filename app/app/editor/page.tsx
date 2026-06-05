"use client";

import { SiteHeader } from "@/app/components/site-header";
import { AudioPanel } from "./components/audio-panel";
import { PreviewPanel } from "./components/preview-panel";
import { SettingsExportPanel } from "./components/settings-export-panel";
import { SourceMediaPanel } from "./components/source-media-panel";
import { useEditorModel } from "./use-editor-model";

export default function Editor() {
  const model = useEditorModel();

  return (
    <main className="min-h-screen bg-[image:var(--editor-page-bg)] text-[var(--color-foreground)]">
      <div className="flex min-h-screen flex-col">
        <SiteHeader />
        <div className="mx-auto p-8 mb-6 grid w-full max-w-7xl flex-1 items-start gap-4 px-3 sm:gap-5 sm:px-6 lg:grid-cols-[minmax(320px,390px)_minmax(0,1fr)]">
          <aside className="order-1 space-y-4">
            <SourceMediaPanel model={model} />
            <AudioPanel model={model} />
          </aside>
          <PreviewPanel model={model} />
          <SettingsExportPanel model={model} />
        </div>
      </div>
    </main>
  );
}
