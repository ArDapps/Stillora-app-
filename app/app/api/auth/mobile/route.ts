import {
  encodeSession,
  fetchGoogleUser,
  fetchGoogleUserFromIdToken,
  verifyAppleIdToken,
} from "@/lib/auth";
import { findUserSubByEmail, recordUserLogin } from "@/lib/admin-store";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

type MobileBody = {
  provider?: string;
  // Google
  accessToken?: string;
  idToken?: string;
  // Apple
  appleIdToken?: string;
  rawNonce?: string;
  name?: string;
  email?: string;
};

/**
 * Native-client sign-in for Google and Apple. The mobile app completes the
 * provider flow on-device and posts the resulting token; we verify it, then mint
 * a Stillora session JWT the app stores and sends as `Authorization: Bearer`.
 */
export async function POST(request: Request) {
  let body: MobileBody;
  try {
    body = (await request.json()) as MobileBody;
  } catch {
    return Response.json({ error: "Invalid request body." }, { status: 400 });
  }

  if (body.provider === "apple" || body.appleIdToken) {
    return handleApple(body);
  }
  return handleGoogle(body);
}

async function handleGoogle(body: MobileBody) {
  const { idToken, accessToken } = body;
  if (!idToken && !accessToken) {
    return Response.json({ error: "idToken is required." }, { status: 400 });
  }

  try {
    const user = idToken
      ? await fetchGoogleUserFromIdToken(idToken)
      : await fetchGoogleUser(accessToken!);
    const token = await encodeSession(user);

    // Surface native sign-ins in the admin dashboard. Fire-and-forget.
    void recordUserLogin(user);

    return Response.json({ token, user });
  } catch {
    return Response.json({ error: "Google sign-in failed." }, { status: 401 });
  }
}

async function handleApple(body: MobileBody) {
  if (!body.appleIdToken) {
    return Response.json(
      { error: "appleIdToken is required." },
      { status: 400 },
    );
  }

  try {
    const { user, emailVerified } = await verifyAppleIdToken({
      idToken: body.appleIdToken,
      rawNonce: body.rawNonce,
      name: body.name,
      email: body.email,
    });

    // Securely link to an existing account only when Apple verified the email:
    // reuse the canonical sub so Apple and Google resolve to the same user.
    let linked = user;
    if (emailVerified && user.email) {
      const existingSub = await findUserSubByEmail(user.email);
      if (existingSub && existingSub !== user.sub) {
        linked = { ...user, sub: existingSub };
      }
    }

    const token = await encodeSession(linked);
    void recordUserLogin(linked);

    return Response.json({ token, user: linked });
  } catch {
    return Response.json(
      { error: "Sign in with Apple failed." },
      { status: 401 },
    );
  }
}
