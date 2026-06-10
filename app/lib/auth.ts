import { SignJWT, jwtVerify, createRemoteJWKSet } from "jose";
import { createHash } from "node:crypto";
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
const GOOGLE_TOKENINFO_URL = "https://oauth2.googleapis.com/tokeninfo";
const GOOGLE_USERINFO_URL = "https://openidconnect.googleapis.com/v1/userinfo";
const FALLBACK_GOOGLE_CLIENT_IDS = [
  "718272031198-jcl994t1b9ucib32k08hb3rc5v29ngur.apps.googleusercontent.com",
  "718272031198-kr3vqn6j3cchpo0vqp7usajm3734ignb.apps.googleusercontent.com",
];

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

function getAllowedGoogleClientIds() {
  return new Set(
    [
      process.env.GOOGLE_CLIENT_ID,
      process.env.GOOGLE_WEB_CLIENT_ID,
      process.env.GOOGLE_IOS_CLIENT_ID,
      process.env.GOOGLE_MACOS_CLIENT_ID,
      process.env.GOOGLE_ANDROID_CLIENT_ID,
      process.env.GOOGLE_NATIVE_CLIENT_IDS,
      ...FALLBACK_GOOGLE_CLIENT_IDS,
    ]
      .flatMap((value) => value?.split(",") ?? [])
      .map((value) => value.trim())
      .filter(Boolean),
  );
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

export async function fetchGoogleUserFromIdToken(
  idToken: string,
): Promise<SessionUser> {
  const response = await fetch(
    `${GOOGLE_TOKENINFO_URL}?id_token=${encodeURIComponent(idToken)}`,
    {
      cache: "no-store",
    },
  );

  if (!response.ok) {
    throw new Error(`Failed to verify Google ID token (${response.status}).`);
  }

  const profile = (await response.json()) as {
    aud?: string;
    iss?: string;
    sub?: string;
    email?: string;
    name?: string;
    picture?: string;
  };

  const validIssuer =
    profile.iss === "accounts.google.com" ||
    profile.iss === "https://accounts.google.com";
  if (!validIssuer) {
    throw new Error("Google ID token issuer is not valid.");
  }

  if (!profile.aud || !getAllowedGoogleClientIds().has(profile.aud)) {
    throw new Error("Google ID token audience is not allowed.");
  }

  if (!profile.sub) {
    throw new Error("Google ID token subject is missing.");
  }

  return {
    sub: profile.sub,
    email: profile.email ?? "",
    name: profile.name ?? profile.email ?? "Stillora user",
    picture: profile.picture ?? "",
  };
}

// --- Sign in with Apple ---

const APPLE_ISSUER = "https://appleid.apple.com";
const APPLE_JWKS = createRemoteJWKSet(
  new URL("https://appleid.apple.com/auth/keys"),
);

function getAllowedAppleClientIds() {
  return new Set(
    [
      process.env.APPLE_CLIENT_ID,
      process.env.APPLE_BUNDLE_ID,
      process.env.APPLE_SERVICE_ID,
      process.env.APPLE_NATIVE_CLIENT_IDS,
      // Fallback to the shipped iOS bundle id / Android service id.
      "app.loopara.stillora",
      "app.loopara.stillora.signin",
    ]
      .flatMap((value) => value?.split(",") ?? [])
      .map((value) => value.trim())
      .filter(Boolean),
  );
}

export type AppleVerifyInput = {
  idToken: string;
  rawNonce?: string;
  /** Apple only returns these on first authorization; the client supplies them. */
  name?: string;
  email?: string;
};

export type AppleVerifyResult = {
  user: SessionUser;
  /** Whether Apple reports the email as verified — gates account linking. */
  emailVerified: boolean;
};

/**
 * Verifies an Apple identity token against Apple's public keys, checking the
 * issuer, audience, and (when supplied) the replay-protection nonce. Apple's
 * token never carries the user's name, so the client-provided name/email are
 * merged in. Returns the resolved user plus whether the email is verified.
 */
export async function verifyAppleIdToken({
  idToken,
  rawNonce,
  name,
  email,
}: AppleVerifyInput): Promise<AppleVerifyResult> {
  const { payload } = await jwtVerify(idToken, APPLE_JWKS, {
    issuer: APPLE_ISSUER,
  });

  const aud = payload.aud;
  const audValues = Array.isArray(aud) ? aud : [aud];
  const allowed = getAllowedAppleClientIds();
  if (
    !audValues.some((value) => typeof value === "string" && allowed.has(value))
  ) {
    throw new Error("Apple identity token audience is not allowed.");
  }

  if (rawNonce) {
    const expected = createHash("sha256").update(rawNonce).digest("hex");
    if (typeof payload.nonce !== "string" || payload.nonce !== expected) {
      throw new Error("Apple identity token nonce mismatch.");
    }
  }

  const sub = typeof payload.sub === "string" ? payload.sub : "";
  if (!sub) {
    throw new Error("Apple identity token subject is missing.");
  }

  const tokenEmail =
    typeof payload.email === "string" ? payload.email : undefined;
  const resolvedEmail = (tokenEmail ?? email ?? "").trim();
  // Apple sends email_verified as a boolean or the string "true".
  const verifiedClaim = payload.email_verified;
  const emailVerified = verifiedClaim === true || verifiedClaim === "true";

  const resolvedName = (name ?? "").trim() || resolvedEmail || "Stillora user";

  return {
    user: {
      // Namespace Apple subjects so they never collide with Google `sub`s.
      sub: `apple:${sub}`,
      email: resolvedEmail,
      name: resolvedName,
      picture: "",
    },
    emailVerified: Boolean(resolvedEmail) && emailVerified,
  };
}
