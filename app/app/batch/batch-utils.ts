import { IMAGE_ACCEPT } from "@/lib/stillora";

export const MAX_IMAGES = 30;
export const CONCURRENCY = 2;
export const BATCH_ACCEPT = `${IMAGE_ACCEPT},.pdf`;

export type ItemStatus = "ready" | "rendering" | "done" | "error";
export type SourceKind = "image" | "pdf";

export type BatchItem = {
  id: string;
  file: File;
  url: string;
  width: number;
  height: number;
  baseName: string;
  source: SourceKind;
  status: ItemStatus;
  resultUrl?: string;
  error?: string;
};

export function isPdf(file: File) {
  return file.type === "application/pdf" || /\.pdf$/i.test(file.name);
}

export function baseNameOf(name: string) {
  const dot = name.lastIndexOf(".");
  return (dot > 0 ? name.slice(0, dot) : name).replace(/[^\w-]+/g, "-").slice(0, 60) || "image";
}
