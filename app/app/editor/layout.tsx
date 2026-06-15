import { requireWebAdmin } from "@/lib/web-access";

/**
 * The web editor is admin-only. Regular visitors are redirected to the landing
 * page; the editing tools are free in the mobile/desktop apps.
 */
export default async function EditorLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  await requireWebAdmin();
  return <>{children}</>;
}
