import Link from "next/link";
import { EDITOR_PATH } from "@/lib/site";

export function DesignAura() {
  return (
    <div className="aura" aria-hidden="true">
      <span className="a1" />
      <span className="a2" />
      <span className="a3" />
    </div>
  );
}

export function DesignHero() {
  return (
    <section className="hero">
      <div className="wrap hero-grid">
        <div className="hero-copy">
          <div className="hero-badges reveal">
            <span className="tag">Free</span>
            <span className="tag">Web</span>
            <span className="tag">Mobile</span>
            <span className="tag">Desktop</span>
            <span className="tag">Android</span>
          </div>
          <h1 className="reveal">
            Mix images, video and audio into <span className="grad-text">one polished MP4</span>
          </h1>
          <p className="lede reveal">
            Stillora combines <b>still images, video clips, and audio tracks</b> into a single
            export-ready video — formatted for Reels, Shorts, TikTok, YouTube, and more.
          </p>

          <div className="media-flow reveal" aria-label="Images, video clips, audio tracks and HTML become an MP4">
            <span className="mf-chip">
              <svg width="17" height="17" viewBox="0 0 20 20" fill="none"><rect x="2.5" y="3.5" width="15" height="13" rx="2.5" stroke="currentColor" strokeWidth="1.4" /><circle cx="7" cy="8" r="1.6" fill="currentColor" /><path d="M3.5 14l4-4 3.5 3 2.5-2.5 3 3.5" stroke="currentColor" strokeWidth="1.4" fill="none" strokeLinecap="round" strokeLinejoin="round" /></svg>
              Images
            </span>
            <span className="mf-chip">
              <svg width="17" height="17" viewBox="0 0 20 20" fill="none"><rect x="2" y="5" width="11" height="10" rx="2.5" stroke="currentColor" strokeWidth="1.4" /><path d="M13 9l5-2.5v7L13 11" stroke="currentColor" strokeWidth="1.4" fill="none" strokeLinejoin="round" /></svg>
              Video clips
            </span>
            <span className="mf-chip">
              <svg width="16" height="16" viewBox="0 0 18 18" fill="none"><path d="M3 7v4M6 5v8M9 3v12M12 6v6M15 8v2" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" /></svg>
              Audio tracks
            </span>
            <span className="mf-chip">
              <svg width="16" height="16" viewBox="0 0 20 20" fill="none"><path d="M7 6L3.5 10 7 14M13 6l3.5 4L13 14" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" /></svg>
              HTML
            </span>
            <span className="mf-arrow" aria-hidden="true">
              <svg width="22" height="14" viewBox="0 0 22 14" fill="none"><path d="M1 7h19m0 0l-5-5m5 5l-5 5" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" /></svg>
            </span>
            <span className="mf-out">to MP4</span>
          </div>

          <div className="hero-actions reveal">
            <Link href={EDITOR_PATH} className="btn btn-primary btn-lg">
              <svg width="16" height="16" viewBox="0 0 16 16" fill="none"><path d="M8 1l1.6 4.4L14 7l-4.4 1.6L8 13l-1.6-4.4L2 7l4.4-1.6L8 1z" fill="currentColor" /></svg>
              Start Free — No Sign-up
            </Link>
            <a href="#how" className="btn btn-ghost btn-lg">
              <svg width="15" height="15" viewBox="0 0 16 16" fill="none"><path d="M4 3l9 5-9 5V3z" fill="currentColor" /></svg>
              Watch Demo
            </a>
          </div>

          <div className="hero-trust reveal">
            <span>100% free</span><span className="sep" />
            <span>Web, mobile &amp; desktop</span><span className="sep" />
            <span>No watermark</span><span className="sep" />
            <span>No account needed</span>
          </div>
        </div>

        {/* Real product shots: web editor + mobile app in a floating cluster */}
        <div className="hero-stage reveal" aria-label="Stillora running on the web and on mobile">
          <span className="stage-glow" aria-hidden="true" />

          <figure className="device-browser">
            <div className="browser-bar">
              <span className="bd" /><span className="bd" /><span className="bd" />
              <span className="browser-url">
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" aria-hidden="true"><rect x="3" y="11" width="18" height="10" rx="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" /></svg>
                stillora.app/editor
              </span>
            </div>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              className="browser-shot"
              src="/marketing/stillora-showcase-app.png"
              alt="Stillora web editor — output presets on the left and a live 9:16 MP4 preview"
              width={3250}
              height={1626}
              fetchPriority="high"
              decoding="async"
            />
            <span className="shine" aria-hidden="true" />
          </figure>

          <figure className="device-phone">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src="/marketing/phone-export.png"
              alt="Stillora mobile app — ready-to-export screen with video preview and an Export MP4 button"
              width={858}
              height={1640}
              decoding="async"
            />
          </figure>

          <div className="stage-badge sb-1">
            <span className="sb-ic" style={{ background: "rgba(34,197,94,.16)", color: "#86efac" }}>
              <svg width="15" height="15" viewBox="0 0 16 16" fill="none"><path d="M3 8.5l3.2 3.2L13 5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" /></svg>
            </span>
            <div><div className="sb-t">No watermark</div><div className="sb-s">1080p · MP4</div></div>
          </div>

          <div className="stage-badge sb-2">
            <span className="sb-ic" style={{ background: "rgba(250,204,21,.16)", color: "#facc15" }}>
              <svg width="15" height="15" viewBox="0 0 18 18" fill="none"><path d="M9 1.5l2.1 4.6 5 .5-3.8 3.4 1.1 4.9L9 12.9 4.6 15.4l1.1-4.9L1.9 6.6l5-.5z" fill="currentColor" /></svg>
            </span>
            <div><div className="sb-t">Exports in seconds</div><div className="sb-s">Web · iOS · Android</div></div>
          </div>
        </div>
      </div>
    </section>
  );
}
