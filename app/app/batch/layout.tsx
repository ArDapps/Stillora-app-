import { requireWebAdmin } from "@/lib/web-access";

/** Admin-only on the web, like the editor and HTML → Video tools. */
export default async function BatchLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  await requireWebAdmin();
  return <>{children}</>;
}
