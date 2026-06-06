import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  turbopack: {
    root: process.cwd(),
  },
  async rewrites() {
    return [
      {
        source: "/ad-api/:path*",
        destination: "https://md.loopara.app/api/:path*",
      },
    ];
  },
};

export default nextConfig;
