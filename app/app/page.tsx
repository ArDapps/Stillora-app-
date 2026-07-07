import { LandingHome } from "@/app/components/landing-home";
import { getPublicDownloadLinks } from "@/lib/downloads-store";

// Revalidate periodically so admin-managed download links propagate to the
// landing page without making it fully dynamic on every request.
export const revalidate = 60;

export default async function Landing() {
  const links = await getPublicDownloadLinks();
  return <LandingHome links={links} />;
}
