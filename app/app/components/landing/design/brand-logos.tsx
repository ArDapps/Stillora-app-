/* Recognizable single-colour social brand marks (white glyph on a brand-tinted
   badge). Drawn with currentColor so the badge sets the fill. */

export type BrandName =
  | "instagram"
  | "tiktok"
  | "youtube"
  | "facebook"
  | "x"
  | "linkedin";

/** Brand badge background + accessible label for each platform. */
export const BRANDS: Record<BrandName, { bg: string; label: string }> = {
  instagram: { bg: "linear-gradient(135deg,#f9ce34,#ee2a7b 45%,#6228d7)", label: "Instagram" },
  tiktok: { bg: "#010101", label: "TikTok" },
  youtube: { bg: "#ff0000", label: "YouTube" },
  facebook: { bg: "#0866ff", label: "Facebook" },
  x: { bg: "#000000", label: "X" },
  linkedin: { bg: "#0a66c2", label: "LinkedIn" },
};

export function BrandLogo({ name, size = 20 }: { name: BrandName; size?: number }) {
  const p = { width: size, height: size, viewBox: "0 0 24 24", "aria-hidden": true } as const;
  switch (name) {
    case "instagram":
      return (
        <svg {...p} fill="none">
          <rect x="3.5" y="3.5" width="17" height="17" rx="5" stroke="currentColor" strokeWidth="1.9" />
          <circle cx="12" cy="12" r="4.1" stroke="currentColor" strokeWidth="1.9" />
          <circle cx="16.9" cy="7.1" r="1.25" fill="currentColor" />
        </svg>
      );
    case "tiktok":
      return (
        <svg {...p} fill="currentColor">
          <path d="M16.6 3c.35 2.1 1.53 3.37 3.57 3.5v2.62c-1.18.12-2.21-.27-3.42-1v5.86c0 3.72-4.06 6.04-7.26 3.9a4.53 4.53 0 0 1 1.9-8.24c.29-.04.57-.05.86-.03v2.7c-.27-.03-.55 0-.83.09a1.98 1.98 0 0 0-1.13 2.97c.85 1.4 3.02.82 3.02-.86V3h3.32z" />
        </svg>
      );
    case "youtube":
      return (
        <svg {...p} fill="currentColor">
          <path d="M21.5 8.3a2.5 2.5 0 0 0-1.76-1.77C18.2 6.1 12 6.1 12 6.1s-6.2 0-7.74.42A2.5 2.5 0 0 0 2.5 8.3 26 26 0 0 0 2.1 12a26 26 0 0 0 .4 3.7 2.5 2.5 0 0 0 1.76 1.77C5.8 17.9 12 17.9 12 17.9s6.2 0 7.74-.43a2.5 2.5 0 0 0 1.76-1.77c.27-1.22.4-2.46.4-3.7 0-1.24-.13-2.48-.4-3.7zM10.1 14.6V9.4l4.5 2.6-4.5 2.6z" />
        </svg>
      );
    case "facebook":
      return (
        <svg {...p} fill="currentColor">
          <path d="M13.4 21v-7.1h2.38l.36-2.77H13.4V9.35c0-.8.22-1.35 1.37-1.35h1.46V5.53c-.25-.03-1.12-.11-2.12-.11-2.1 0-3.54 1.28-3.54 3.64v2.03H8.18v2.77h2.39V21h2.83z" />
        </svg>
      );
    case "x":
      return (
        <svg {...p} fill="currentColor">
          <path d="M17.6 3.8h2.7l-5.9 6.73L21.4 20h-5.4l-4.24-5.54L6.9 20H4.2l6.3-7.2L3.4 3.8H9l3.83 5.06L17.6 3.8zm-.95 14.6h1.5L8.02 5.32H6.4l10.25 13.08z" />
        </svg>
      );
    case "linkedin":
      return (
        <svg {...p} fill="currentColor">
          <path d="M6.94 8.9H4.1V20h2.84V8.9zM5.52 4.3a1.65 1.65 0 1 0 0 3.3 1.65 1.65 0 0 0 0-3.3zM20 20v-6.1c0-3.06-1.63-4.48-3.81-4.48-1.76 0-2.54.97-2.98 1.65V8.9H10.4V20h2.83v-6.03c0-1.41.78-2.06 1.68-2.06.86 0 1.53.5 1.53 2.03V20H20z" />
        </svg>
      );
  }
}
