import { SignJWT, jwtVerify } from "jose";
import type { NextRequest } from "next/server";

export const ADMIN_SESSION_COOKIE = "stillora_admin";
const ADMIN_SESSION_MAX_AGE = 60 * 60 * 8; // 8 hours

export type AdminSession = { email: string };

function getAdminKey() {
  const secret = process.env.AUTH_SECRET;
  if (!secret) throw new Error("AUTH_SECRET is not set.");
  return new TextEncoder().encode(`admin:${secret}`);
}

export function getAdminEmails(): Set<string> {
  return new Set(
    (process.env.ADMIN_EMAILS ?? "")
      .split(",")
      .map((e) => e.trim().toLowerCase())
      .filter(Boolean),
  );
}

export function isAdminEmail(email: string): boolean {
  return getAdminEmails().has(email.toLowerCase());
}

export async function verifyAdminPassword(password: string): Promise<boolean> {
  const stored = process.env.ADMIN_PASSWORD;
  if (!stored || !password) return false;
  return password === stored;
}

export async function encodeAdminSession(email: string): Promise<string> {
  return new SignJWT({ email })
    .setProtectedHeader({ alg: "HS256" })
    .setIssuedAt()
    .setExpirationTime("8h")
    .sign(getAdminKey());
}

export async function decodeAdminSession(
  token: string | undefined,
): Promise<AdminSession | null> {
  if (!token) return null;
  try {
    const { payload } = await jwtVerify(token, getAdminKey(), { algorithms: ["HS256"] });
    if (typeof payload.email !== "string") return null;
    if (!isAdminEmail(payload.email)) return null;
    return { email: payload.email };
  } catch {
    return null;
  }
}

/** Use in API route handlers (supports both cookie and Authorization: Admin <jwt>). */
export async function getAdminFromRequest(request: Request | NextRequest): Promise<AdminSession | null> {
  const header = request.headers.get("authorization");
  if (header?.startsWith("Admin ")) {
    const admin = await decodeAdminSession(header.slice("Admin ".length).trim());
    if (admin) return admin;
  }
  const token = (request as NextRequest).cookies?.get?.(ADMIN_SESSION_COOKIE)?.value;
  return decodeAdminSession(token);
}

/**
 * The origin the request arrived on, honouring the proxy headers a deployment
 * sits behind. Used to decide whether the admin session cookie can be marked
 * Secure — localhost is served over plain http.
 */
export function resolveBaseUrl(request: NextRequest) {
  const host = request.headers.get("x-forwarded-host") ?? request.headers.get("host") ?? "";
  const proto =
    request.headers.get("x-forwarded-proto") ??
    (host.startsWith("localhost") || host.startsWith("127.0.0.1") ? "http" : "https");
  return `${proto}://${host}`;
}

export function adminCookieOptions(secure: boolean) {
  return {
    httpOnly: true,
    secure,
    sameSite: "lax" as const,
    path: "/",
    maxAge: ADMIN_SESSION_MAX_AGE,
  };
}
