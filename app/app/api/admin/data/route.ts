import { type NextRequest } from "next/server";
import { getAdminFromRequest, isAdminEmail } from "@/lib/admin";
import { getCurrentUser } from "@/lib/auth";
import { getStats, getUsers, getRecentExports } from "@/lib/admin-store";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const [adminSession, userSession] = await Promise.all([
    getAdminFromRequest(request),
    getCurrentUser(),
  ]);

  const isAllowed =
    adminSession !== null ||
    (userSession !== null && isAdminEmail(userSession.email));

  if (!isAllowed) {
    return Response.json({ error: "Unauthorized." }, { status: 401 });
  }

  const [stats, users, exports] = await Promise.all([
    getStats(),
    getUsers(),
    getRecentExports(100),
  ]);

  return Response.json({ stats, users, exports });
}
