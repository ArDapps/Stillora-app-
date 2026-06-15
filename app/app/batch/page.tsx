import type { Metadata } from "next";
import { BatchTool } from "./batch-tool";

export const metadata: Metadata = {
  title: "Batch images & PDFs to MP4 — one video per file",
  description:
    "Upload many images or PDFs, pick one format preset and one duration, and Stillora renders a separate MP4 for each. A PDF's first page is converted like a static image. No merging — every file becomes its own video.",
  alternates: { canonical: "/batch" },
};

export default function BatchPage() {
  return <BatchTool />;
}
