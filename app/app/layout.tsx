import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Stillora - Turn images into share-ready videos",
  description:
    "Stillora turns images and clips into polished, perfectly-sized social videos in seconds. Reels, Shorts, TikTok, and square posts with optional audio.",
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
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}
