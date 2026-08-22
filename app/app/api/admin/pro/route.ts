import { getAdminFromRequest } from "@/lib/admin";
import { adminGrantPro, adminRevokePro } from "@/lib/pro-store";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

type AdminProBody = {
  action?: string;
  userSub?: string;
  note?: string;
};

/**
 * Grant or take back a comped lifetime Pro.
 *
 * Revoke only ever touches an admin grant — see `adminRevokePro`. A real store
 * purchase cannot be cancelled from here, because the buyer's device would hear
 * "owned" from Apple/Google on its next launch and re-grant itself; refunds go
 * through the store.
 */
export async function POST(request: Request) {
  const admin = await getAdminFromRequest(request);
  if (!admin) {
    return Response.json({ error: "Not authorized." }, { status: 401 });
  }

  let body: AdminProBody;
  try {
    body = (await request.json()) as AdminProBody;
  } catch {
    return Response.json({ error: "Invalid request body." }, { status: 400 });
  }

  const userSub = (body.userSub ?? "").trim();
  if (!userSub) {
    return Response.json({ error: "userSub is required." }, { status: 400 });
  }

  try {
    if (body.action === "grant") {
      const entitlement = await adminGrantPro({
        userSub,
        adminEmail: admin.email,
        note: (body.note ?? "").slice(0, 500),
      });
      return Response.json({ ok: true, entitlement });
    }

    if (body.action === "revoke") {
      const revoked = await adminRevokePro({ userSub, adminEmail: admin.email });
      return Response.json({
        ok: revoked,
        // Distinguishes "nothing to revoke" from "refused because it is a real
        // purchase" for the panel's benefit.
        error: revoked
          ? undefined
          : "Nothing revocable — only admin-granted Pro can be taken back here.",
      });
    }

    return Response.json(
      { error: "action must be 'grant' or 'revoke'." },
      { status: 400 },
    );
  } catch (error) {
    console.error("admin/pro failed", error);
    return Response.json({ error: "Request failed." }, { status: 500 });
  }
}
