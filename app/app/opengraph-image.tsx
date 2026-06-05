import { ImageResponse } from "next/og";
import { SITE_NAME } from "@/lib/site";

/*
 * Programmatically generated social-preview image (1200×630). This avoids
 * shipping a binary asset while still producing a real, branded OG/Twitter card.
 * TODO: replace with a hand-designed `opengraph-image.png` (and matching
 * `twitter-image.png`) once final brand artwork is available.
 */

export const alt = "Stillora — Turn any image into a share-ready video";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default function OpengraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          padding: "80px",
          background:
            "radial-gradient(1000px 600px at 15% 0%, rgba(124,58,237,0.45), transparent 60%), radial-gradient(900px 600px at 95% 20%, rgba(236,72,153,0.35), transparent 55%), linear-gradient(135deg, #0b1326 0%, #060e20 60%, #131b2e 100%)",
          color: "#dae2fd",
          fontFamily: "sans-serif",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 20 }}>
          <div
            style={{
              width: 64,
              height: 64,
              borderRadius: 16,
              background: "linear-gradient(145deg, #2dd4ff, #8b5cf6 55%, #ec4899)",
              display: "flex",
            }}
          />
          <div style={{ display: "flex", flexDirection: "column" }}>
            <span style={{ fontSize: 36, fontWeight: 700, color: "#ffffff" }}>{SITE_NAME}</span>
            <span style={{ fontSize: 22, color: "#958da1" }}>Built by Tecno Blocks</span>
          </div>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 24 }}>
          <span style={{ fontSize: 70, fontWeight: 800, lineHeight: 1.05, color: "#ffffff" }}>
            Turn any image into a
          </span>
          <span
            style={{
              fontSize: 70,
              fontWeight: 800,
              lineHeight: 1.05,
              background: "linear-gradient(135deg, #a855f7 0%, #ec4899 100%)",
              backgroundClip: "text",
              color: "transparent",
            }}
          >
            share-ready video
          </span>
        </div>

        <div style={{ display: "flex", gap: 16, fontSize: 26, color: "#ccc3d8" }}>
          <span>Reels · TikTok · YouTube · Square</span>
          <span style={{ color: "#7c3aed" }}>·</span>
          <span>1080p MP4 with audio</span>
        </div>
      </div>
    ),
    { ...size },
  );
}
