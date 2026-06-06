import {
  encodeSession,
  fetchGoogleUser,
  fetchGoogleUserFromIdToken,
} from "@/lib/auth";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

/**
 * Native-client sign-in. The mobile app completes Google sign-in on-device and
 * posts a Google ID token, with access-token fallback for older clients. We
 * verify it with Google, then mint a Stillora session JWT the app stores and
 * sends as `Authorization: Bearer <token>`.
 */
export async function POST(request: Request) {
  let idToken: string | undefined;
  let accessToken: string | undefined;

  try {
    const body = (await request.json()) as {
      accessToken?: string;
      idToken?: string;
    };
    idToken = body.idToken;
    accessToken = body.accessToken;
  } catch {
    return Response.json({ error: "Invalid request body." }, { status: 400 });
  }

  if (!idToken && !accessToken) {
    return Response.json({ error: "idToken is required." }, { status: 400 });
  }

  try {
    const user = idToken
      ? await fetchGoogleUserFromIdToken(idToken)
      : await fetchGoogleUser(accessToken!);
    const token = await encodeSession(user);

    return Response.json({ token, user });
  } catch {
    return Response.json({ error: "Google sign-in failed." }, { status: 401 });
  }
}
