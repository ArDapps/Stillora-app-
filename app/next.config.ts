import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  turbopack: {
    root: process.cwd(),
  },
  // `pg` is a server-only Node package; keep it out of the bundler so its
  // optional native/dynamic requires resolve at runtime.
  serverExternalPackages: ["pg"],
};

export default nextConfig;
