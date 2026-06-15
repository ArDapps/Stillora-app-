/**
 * Render the FIRST page of a PDF to a PNG File entirely in the browser.
 * The resulting image flows through the same image → MP4 export pipeline,
 * so the server never needs to understand PDFs. Only page 1 is used.
 */
let workerConfigured = false;

function pdfBaseName(name: string) {
  return name.replace(/\.pdf$/i, "");
}

export async function renderPdfFirstPage(
  file: File,
): Promise<{ file: File; width: number; height: number } | null> {
  try {
    const pdfjs = await import("pdfjs-dist");
    if (!workerConfigured) {
      pdfjs.GlobalWorkerOptions.workerSrc = "/pdf.worker.min.mjs";
      workerConfigured = true;
    }

    const data = await file.arrayBuffer();
    const doc = await pdfjs.getDocument({ data }).promise;
    const page = await doc.getPage(1);

    // Scale page 1 up to a crisp size without exploding memory.
    const unit = page.getViewport({ scale: 1 });
    const maxDim = Math.max(unit.width, unit.height);
    const scale = Math.min(3, Math.max(1, 1800 / maxDim));
    const viewport = page.getViewport({ scale });

    const canvas = document.createElement("canvas");
    canvas.width = Math.round(viewport.width);
    canvas.height = Math.round(viewport.height);
    const ctx = canvas.getContext("2d");
    if (!ctx) {
      await doc.destroy();
      return null;
    }

    // PDFs render with a transparent background — flatten onto white.
    ctx.fillStyle = "#ffffff";
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    await page.render({ canvasContext: ctx, viewport }).promise;

    const blob = await new Promise<Blob | null>((resolve) =>
      canvas.toBlob(resolve, "image/png"),
    );
    await doc.destroy();
    if (!blob) return null;

    const png = new File([blob], `${pdfBaseName(file.name)}.png`, { type: "image/png" });
    return { file: png, width: canvas.width, height: canvas.height };
  } catch {
    return null;
  }
}
