/**
 * Next.js instrumentation hook.
 *
 * `onRequestError` fires for every uncaught server-side error — API routes,
 * server components, SSR — which is why the app's routes do not each need their
 * own try/catch to be visible in the admin panel. Whatever throws anywhere on
 * the server ends up on /admin/errors, tagged with the route that produced it.
 */
export async function onRequestError(
  error: unknown,
  request: { path: string; method: string; headers: Record<string, string | undefined> },
  context: { routePath?: string; routeType?: string },
) {
  // Imported lazily: instrumentation is evaluated in every runtime, and the
  // error store speaks to Postgres, which only exists on Node.
  const { logError } = await import("./lib/error-log");

  await logError({
    source: `${request.method} ${context.routePath || request.path}`,
    error,
    scope: "server",
    url: request.path,
    platform: request.headers["x-stillora-platform"] ?? "",
    appVersion: request.headers["x-stillora-version"] ?? "",
    deviceId: request.headers["x-stillora-device"] ?? "",
    userAgent: request.headers["user-agent"] ?? "",
  });
}
