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

        <div className="mock-stage reveal">
          <div className="mock-glow" aria-hidden="true" />
          <div className="phone" role="img" aria-label="Stillora app showing a photo being exported as a vertical MP4 with platform format options">
            <div className="phone-notch" />
            <div className="screen">
              <div className="photo" />
              <div className="topbar"><span>Stillora</span><span>9:16</span></div>
              <div className="playhead">
                <svg width="20" height="20" viewBox="0 0 16 16" fill="none"><path d="M5 3l8 5-8 5V3z" fill="#fff" /></svg>
              </div>
              <div className="chips">
                <span className="on">Reels</span><span>Shorts</span><span>TikTok</span><span>Video</span>
              </div>
              <div className="exporting">
                <div className="row"><b><span className="spinner" />Exporting MP4…</b><span>72%</span></div>
                <div className="ptrack"><div className="pfill" /></div>
              </div>
            </div>
          </div>
          <div className="float-card fc-left">
            <span className="fc-ic" style={{ background: "rgba(250,204,21,.16)", color: "#facc15" }}>
              <svg width="17" height="17" viewBox="0 0 18 18" fill="none"><path d="M3 7v4M6 5v8M9 3v12M12 6v6M15 8v2" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" /></svg>
            </span>
            <div><div className="fc-t">Audio mixed in</div><div className="fc-s">AAC · synced</div></div>
          </div>
          <div className="float-card fc-right">
            <span className="fc-ic" style={{ background: "rgba(34,197,94,.16)", color: "#86efac" }}>
              <svg width="16" height="16" viewBox="0 0 16 16" fill="none"><path d="M3 8.5l3.2 3.2L13 5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" /></svg>
            </span>
            <div><div className="fc-t">No watermark</div><div className="fc-s">1080 × 1920</div></div>
          </div>
        </div>
      </div>
    </section>
  );
}
