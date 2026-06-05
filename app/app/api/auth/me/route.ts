import { getUserFromRequest } from "@/lib/auth";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

// Serves both web (session cookie) and mobile (Authorization: Bearer <jwt>) clients,
// so the same user resolves identically whichever app they open.
export async function GET(request: Request) {
  const user = await getUserFromRequest(request);
  return Response.json({ user });
}
