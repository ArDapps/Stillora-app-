import { getUserFromRequest } from "@/lib/auth";
import { recordStorePurchase, type ProSource } from "@/lib/pro-store";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

type RedeemBody = {
  source?: string;
  productId?: string;
  storeToken?: string;
  platform?: string;
};

const STORE_SOURCES = new Set(["apple", "google"]);

/**
 * Attaches a store purchase to the signed-in Stillora account.
 *
 * The app calls this whenever its own store says the unlock is owned — after a
 * purchase, and on any launch where a signed-in user has a store entitlement
 * the server does not know about yet. That repetition is deliberate: it is how
 * an account that bought before ever signing in gets caught up, so the write
 * below is idempotent.
 *
 * **The token is recorded, not verified.** Nothing here calls Apple or Google
 * yet, so a determined caller could claim a purchase they never made. That is a
 * deliberate trade for a $19.99 lifetime unlock: it ships without App Store
 * Connect / Play service-account credentials, and because the raw token is
 * stored, every claim can be verified retroactively once those exist.
 */
export async function POST(request: Request) {
  const user = await getUserFromRequest(request);
  if (!user) {
    return Response.json({ error: "Not signed in." }, { status: 401 });
  }

  let body: RedeemBody;
  try {
    body = (await request.json()) as RedeemBody;
  } catch {
    return Response.json({ error: "Invalid request body." }, { status: 400 });
  }

  const source = (body.source ?? "").toLowerCase();
  if (!STORE_SOURCES.has(source)) {
    return Response.json(
      { error: "source must be 'apple' or 'google'." },
      { status: 400 },
    );
  }

  try {
    const entitlement = await recordStorePurchase({
      userSub: user.sub,
      source: source as Exclude<ProSource, "admin">,
      productId: (body.productId ?? "").slice(0, 200),
      storeToken: (body.storeToken ?? "").slice(0, 8000),
      platform: (body.platform ?? "").slice(0, 40),
    });

    return Response.json({
      isPro: true,
      source: entitlement.source,
      grantedAt: entitlement.grantedAt,
    });
  } catch (error) {
    console.error("pro/redeem failed", error);
    return Response.json({ error: "Could not record purchase." }, { status: 500 });
  }
}
