import { type NextRequest } from "next/server";
import { getAdminFromRequest } from "@/lib/admin";
import { isDownloadPlatform } from "@/lib/downloads";
import { deleteDownloadLink } from "@/lib/downloads-store";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function DELETE(
  request: NextRequest,
  context: { params: Promise<{ platform: string }> },
) {
  if ((await getAdminFromRequest(request)) === null) {
    return Response.json({ error: "Unauthorized." }, { status: 401 });
  }

  const { platform } = await context.params;
  if (!isDownloadPlatform(platform)) {
    return Response.json({ error: "Unknown platform." }, { status: 400 });
  }

  await deleteDownloadLink(platform);
  return Response.json({ ok: true, platform });
}
