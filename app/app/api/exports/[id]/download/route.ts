export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET(request: Request, context: RouteContext<"/api/exports/[id]/download">) {
  const { id } = await context.params;
  const day = new URL(request.url).searchParams.get("day");

  if (!day || !/^\d{4}-\d{2}-\d{2}$/.test(day) || !isUuid(id)) {
    return Response.json({ error: "Invalid download request." }, { status: 400 });
  }

  return Response.json(
    { error: "Exports are processed temporarily and are not saved on the server." },
    { status: 410 },
  );
}

function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
}
