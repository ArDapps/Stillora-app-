import { cookies } from "next/headers";
import { ADMIN_SESSION_COOKIE, decodeAdminSession } from "./admin";
import type { AdminSession } from "./admin";

export type { AdminSession };

/** Use in server components and server actions (reads cookie store). */
export async function getCurrentAdmin(): Promise<AdminSession | null> {
  const token = (await cookies()).get(ADMIN_SESSION_COOKIE)?.value;
  return decodeAdminSession(token);
}
