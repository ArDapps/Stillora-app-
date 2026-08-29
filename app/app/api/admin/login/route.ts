import { NextResponse, type NextRequest } from "next/server";
import {
  ADMIN_SESSION_COOKIE,
  adminCookieOptions,
  encodeAdminSession,
  isAdminEmail,
  resolveBaseUrl,
  verifyAdminPassword,
} from "@/lib/admin";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function POST(request: NextRequest) {
  let body: { email?: string; password?: string };
  try {
    body = (await request.json()) as { email?: string; password?: string };
  } catch {
    return Response.json({ error: "Invalid request." }, { status: 400 });
  }

  const { email, password } = body;

  if (
    typeof email !== "string" ||
    typeof password !== "string" ||
    !isAdminEmail(email) ||
    !(await verifyAdminPassword(password))
  ) {
    return Response.json({ error: "Invalid credentials." }, { status: 401 });
  }

  const token = await encodeAdminSession(email);
  const base = resolveBaseUrl(request);
  const secure = base.startsWith("https");

  const response = NextResponse.json({ ok: true });
  response.cookies.set(ADMIN_SESSION_COOKIE, token, adminCookieOptions(secure));
  return response;
}
