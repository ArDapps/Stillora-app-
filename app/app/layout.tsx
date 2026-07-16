import type { Metadata, Viewport } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import { SITE_DESCRIPTION, SITE_NAME, SITE_URL } from "@/lib/site";
import { SessionTracker } from "./components/session-tracker";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

const TITLE = "Stillora — Turn Images into MP4 Videos with Audio Online";

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: TITLE,
    template: `%s — ${SITE_NAME}`,
  },
  description: SITE_DESCRIPTION,
  applicationName: SITE_NAME,
  authors: [{ name: "Tecno Blocks", url: "https://tecnoblocks.com/" }],
  creator: "Tecno Blocks",
  publisher: "Tecno Blocks",
  alternates: {
    canonical: "/",
  },
  keywords: [
    "image to video",
    "image to MP4",
    "photo to reel",
    "TikTok slideshow maker",
    "add audio to image",
    "YouTube video from image",
    "MP4 export online",
  ],
  // og:image and twitter:image are supplied automatically by the
  // opengraph-image / twitter-image route files in this directory.
  openGraph: {
    type: "website",
    siteName: SITE_NAME,
    title: TITLE,
    description: SITE_DESCRIPTION,
    url: SITE_URL,
    locale: "en_US",
  },
  twitter: {
    card: "summary_large_image",
    title: TITLE,
    description: SITE_DESCRIPTION,
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-image-preview": "large",
      "max-snippet": -1,
      "max-video-preview": -1,
    },
  },
  icons: {
    icon: "/favicon.ico",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  themeColor: [
    { media: "(prefers-color-scheme: dark)", color: "#0b1326" },
    { media: "(prefers-color-scheme: light)", color: "#f7f6fc" },
  ],
};

// Runs before paint so the saved theme is applied without a flash. Defaults to dark.
const themeInitScript = `(function(){try{var t=localStorage.getItem("stillora-theme");if(t==="light"){document.documentElement.classList.add("light");}}catch(e){}})();`;

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeInitScript }} />
      </head>
      <body className="min-h-full flex flex-col">
        <SessionTracker />
        {children}
      </body>
    </html>
  );
}
