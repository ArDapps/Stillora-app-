import { getPublicDownloadLinks } from "@/lib/downloads-store";

import StilloraLanding from "./(marketing)/StilloraLanding";

// Revalidate periodically so admin-managed download links propagate to the
// landing page without making it fully dynamic on every request.
export const revalidate = 60;

export default async function Landing() {
  const links = await getPublicDownloadLinks();

  // The design's store strip is keyed by surface, not by our platform ids, and
  // macOS ships from the same universal App Store listing as iOS.
  return (
    <StilloraLanding
      stores={{
        ios: links.ios,
        mac: links.macos,
        android: links.android,
        windows: links.windows,
      }}
    />
  );
}
