import { encodeSession, fetchGoogleUser } from "@/lib/auth";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

/**
 * Native-client sign-in. The mobile app completes Google OAuth on-device and posts the
 * resulting Google access token here; we verify it with Google, then mint a Stillora
 * session JWT the app stores and sends as `Authorization: Bearer <token>`.
 */
export async function POST(request: Request) {
  let accessToken: string | undefined;

  try {
    const body = (await request.json()) as { accessToken?: string };
    accessToken = body.accessToken;
  } catch {
    return Response.json({ error: "Invalid request body." }, { status: 400 });
  }

  if (!accessToken) {
    return Response.json({ error: "accessToken is required." }, { status: 400 });
  }

  try {
    const user = await fetchGoogleUser(accessToken);
    const token = await encodeSession(user);

    return Response.json({ token, user });
  } catch {
    return Response.json({ error: "Google sign-in failed." }, { status: 401 });
  }
}
