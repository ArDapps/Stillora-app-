import { NextResponse, type NextRequest } from "next/server";

import {
  OAUTH_REDIRECT_COOKIE,
  OAUTH_STATE_COOKIE,
  SESSION_COOKIE,
  encodeSession,
  exchangeGoogleCode,
  fetchGoogleUser,
  resolveBaseUrl,
  sessionCookieOptions,
} from "@/lib/auth";
import { recordUserLogin } from "@/lib/admin-store";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const base = resolveBaseUrl(request);
  const params = request.nextUrl.searchParams;

  const cookieState = request.cookies.get(OAUTH_STATE_COOKIE)?.value;
  const callbackUrl = request.cookies.get(OAUTH_REDIRECT_COOKIE)?.value ?? "/editor";

  const fail = (reason: string) => {
    const target = new URL(callbackUrl, base);
    target.searchParams.set("auth_error", reason);
    const response = NextResponse.redirect(target);
    response.cookies.delete(OAUTH_STATE_COOKIE);
    response.cookies.delete(OAUTH_REDIRECT_COOKIE);
    return response;
  };

  if (params.get("error")) {
    return fail(params.get("error") ?? "access_denied");
  }

  const code = params.get("code");
  const state = params.get("state");

  if (!code || !state || !cookieState || state !== cookieState) {
    return fail("invalid_state");
  }

  try {
    const redirectUri = `${base}/api/auth/callback/google`;
    const tokens = await exchangeGoogleCode(code, redirectUri);
    const user = await fetchGoogleUser(tokens.access_token);
    void recordUserLogin(user);
    const session = await encodeSession(user);

    const response = NextResponse.redirect(new URL(callbackUrl, base));
    const secure = base.startsWith("https");

    response.cookies.set(SESSION_COOKIE, session, sessionCookieOptions(secure));
    response.cookies.delete(OAUTH_STATE_COOKIE);
    response.cookies.delete(OAUTH_REDIRECT_COOKIE);

    return response;
  } catch {
    return fail("auth_failed");
  }
}
