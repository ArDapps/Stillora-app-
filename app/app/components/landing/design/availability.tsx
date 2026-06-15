import Link from "next/link";
import { EDITOR_PATH } from "@/lib/site";
import { AppStoreLink } from "./store";

function Tick() {
  return (
    <span className="tick">
      <svg width="11" height="11" viewBox="0 0 16 16" fill="none"><path d="M3 8.5l3.2 3.2L13 5" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" /></svg>
    </span>
  );
}

function AList({ items }: { items: string[] }) {
  return (
    <ul className="a-list">
      {items.map((i) => (
        <li key={i}><Tick />{i}</li>
      ))}
    </ul>
  );
}

function SecHead({ eyebrow, title, body }: { eyebrow: string; title: string; body: string }) {
  return (
    <div className="sec-head reveal">
      <span className="eyebrow"><span className="dot" />{eyebrow}</span>
      <h2>{title}</h2>
      <p>{body}</p>
    </div>
  );
}

export function Availability() {
  return (
    <section className="section-pad" id="platforms" style={{ paddingTop: 0 }}>
      <div className="wrap">
        <SecHead
          eyebrow="Available everywhere"
          title="Web, desktop and mobile — free"
          body="Start in your browser, continue on your phone, and power up on desktop. Free on every platform — Mac, Windows, Linux, iOS and Android."
        />
        <div className="avail-grid">
          <article className="avail live reveal">
            <span className="status s-live"><span className="pulse" />Live</span>
            <h3>Web App</h3>
            <div className="a-platforms">All browsers</div>
            <AList items={["No install needed", "Full-resolution export", "Drag-and-drop uploads", "Works on any device"]} />
            <div className="a-foot">
              <Link href={EDITOR_PATH} className="btn btn-primary" style={{ height: 46, width: "100%" }}>Open Web App</Link>
            </div>
          </article>

          <article className="avail live featured reveal">
            <span className="status s-live"><span className="pulse" />Live</span>
            <h3>Mobile App</h3>
            <div className="a-platforms">iOS, Android &amp; tablet</div>
            <AList items={["Full editor on the go", "Native camera upload", "Direct share to apps", "Offline export"]} />
            <div className="a-foot store-stack">
              <AppStoreLink id="dl-app-store" data="ios" kind="apple" top="Download on the" bottom="App Store" />
              <AppStoreLink id="dl-google-play" data="android" kind="play" top="Get it on" bottom="Google Play" />
            </div>
          </article>

          <article className="avail live reveal">
            <span className="status s-live"><span className="pulse" />Live</span>
            <h3>Desktop App</h3>
            <div className="a-platforms">Mac, Windows and Linux</div>
            <AList items={["Batch processing", "Local file access", "Faster FFmpeg encoding", "Pro-grade controls"]} />
            <div className="a-foot store-stack">
              <AppStoreLink id="dl-macos" data="macos" kind="apple" top="Download for" bottom="macOS" />
              <AppStoreLink id="dl-windows" data="windows" kind="windows" top="Download for" bottom="Windows" />
            </div>
          </article>
        </div>
      </div>
    </section>
  );
}

export function FeatureGrid() {
  const features = [
    { tag: "3-in-1", h: "Mix media types", p: "Combine images, video clips, and audio tracks into one MP4 export.", ic: <svg width="20" height="20" viewBox="0 0 20 20" fill="none"><path d="M10 2l2 5 5 .5-3.8 3.3L14.5 16 10 13.3 5.5 16l1.3-5.2L3 7.5 8 7z" fill="currentColor" /></svg> },
    { tag: "New", h: "HTML to video", p: "Render a web page, animation, or HTML snippet straight into a polished MP4.", ic: <svg width="20" height="20" viewBox="0 0 20 20" fill="none"><path d="M7 6L3.5 10 7 14M13 6l3.5 4L13 14" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" /></svg> },
    { tag: "Upload", h: "Drag-and-drop upload", p: "Drop JPEG, PNG, WebP, MP4, or MOV files and preview them instantly.", ic: <svg width="20" height="20" viewBox="0 0 20 20" fill="none"><path d="M10 13V3m0 0L6 7m4-4l4 4M4 16h12" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" /></svg> },
    { tag: "Framing", h: "Smart Fit and Fill", p: "Fit shows the full frame. Fill crops neatly for each social format.", ic: <svg width="20" height="20" viewBox="0 0 20 20" fill="none"><rect x="3" y="3" width="14" height="14" rx="2" stroke="currentColor" strokeWidth="1.5" /><path d="M3 12l4-3 3 2 3-3 4 3" stroke="currentColor" strokeWidth="1.5" fill="none" strokeLinejoin="round" /></svg> },
    { tag: "Audio", h: "Audio track support", p: "Attach MP3, WAV, M4A, AAC, or OGG audio and trim it to the video.", ic: <svg width="20" height="20" viewBox="0 0 18 18" fill="none"><path d="M3 7v4M6 5v8M9 3v12M12 6v6M15 8v2" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" /></svg> },
    { tag: "Duration", h: "10s to 60s durations", p: "Use clean timing presets made for social posts, reels, and shorts.", ic: <svg width="20" height="20" viewBox="0 0 20 20" fill="none"><circle cx="10" cy="10" r="7.5" stroke="currentColor" strokeWidth="1.5" /><path d="M10 6v4l3 2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" /></svg> },
    { tag: "FFmpeg", h: "Fast FFmpeg encoding", p: "Render H.264, AAC, 30 FPS MP4s server-side with native FFmpeg.", ic: <svg width="20" height="20" viewBox="0 0 20 20" fill="none"><path d="M4 3l9 5-9 5V3z" fill="currentColor" /><path d="M15 4v12" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" /></svg> },
    { tag: "Canvas", h: "Background customization", p: "Use black, white, custom color, or blurred image backgrounds.", ic: <svg width="20" height="20" viewBox="0 0 20 20" fill="none"><rect x="3" y="3" width="14" height="14" rx="3" stroke="currentColor" strokeWidth="1.5" /><circle cx="10" cy="10" r="2.4" fill="currentColor" /></svg> },
  ];
  return (
    <section className="section-pad" style={{ paddingTop: 0 }}>
      <div className="wrap">
        <SecHead
          eyebrow="Everything included — free"
          title="No fluff. Just the essentials."
          body="All features are free. No plans, no paywalls — just the tools creators need to ship great content."
        />
        <div className="feature-grid">
          {features.map((f) => (
            <article className="feature reveal" key={f.h}>
              <div className="f-ic">{f.ic}</div>
              <div className="f-tag">{f.tag}</div>
              <h3>{f.h}</h3>
              <p>{f.p}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
