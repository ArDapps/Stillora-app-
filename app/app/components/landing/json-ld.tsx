import { FAQ_ITEMS } from "@/lib/landing-content";
import { SITE_URL, TECNOBLOCKS_ORG_ID, TECNOBLOCKS_URL } from "@/lib/site";

/**
 * Structured data for the homepage. The FAQ entity is generated from the same
 * FAQ_ITEMS used by the visible accordion, so schema and page content stay in
 * sync. Rendered as a single @graph to avoid duplicate-script hydration noise.
 */
const structuredData = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      "@id": TECNOBLOCKS_ORG_ID,
      name: "Tecno Blocks",
      url: TECNOBLOCKS_URL,
    },
    {
      "@type": "WebApplication",
      "@id": `${SITE_URL}/#app`,
      name: "Stillora",
      url: `${SITE_URL}/`,
      applicationCategory: "MultimediaApplication",
      operatingSystem: "Web",
      description:
        "Stillora turns images, slideshows, and clips into share-ready MP4 videos with optional audio and social-media format presets.",
      creator: { "@id": TECNOBLOCKS_ORG_ID },
    },
    {
      "@type": "FAQPage",
      "@id": `${SITE_URL}/#faq`,
      mainEntity: FAQ_ITEMS.map((item) => ({
        "@type": "Question",
        name: item.question,
        acceptedAnswer: {
          "@type": "Answer",
          text: item.answer,
        },
      })),
    },
  ],
};

export function LandingJsonLd() {
  return (
    <script
      type="application/ld+json"
      // Static, trusted content — safe to inline. JSON.stringify prevents stray
      // characters from breaking the script tag.
      dangerouslySetInnerHTML={{ __html: JSON.stringify(structuredData) }}
    />
  );
}
