import path from "node:path";
import {
  APP_STORE_URL,
  GOOGLE_PLAY_URL,
  MACOS_DOWNLOAD_URL,
  WINDOWS_DOWNLOAD_URL,
} from "./site";

/**
 * Admin-managed platform downloads (Downloads panel → landing buttons).
 *
 * Each platform is either backed by an uploaded binary (served from
 * `/download/<platform>`) or an external link the admin pastes. When a platform
 * has no row, the landing button falls back to the shipped default below so the
 * site behaves exactly as before the panel was added.
 */
export const DOWNLOAD_PLATFORMS = ["ios", "android", "macos", "windows"] as const;
export type DownloadPlatform = (typeof DOWNLOAD_PLATFORMS)[number];

export function isDownloadPlatform(value: string): value is DownloadPlatform {
  return (DOWNLOAD_PLATFORMS as readonly string[]).includes(value);
}

/** Public URL used when a platform has no admin-configured download. */
export const DEFAULT_DOWNLOAD_URL: Record<DownloadPlatform, string> = {
  ios: APP_STORE_URL,
  android: GOOGLE_PLAY_URL,
  macos: MACOS_DOWNLOAD_URL,
  windows: WINDOWS_DOWNLOAD_URL,
};

export type DownloadLinks = Record<DownloadPlatform, string>;

/** Resolved public URLs before any DB overrides — used as the safe default. */
export const DEFAULT_DOWNLOAD_LINKS: DownloadLinks = { ...DEFAULT_DOWNLOAD_URL };

/** Human labels for the admin UI. */
export const DOWNLOAD_LABELS: Record<DownloadPlatform, string> = {
  ios: "iOS (App Store)",
  android: "Android (APK / Play)",
  macos: "macOS",
  windows: "Windows",
};

/** 300 MB cap — comfortably fits an APK or a zipped desktop build. */
export const MAX_DOWNLOAD_BYTES = 300 * 1024 * 1024;

/**
 * Root directory for uploaded binaries. Defaults to the Docker writable volume
 * (`/data/stillora`); falls back to `<cwd>/storage` for local development.
 */
export function downloadsDir(): string {
  const base = process.env.STILLORA_DATA_DIR || path.join(process.cwd(), "storage");
  return path.join(base, "downloads");
}
