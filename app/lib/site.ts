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
 */
export const MACOS_DOWNLOAD_URL = APP_STORE_URL;

/**
 * Live Google Play listing. No `hl` parameter on purpose: Play then opens in
 * the visitor's own language, which matters for a site that ships English,
 * French and Arabic.
 */
export const GOOGLE_PLAY_URL =
  "https://play.google.com/store/apps/details?id=app.loopara.stillora";

export const WINDOWS_DOWNLOAD_URL = "/downloads/stillora-windows.zip";

/**
 * Android now installs from Play. The signed APK stays served at
 * `/downloads/stillora-android.apk` for sideloading and for regions without
 * Play — point the Downloads panel at it to make that the public link again.
 */
export const ANDROID_DOWNLOAD_URL = GOOGLE_PLAY_URL;
export const ANDROID_APK_URL = "/downloads/stillora-android.apk";
