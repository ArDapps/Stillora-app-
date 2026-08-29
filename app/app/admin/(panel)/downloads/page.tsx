import { DOWNLOAD_LABELS, DOWNLOAD_PLATFORMS } from "@/lib/downloads";
import { getDownloadLinks } from "@/lib/downloads-store";
import { PageHeader } from "../ui";
import { DownloadsManager, type PlatformState } from "./downloads-manager";

export const dynamic = "force-dynamic";

export default async function AdminDownloadsPage() {
  const rows = await getDownloadLinks();
  const byPlatform = new Map(rows.map((r) => [r.platform, r]));

  const platforms: PlatformState[] = DOWNLOAD_PLATFORMS.map((platform) => {
    const row = byPlatform.get(platform);
    return {
      platform,
      label: DOWNLOAD_LABELS[platform],
      kind: row?.kind ?? null,
      externalUrl: row?.externalUrl ?? "",
      fileName: row?.fileName ?? "",
      sizeBytes: row?.sizeBytes ?? 0,
      version: row?.version ?? "",
      updatedAt: row?.updatedAt ?? "",
    };
  });

  return (
    <>
      <PageHeader
        title="Downloads"
        subtitle="Upload a build or paste a link for each platform. These power the download buttons on the landing page; unset platforms use the shipped defaults."
      />
      <DownloadsManager platforms={platforms} />
    </>
  );
}
