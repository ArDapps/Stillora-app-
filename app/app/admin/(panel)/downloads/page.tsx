import { DOWNLOAD_LABELS, DOWNLOAD_PLATFORMS } from "@/lib/downloads";
import { getDownloadLinks } from "@/lib/downloads-store";
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
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold" style={{ color: "var(--color-foreground)" }}>
          Downloads
        </h1>
        <p className="mt-1 text-sm" style={{ color: "var(--color-muted)" }}>
          Upload a build or paste a link for each platform. These power the download
          buttons on the landing page. Unset platforms use the shipped defaults.
        </p>
      </div>

      <DownloadsManager platforms={platforms} />
    </div>
  );
}
