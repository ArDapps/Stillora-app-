import {
  Download,
  Globe,
  ImageIcon,
  Laptop,
  Layers,
  Maximize2,
  Monitor,
  Music,
  Palette,
  Sliders,
  Smartphone,
  Square,
  Timer,
  Upload,
  UploadCloud,
  Zap,
} from "lucide-react";

export const platforms = [
  { name: "Instagram Reels", sub: "Stories and feed", badge: "IG", gradient: "from-[#f09433] via-[#dc2743] to-[#bc1888]", dims: "1080x1920" },
  { name: "TikTok", sub: "For You feed", badge: "TK", gradient: "from-[#010101] to-[#69C9D0]", dims: "1080x1920" },
  { name: "YouTube", sub: "Shorts and long", badge: "YT", gradient: "from-[#FF0000] to-[#cc0000]", dims: "1080x1920 / 1920x1080" },
  { name: "Facebook", sub: "Reels and feed", badge: "FB", gradient: "from-[#1877F2] to-[#0a5bc4]", dims: "1080x1920" },
];

export const appPlatforms = [
  {
    icon: Smartphone,
    name: "Mobile App",
    sub: "iOS and Android",
    status: "Live",
    color: "text-primary",
    bg: "bg-primary/10 border-primary/25",
    features: ["Full editor on the go", "Native camera upload", "Direct share to apps", "Offline export"],
  },
  {
    icon: Monitor,
    name: "Web App",
    sub: "All browsers",
    status: "Live",
    color: "text-accent",
    bg: "bg-accent/10 border-accent/25",
    features: ["No install needed", "Full-resolution export", "Drag-and-drop uploads", "Works on any device"],
  },
  {
    icon: Laptop,
    name: "Desktop App",
    sub: "Mac, Windows and Linux",
    status: "Soon",
    color: "text-amber-400",
    bg: "bg-amber-500/10 border-amber-500/25",
    features: ["Batch processing", "Local file access", "Faster FFmpeg encoding", "Pro-grade controls"],
  },
];

export const steps = [
  {
    icon: Upload,
    number: "01",
    title: "Drop your media",
    description: "Drag and drop images, clips, or audio. Stillora reads the file details and prepares a clean preview.",
    detail: "JPG, PNG, WebP, MP4, MOV",
    color: "text-primary",
    bg: "bg-primary/10 border-primary/20",
  },
  {
    icon: Sliders,
    number: "02",
    title: "Choose your format",
    description: "Pick a platform preset, switch Fit or Fill, add optional audio, and choose the export duration.",
    detail: "5 presets, Fit and Fill, Audio",
    color: "text-accent",
    bg: "bg-accent/10 border-accent/20",
  },
  {
    icon: Download,
    number: "03",
    title: "Export your MP4",
    description: "Render a share-ready H.264 MP4 with AAC audio, then download it for any social platform.",
    detail: "H.264, 30 FPS, AAC audio",
    color: "text-green-400",
    bg: "bg-green-500/10 border-green-500/20",
  },
];

export const formats = [
  { icon: Smartphone, label: "Reels / TikTok / Stories", dims: "1080 x 1920", ratio: "9:16", color: "text-pink-400", bg: "bg-pink-500/10 border-pink-500/20" },
  { icon: Smartphone, label: "YouTube Shorts", dims: "1080 x 1920", ratio: "9:16", color: "text-red-400", bg: "bg-red-500/10 border-red-500/20" },
  { icon: Monitor, label: "YouTube Long Video", dims: "1920 x 1080", ratio: "16:9", color: "text-blue-400", bg: "bg-blue-500/10 border-blue-500/20" },
  { icon: Square, label: "Square Post", dims: "1080 x 1080", ratio: "1:1", color: "text-purple-400", bg: "bg-purple-500/10 border-purple-500/20" },
  { icon: ImageIcon, label: "Original Image Size", dims: "As uploaded", ratio: "As-is", color: "text-green-400", bg: "bg-green-500/10 border-green-500/20" },
];

export const features = [
  { icon: Layers, title: "Mix media types", description: "Combine images, video clips, and audio tracks into one MP4 export.", tag: "3-in-1", color: "text-primary", bg: "bg-primary/10 border-primary/20" },
  { icon: UploadCloud, title: "Drag-and-drop upload", description: "Drop JPEG, PNG, WebP, MP4, or MOV files and preview them instantly.", tag: "Upload", color: "text-violet-400", bg: "bg-violet-500/10 border-violet-500/20" },
  { icon: Maximize2, title: "Smart Fit and Fill", description: "Fit shows the full frame. Fill crops neatly for each social format.", tag: "Framing", color: "text-blue-400", bg: "bg-blue-500/10 border-blue-500/20" },
  { icon: Music, title: "Audio track support", description: "Attach MP3, WAV, M4A, AAC, or OGG audio and trim it to the video.", tag: "Audio", color: "text-pink-400", bg: "bg-pink-500/10 border-pink-500/20" },
  { icon: Timer, title: "10s to 60s durations", description: "Use clean 10-second timing presets made for social posts, reels, and shorts.", tag: "Duration", color: "text-amber-400", bg: "bg-amber-500/10 border-amber-500/20" },
  { icon: Zap, title: "Fast FFmpeg encoding", description: "Render H.264, AAC, 30 FPS MP4s server-side with native FFmpeg.", tag: "FFmpeg", color: "text-green-400", bg: "bg-green-500/10 border-green-500/20" },
  { icon: Globe, title: "Web, mobile and desktop", description: "Use the web editor now, mobile app now, and desktop once it ships.", tag: "Platform", color: "text-cyan-400", bg: "bg-cyan-500/10 border-cyan-500/20" },
  { icon: Palette, title: "Background customization", description: "Use black, white, custom color, or blurred image backgrounds.", tag: "Canvas", color: "text-rose-400", bg: "bg-rose-500/10 border-rose-500/20" },
];

export const testimonials = [
  { quote: "I used to open Premiere just to render a photo as a 10s clip for Shorts. Stillora saves me hours every week.", author: "Sarah J.", role: "Tech reviewer", avatar: "SJ", color: "from-violet-500 to-purple-600" },
  { quote: "The blurred background when fitting landscape photos to vertical reels is perfect. Clean export every time.", author: "Mike T.", role: "Music producer", avatar: "MT", color: "from-blue-500 to-cyan-500" },
  { quote: "Fastest workflow ever. Drag, pick format, download. Exactly what I needed for podcast snippets.", author: "Elena R.", role: "Podcaster", avatar: "ER", color: "from-pink-500 to-rose-500" },
];

export const ctaPerks = [
  "100% free - no credit card ever",
  "No watermark on any export",
  "Web and mobile app available now",
  "All platform presets included",
  "Mix images, video and audio freely",
  "No account needed to start",
];
