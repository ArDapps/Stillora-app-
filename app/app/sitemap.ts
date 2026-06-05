import type { MetadataRoute } from "next";
import { SITE_URL } from "@/lib/site";

/**
 * Only real, public, indexable URLs belong here. The editor is a working app
 * route; the homepage is the marketing landing page. Future use-case and guide
 * pages should be appended once they ship with unique content.
 */
export default function sitemap(): MetadataRoute.Sitemap {
  const lastModified = new Date();
  return [
    {
      url: `${SITE_URL}/`,
      lastModified,
      changeFrequency: "weekly",
      priority: 1,
    },
    {
      url: `${SITE_URL}/editor`,
      lastModified,
      changeFrequency: "monthly",
      priority: 0.8,
    },
  ];
}
