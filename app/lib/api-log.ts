import { logError } from "./error-log";

/**
 * Wraps a route handler so anything it throws lands on the admin Errors page
 * instead of vanishing into the platform log.
 *
 * The client still gets a generic 500 — the stack stays server-side — and the
 * request's own platform/version headers are attached so a failure can be
 * traced back to the app that triggered it.
 *
 * Usage: `export const POST = withErrorLog("api/convert/html", handler);`
 */
export function withErrorLog<Args extends unknown[]>(
  source: string,
  handler: (request: Request, ...args: Args) => Promise<Response> | Response,
): (request: Request, ...args: Args) => Promise<Response> {
  return async (request: Request, ...args: Args) => {
    try {
      return await handler(request, ...args);
    } catch (error) {
      await logError({
        source,
        error,
        scope: "server",
        url: safeUrl(request),
        platform: request.headers.get("x-stillora-platform") ?? "",
        appVersion: request.headers.get("x-stillora-version") ?? "",
        deviceId: request.headers.get("x-stillora-device") ?? "",
        userAgent: request.headers.get("user-agent") ?? "",
      });
      return Response.json({ error: "Something went wrong." }, { status: 500 });
    }
  };
}

function safeUrl(request: Request): string {
  try {
    const url = new URL(request.url);
    return `${url.pathname}${url.search}`;
  } catch {
    return "";
  }
}
