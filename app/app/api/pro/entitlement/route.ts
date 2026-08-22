import { getUserFromRequest } from "@/lib/auth";
import { getEntitlement } from "@/lib/pro-store";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

/**
 * What Pro this signed-in Stillora account owns.
 *
 * This is what lets the unlock cross platforms: Linux and Windows have no store
 * at all, and a buyer who owns Pro on their iPhone gets nothing from Google on
 * their Android tablet. The account is the one identity that spans all of them.
 *
 * Answers only for the caller's own account — the session decides whose
 * entitlement is read, never a parameter.
 */
export async function GET(request: Request) {
  const user = await getUserFromRequest(request);
  if (!user) {
    return Response.json({ error: "Not signed in." }, { status: 401 });
  }

  try {
    const entitlement = await getEntitlement(user.sub);
    const active = Boolean(entitlement && !entitlement.revokedAt);

    return Response.json({
      isPro: active,
      source: active ? entitlement!.source : null,
      grantedAt: active ? entitlement!.grantedAt : null,
      // Present and true only when a comp was explicitly taken back. The app
      // uses this to distinguish "never had Pro" from "had it, admin removed
      // it" — the one case where a client is allowed to turn Pro off.
      revoked: Boolean(entitlement?.revokedAt),
    });
  } catch (error) {
    console.error("pro/entitlement failed", error);
    // A 500 must never read as "not Pro": the app treats any non-200 as
    // "unknown" and keeps whatever entitlement it already had.
    return Response.json({ error: "Lookup failed." }, { status: 500 });
  }
}
