import { readFile } from "node:fs/promises";
import path from "node:path";

import { EXPORTS_ROOT } from "@/lib/server-storage";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET(request: Request, context: RouteContext<"/api/exports/[id]/download">) {
  const { id } = await context.params;
  const day = new URL(request.url).searchParams.get("day");

  if (!day || !/^\d{4}-\d{2}-\d{2}$/.test(day) || !isUuid(id)) {
    return Response.json({ error: "Invalid download request." }, { status: 400 });
  }

  try {
    const filePath = path.join(EXPORTS_ROOT, day, `${id}.mp4`);
    const file = await readFile(filePath);

    return new Response(file, {
      headers: {
        "Content-Disposition": `attachment; filename="stillora-${id}.mp4"`,
        "Content-Type": "video/mp4",
      },
    });
  } catch {
    return Response.json({ error: "Export file was not found." }, { status: 404 });
  }
}

function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
}
