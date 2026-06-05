import { NextResponse, type NextRequest } from "next/server";

import {
  OAUTH_REDIRECT_COOKIE,
  OAUTH_STATE_COOKIE,
  buildGoogleAuthUrl,
  oauthCookieOptions,
  resolveBaseUrl,
} from "@/lib/auth";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const base = resolveBaseUrl(request);
  const redirectUri = `${base}/api/auth/callback/google`;

  const requested = request.nextUrl.searchParams.get("callbackUrl");
  // Only allow same-site relative paths to avoid open-redirects.
  const callbackUrl = requested && requested.startsWith("/") ? requested : "/editor";

  const state = crypto.randomUUID();
  const secure = base.startsWith("https");

  let authUrl: string;
  try {
    authUrl = buildGoogleAuthUrl(redirectUri, state);
  } catch {
    // Credentials not configured yet — send the user back with a readable error.
    const target = new URL(callbackUrl, base);
    target.searchParams.set("auth_error", "not_configured");
    return NextResponse.redirect(target);
  }

  const response = NextResponse.redirect(authUrl);
  response.cookies.set(OAUTH_STATE_COOKIE, state, oauthCookieOptions(secure));
  response.cookies.set(OAUTH_REDIRECT_COOKIE, callbackUrl, oauthCookieOptions(secure));

  return response;
}
