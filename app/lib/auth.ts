import { SignJWT, jwtVerify } from "jose";
import type { NextRequest } from "next/server";
import { cookies } from "next/headers";

export type SessionUser = {
  sub: string;
  email: string;
  name: string;
  picture: string;
};

export const SESSION_COOKIE = "stillora_session";
export const OAUTH_STATE_COOKIE = "stillora_oauth_state";
export const OAUTH_REDIRECT_COOKIE = "stillora_oauth_redirect";

const SESSION_MAX_AGE = 60 * 60 * 24 * 7; // 7 days
const OAUTH_TX_MAX_AGE = 60 * 10; // 10 minutes

const GOOGLE_AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth";
const GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token";
const GOOGLE_USERINFO_URL = "https://openidconnect.googleapis.com/v1/userinfo";

function getSessionKey() {
  const secret = process.env.AUTH_SECRET;
  if (!secret) {
    throw new Error("AUTH_SECRET is not set. Add it to your .env.local file.");
  }
  return new TextEncoder().encode(secret);
}

function getGoogleCredentials() {
  const clientId = process.env.GOOGLE_CLIENT_ID;
  const clientSecret = process.env.GOOGLE_CLIENT_SECRET;
  if (!clientId || !clientSecret) {
    throw new Error(
      "GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET are not set. Add them to your .env.local file.",
    );
  }
  return { clientId, clientSecret };
}

// --- Session (stateless JWT in an httpOnly cookie) ---

export async function encodeSession(user: SessionUser) {
  return new SignJWT({ email: user.email, name: user.name, picture: user.picture })
    .setProtectedHeader({ alg: "HS256" })
    .setSubject(user.sub)
    .setIssuedAt()
    .setExpirationTime("7d")
    .sign(getSessionKey());
}

export async function decodeSession(token: string | undefined): Promise<SessionUser | null> {
  if (!token) {
    return null;
  }

  try {
    const { payload } = await jwtVerify(token, getSessionKey(), { algorithms: ["HS256"] });

    if (typeof payload.sub !== "string") {
      return null;
    }

    return {
      sub: payload.sub,
      email: typeof payload.email === "string" ? payload.email : "",
      name: typeof payload.name === "string" ? payload.name : "",
      picture: typeof payload.picture === "string" ? payload.picture : "",
    };
  } catch {
    return null;
  }
}

/** Reads and verifies the session from the request cookies. Use in pages, route handlers, and actions. */
export async function getCurrentUser(): Promise<SessionUser | null> {
  const token = (await cookies()).get(SESSION_COOKIE)?.value;
  return decodeSession(token);
}

/**
 * Resolves the user from either an `Authorization: Bearer <jwt>` header (mobile/native
 * clients) or the session cookie (web). Use this in route handlers that serve both.
 */
export async function getUserFromRequest(request: Request): Promise<SessionUser | null> {
  const header = request.headers.get("authorization");

  if (header?.startsWith("Bearer ")) {
    const user = await decodeSession(header.slice("Bearer ".length).trim());
    if (user) {
      return user;
    }
  }

  return getCurrentUser();
}

export function sessionCookieOptions(secure: boolean) {
  return {
    httpOnly: true,
    secure,
    sameSite: "lax" as const,
    path: "/",
    maxAge: SESSION_MAX_AGE,
  };
}

export function oauthCookieOptions(secure: boolean) {
  return {
    httpOnly: true,
    secure,
    sameSite: "lax" as const,
    path: "/",
    maxAge: OAUTH_TX_MAX_AGE,
  };
}

// --- Base URL resolution (works on localhost and behind Vercel's proxy) ---

export function resolveBaseUrl(request: NextRequest) {
  const host = request.headers.get("x-forwarded-host") ?? request.headers.get("host") ?? "";
  const proto =
    request.headers.get("x-forwarded-proto") ??
    (host.startsWith("localhost") || host.startsWith("127.0.0.1") ? "http" : "https");
  return `${proto}://${host}`;
}

// --- Google OAuth (Authorization Code flow) ---

export function buildGoogleAuthUrl(redirectUri: string, state: string) {
  const { clientId } = getGoogleCredentials();
  const params = new URLSearchParams({
    client_id: clientId,
    redirect_uri: redirectUri,
    response_type: "code",
    scope: "openid email profile",
    state,
    access_type: "online",
    prompt: "select_account",
  });
  return `${GOOGLE_AUTH_URL}?${params.toString()}`;
}

export async function exchangeGoogleCode(code: string, redirectUri: string) {
  const { clientId, clientSecret } = getGoogleCredentials();
  const response = await fetch(GOOGLE_TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      code,
      client_id: clientId,
      client_secret: clientSecret,
      redirect_uri: redirectUri,
      grant_type: "authorization_code",
    }),
  });

  if (!response.ok) {
    throw new Error(`Google token exchange failed (${response.status}).`);
  }

  return (await response.json()) as { access_token: string; id_token?: string };
}

export async function fetchGoogleUser(accessToken: string): Promise<SessionUser> {
  const response = await fetch(GOOGLE_USERINFO_URL, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (!response.ok) {
    throw new Error(`Failed to load Google profile (${response.status}).`);
  }

  const profile = (await response.json()) as {
    sub: string;
    email?: string;
    name?: string;
    picture?: string;
  };

  return {
    sub: profile.sub,
    email: profile.email ?? "",
    name: profile.name ?? profile.email ?? "Stillora user",
    picture: profile.picture ?? "",
  };
}
