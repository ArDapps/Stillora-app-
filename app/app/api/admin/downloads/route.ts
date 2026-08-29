import { type NextRequest } from "next/server";
import { getAdminFromRequest } from "@/lib/admin";
import { isDownloadPlatform, MAX_DOWNLOAD_BYTES } from "@/lib/downloads";
import {
  getDownloadLinks,
  setFileLink,
  setUrlLink,
} from "@/lib/downloads-store";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

async function requireAdmin(request: NextRequest): Promise<boolean> {
  return (await getAdminFromRequest(request)) !== null;
}

export async function GET(request: NextRequest) {
  if (!(await requireAdmin(request))) {
    return Response.json({ error: "Unauthorized." }, { status: 401 });
  }
  return Response.json({ links: await getDownloadLinks() });
}

export async function POST(request: NextRequest) {
  if (!(await requireAdmin(request))) {
    return Response.json({ error: "Unauthorized." }, { status: 401 });
  }

  let formData: FormData;
  try {
    formData = await request.formData();
  } catch {
    return Response.json({ error: "Expected multipart form data." }, { status: 400 });
  }

  const platform = String(formData.get("platform") ?? "");
  if (!isDownloadPlatform(platform)) {
    return Response.json({ error: "Unknown platform." }, { status: 400 });
  }

  const version = String(formData.get("version") ?? "").trim().slice(0, 64);
  const file = formData.get("file");
  const url = String(formData.get("url") ?? "").trim();

  if (file instanceof File && file.size > 0) {
    if (file.size > MAX_DOWNLOAD_BYTES) {
      return Response.json({ error: "File is too large (max 300 MB)." }, { status: 413 });
    }
    const data = Buffer.from(await file.arrayBuffer());
    await setFileLink(
      platform,
      {
        data,
        fileName: file.name || `${platform}.bin`,
        contentType: file.type || "application/octet-stream",
      },
      version,
    );
    return Response.json({ ok: true, platform, kind: "file" }, { status: 201 });
  }

  if (url) {
    let parsed: URL;
    try {
      parsed = new URL(url);
    } catch {
      return Response.json({ error: "Invalid URL." }, { status: 400 });
    }
    if (parsed.protocol !== "https:" && parsed.protocol !== "http:") {
      return Response.json({ error: "URL must be http(s)." }, { status: 400 });
    }
    await setUrlLink(platform, url, version);
    return Response.json({ ok: true, platform, kind: "url" }, { status: 201 });
  }

  return Response.json({ error: "Provide a file or a URL." }, { status: 400 });
}
