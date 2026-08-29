import { getAdminFromRequest } from "@/lib/admin";
import {
  deleteErrorById,
  deleteResolvedErrors,
  reopenErrorById,
  resolveErrorById,
} from "@/lib/error-log";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

/**
 * Triage actions for the admin Errors page: resolve one, reopen one, delete
 * one, or clear everything already resolved.
 *
 * Resolving is a judgement, not a fix — the next occurrence of the same
 * fingerprint reopens the row automatically (see `logError`), so marking
 * something done can never hide a bug that is still happening.
 */
export async function POST(request: Request) {
  const admin = await getAdminFromRequest(request);
  if (!admin) {
    return Response.json({ error: "Unauthorized." }, { status: 401 });
  }

  let body: { action?: unknown; id?: unknown };
  try {
    body = (await request.json()) as typeof body;
  } catch {
    return Response.json({ error: "Invalid request." }, { status: 400 });
  }

  const action = typeof body.action === "string" ? body.action : "";
  const id = typeof body.id === "string" ? body.id : "";

  try {
    if (action === "clear-resolved") {
      const removed = await deleteResolvedErrors();
      return Response.json({ ok: true, removed });
    }

    if (!id) {
      return Response.json({ error: "id is required." }, { status: 400 });
    }

    switch (action) {
      case "resolve":
        await resolveErrorById(id);
        break;
      case "reopen":
        await reopenErrorById(id);
        break;
      case "delete":
        await deleteErrorById(id);
        break;
      default:
        return Response.json({ error: "Unknown action." }, { status: 400 });
    }

    return Response.json({ ok: true });
  } catch (error) {
    // Logging a failure of the error tool itself would be circular, so this one
    // stays on the console.
    console.error("admin/errors action failed:", error);
    return Response.json({ error: "Action failed." }, { status: 500 });
  }
}
