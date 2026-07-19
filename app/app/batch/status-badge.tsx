"use client";

import { Loader2 } from "lucide-react";
import type { ItemStatus } from "./batch-utils";

export function StatusBadge({ status, error }: { status: ItemStatus; error?: string }) {
  if (status === "rendering") {
    return (
      <span className="inline-flex items-center gap-1 rounded-full bg-primary/90 px-2 py-0.5 text-[10px] font-bold text-white">
        <Loader2 className="size-2.5 animate-spin" />
        Rendering
      </span>
    );
  }
  if (status === "done") {
    return <span className="rounded-full bg-green-500/90 px-2 py-0.5 text-[10px] font-bold text-white">Done</span>;
  }
  if (status === "error") {
    return (
      <span className="rounded-full bg-red-500/90 px-2 py-0.5 text-[10px] font-bold text-white" title={error}>
        {error ?? "Error"}
      </span>
    );
  }
  return <span className="rounded-full bg-black/60 px-2 py-0.5 text-[10px] font-bold text-white/80">Ready</span>;
}
