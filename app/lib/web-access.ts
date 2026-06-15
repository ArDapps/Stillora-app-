import { redirect } from "next/navigation";
import { isAdminEmail } from "./admin";
import { getCurrentAdmin } from "./admin-server";
import { getCurrentUser } from "./auth";

/**
 * Web access gate for the creation tools. The native apps (iOS/iPad/Mac/Android)
 * are free for everyone, but on the web the editor and HTML → Video tools are
 * restricted to admins. Non-admins are sent to the landing page (which points
 * them to the free apps).
 *
 * "Admin" means either an authenticated admin-panel session, or a signed-in user
 * whose email is in ADMIN_EMAILS.
 */
export async function requireWebAdmin(): Promise<void> {
  const [admin, user] = await Promise.all([
    getCurrentAdmin(),
    getCurrentUser(),
  ]);

  const allowed =
    admin !== null || (user !== null && isAdminEmail(user.email));

  if (!allowed) redirect("/");
}
