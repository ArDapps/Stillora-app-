/**
 * Canonical site + brand URLs used across metadata, JSON-LD, and footer links.
 * Keep these in one place so canonical/OG/sitemap stay consistent.
 */
export const SITE_URL = "https://stillora.loopara.app";
export const SITE_NAME = "Stillora";

export const SITE_DESCRIPTION =
  "Turn photos, image slideshows, and clips into share-ready MP4 videos. Add audio, choose Reels, TikTok, YouTube, or square formats, and export online with Stillora.";

// Parent brand. tecnoblocks.com is already referenced elsewhere in the project.
export const TECNOBLOCKS_URL = "https://tecnoblocks.com/";

/** The existing editor route — every primary CTA points here. */
export const EDITOR_PATH = "/editor";

/**
 * Live Apple App Store listing. The single universal listing serves iPhone and
 * iPad, and is also downloadable on Apple Silicon Macs from the Mac App Store.
 */
export const APP_STORE_URL =
  "https://apps.apple.com/ae/app/stillora-mp4-video-maker/id6777488603";

/**
 * Platform download targets used by the landing download buttons.
 * iOS and macOS both ship from the universal App Store listing above.
 * Windows ships as a zipped desktop build served from this site's own
 * `public/downloads` folder, so the download stays on our domain.
 * Google Play is not live yet — leave empty and the UI renders it as "Soon".
 */
export const MACOS_DOWNLOAD_URL = APP_STORE_URL;
export const GOOGLE_PLAY_URL = "";
export const WINDOWS_DOWNLOAD_URL = "/downloads/stillora-windows.zip";
/**
 * Android ships as a directly-installable APK served from this site's own
 * `public/downloads` folder until the Google Play listing is live.
 */
export const ANDROID_DOWNLOAD_URL = "/downloads/stillora-android.apk";
