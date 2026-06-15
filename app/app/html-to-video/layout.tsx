import { requireWebAdmin } from "@/lib/web-access";

export const metadata = { title: "HTML → Video — Stillora" };

/** Admin-only on the web, like the editor. */
export default async function HtmlToVideoLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  await requireWebAdmin();
  return <>{children}</>;
}
