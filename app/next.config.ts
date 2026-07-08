import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  turbopack: {
    root: process.cwd(),
  },
  // Server-only Node packages that must NOT be bundled, so their optional
  // native/dynamic requires (and shipped binaries) resolve at runtime:
  //  - `pg`: optional native/dynamic requires.
  //  - `puppeteer`: reads its own package files + spawns the system Chromium;
  //    bundling breaks module load, which 500s /api/convert/html.
  //  - `ffmpeg-static`: ships a binary whose path breaks when bundled.
  serverExternalPackages: ["pg", "puppeteer", "ffmpeg-static"],
};

export default nextConfig;
