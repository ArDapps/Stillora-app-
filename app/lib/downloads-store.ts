import { promises as fs } from "node:fs";
import { logError } from "./error-log";
import path from "node:path";
import { query } from "./db";
import {
  DEFAULT_DOWNLOAD_LINKS,
  DOWNLOAD_PLATFORMS,
  downloadsDir,
  type DownloadLinks,
  type DownloadPlatform,
} from "./downloads";

export type DownloadLinkRecord = {
  platform: DownloadPlatform;
  kind: "file" | "url";
  externalUrl: string;
  fileName: string;
  filePath: string;
  contentType: string;
  sizeBytes: number;
  version: string;
  updatedAt: string;
};

type DownloadRow = {
  platform: string;
  kind: string;
  external_url: string;
  file_name: string;
  file_path: string;
  content_type: string;
  size_bytes: string | number;
  version: string;
  updated_at: Date | string;
};

function toIso(value: Date | string): string {
  return value instanceof Date ? value.toISOString() : new Date(value).toISOString();
}

function mapRow(row: DownloadRow): DownloadLinkRecord {
  return {
    platform: row.platform as DownloadPlatform,
    kind: row.kind === "file" ? "file" : "url",
    externalUrl: row.external_url,
    fileName: row.file_name,
    filePath: row.file_path,
    contentType: row.content_type,
    sizeBytes: Number(row.size_bytes) || 0,
    version: row.version,
    updatedAt: toIso(row.updated_at),
  };
}

/** All configured download rows, keyed for easy lookup by platform. */
export async function getDownloadLinks(): Promise<DownloadLinkRecord[]> {
  try {
    const rows = await query<DownloadRow>(
      `SELECT platform, kind, external_url, file_name, file_path,
              content_type, size_bytes, version, updated_at
       FROM download_links`,
    );
    return rows.map(mapRow);
  } catch (error) {
    void logError({ source: "downloads-store/getDownloadLinks", error });
    return [];
  }
}

export async function getDownloadLink(
  platform: DownloadPlatform,
): Promise<DownloadLinkRecord | null> {
  try {
    const rows = await query<DownloadRow>(
      `SELECT platform, kind, external_url, file_name, file_path,
              content_type, size_bytes, version, updated_at
       FROM download_links WHERE platform = $1`,
      [platform],
    );
    return rows[0] ? mapRow(rows[0]) : null;
  } catch (error) {
    void logError({ source: "downloads-store/getDownloadLink", error });
    return null;
  }
}

/**
 * Public URLs for the landing buttons: an external link, our own
 * `/download/<platform>` route when a binary is stored, or the shipped default.
 */
export async function getPublicDownloadLinks(): Promise<DownloadLinks> {
  const links: DownloadLinks = { ...DEFAULT_DOWNLOAD_LINKS };
  const rows = await getDownloadLinks();
  for (const row of rows) {
    if (row.kind === "url" && row.externalUrl) {
      links[row.platform] = row.externalUrl;
    } else if (row.kind === "file" && row.filePath) {
      // Cache-bust so a re-upload is picked up immediately.
      links[row.platform] = `/download/${row.platform}?v=${Date.parse(row.updatedAt) || 0}`;
    }
  }
  return links;
}

/** Points a platform at an external link, removing any previously stored file. */
export async function setUrlLink(
  platform: DownloadPlatform,
  externalUrl: string,
  version: string,
): Promise<void> {
  await removeStoredFile(platform);
  await query(
    `INSERT INTO download_links
       (platform, kind, external_url, file_name, file_path, content_type, size_bytes, version, updated_at)
     VALUES ($1, 'url', $2, '', '', '', 0, $3, now())
     ON CONFLICT (platform) DO UPDATE
       SET kind = 'url', external_url = EXCLUDED.external_url,
           file_name = '', file_path = '', content_type = '', size_bytes = 0,
           version = EXCLUDED.version, updated_at = now()`,
    [platform, externalUrl, version],
  );
}

/** Persists an uploaded binary to disk and records it for the platform. */
export async function setFileLink(
  platform: DownloadPlatform,
  file: { data: Buffer; fileName: string; contentType: string },
  version: string,
): Promise<void> {
  const dir = downloadsDir();
  await fs.mkdir(dir, { recursive: true });

  const ext = path.extname(file.fileName) || "";
  const safeExt = ext.replace(/[^.a-zA-Z0-9]/g, "").slice(0, 12);
  const destPath = path.join(dir, `${platform}${safeExt}`);

  // Replace any prior stored file (extension may differ between uploads).
  await removeStoredFile(platform);
  await fs.writeFile(destPath, file.data);

  await query(
    `INSERT INTO download_links
       (platform, kind, external_url, file_name, file_path, content_type, size_bytes, version, updated_at)
     VALUES ($1, 'file', '', $2, $3, $4, $5, $6, now())
     ON CONFLICT (platform) DO UPDATE
       SET kind = 'file', external_url = '',
           file_name = EXCLUDED.file_name, file_path = EXCLUDED.file_path,
           content_type = EXCLUDED.content_type, size_bytes = EXCLUDED.size_bytes,
           version = EXCLUDED.version, updated_at = now()`,
    [platform, file.fileName, destPath, file.contentType, file.data.length, version],
  );
}

/** Clears a platform's configuration and deletes any stored binary. */
export async function deleteDownloadLink(platform: DownloadPlatform): Promise<void> {
  await removeStoredFile(platform);
  await query(`DELETE FROM download_links WHERE platform = $1`, [platform]);
}

async function removeStoredFile(platform: DownloadPlatform): Promise<void> {
  const existing = await getDownloadLink(platform);
  if (existing?.filePath) {
    await fs.rm(existing.filePath, { force: true }).catch((error) => {
      void logError({ source: "downloads-store/removeStoredFile", error });
    });
  }
}

export { DOWNLOAD_PLATFORMS };
