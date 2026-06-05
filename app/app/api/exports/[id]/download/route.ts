import { readExport } from "@/lib/server-storage";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET(request: Request, context: RouteContext<"/api/exports/[id]/download">) {
  const { id } = await context.params;
  const day = new URL(request.url).searchParams.get("day");

  if (!day || !/^\d{4}-\d{2}-\d{2}$/.test(day) || !isUuid(id)) {
    return Response.json({ error: "Invalid download request." }, { status: 400 });
  }

  try {
    const exportFile = await readExport(day, id);

    if (!exportFile) {
      return Response.json({ error: "Export file was not found." }, { status: 404 });
    }

    return new Response(exportFile.body, {
      headers: {
        "Content-Disposition": `attachment; filename="stillora-${id}.mp4"`,
        "Content-Type": exportFile.contentType,
      },
    });
  } catch {
    return Response.json({ error: "Export file was not found." }, { status: 404 });
  }
}

function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
}
