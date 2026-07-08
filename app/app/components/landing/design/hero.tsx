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
      <div className="wrap">
        <div className="hero-head">
          <span className="eyebrow reveal">
            <span className="dot" />
            Free · Web · Mobile · Desktop
          </span>
          <h1 className="reveal">
            Turn images, video &amp; audio into{" "}
            <span className="grad-text">one polished MP4</span>
          </h1>
          <p className="lede reveal">
            Stillora combines <b>still images, video clips and audio tracks</b> into a
            single export-ready video — sized for Reels, Shorts, TikTok and YouTube.
            Runs on the web, your phone, and your desktop.
          </p>

          <div className="hero-actions reveal">
            <Link href={EDITOR_PATH} className="btn btn-primary btn-lg">
              <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                <path d="M8 1l1.6 4.4L14 7l-4.4 1.6L8 13l-1.6-4.4L2 7l4.4-1.6L8 1z" fill="currentColor" />
              </svg>
              Start Free — No Sign-up
            </Link>
            <a href="#how" className="btn btn-ghost btn-lg">
              <svg width="15" height="15" viewBox="0 0 16 16" fill="none">
                <path d="M4 3l9 5-9 5V3z" fill="currentColor" />
              </svg>
              Watch Demo
            </a>
          </div>

          <div className="hero-trust reveal">
            <span>100% free</span><span className="sep" />
            <span>No watermark</span><span className="sep" />
            <span>No account needed</span>
          </div>
        </div>

        {/* Real product shots: desktop editor in a browser + two mobile app screens */}
        <div className="hero-showcase reveal" aria-label="Stillora running on desktop and mobile">
          <span className="sc-glow" aria-hidden="true" />

          <figure className="sc-window">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              className="sc-shot"
              src="/marketing/stillora-desktop.png"
              alt="Stillora Desktop Studio — source media, presets and a live 9:16 MP4 preview"
              width={3146}
              height={2480}
              fetchPriority="high"
              decoding="async"
            />
            <span className="sc-shine" aria-hidden="true" />
          </figure>

          <figure className="sc-phone sc-phone-l">
            <span className="sc-notch" aria-hidden="true" />
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src="/marketing/screens/01-create.png"
              alt="Stillora mobile app — Create screen"
              width={1080}
              height={2336}
              decoding="async"
            />
          </figure>

          <figure className="sc-phone sc-phone-r">
            <span className="sc-notch" aria-hidden="true" />
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src="/marketing/screens/05-export.png"
              alt="Stillora mobile app — Export screen with an Export MP4 button"
              width={1080}
              height={2336}
              decoding="async"
            />
          </figure>

          <div className="sc-badge sc-b1">
            <span className="sb-ic" style={{ background: "rgba(34,197,94,.16)", color: "#86efac" }}>
              <svg width="15" height="15" viewBox="0 0 16 16" fill="none">
                <path d="M3 8.5l3.2 3.2L13 5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </span>
            <div><div className="sb-t">No watermark</div><div className="sb-s">1080p · MP4</div></div>
          </div>

          <div className="sc-badge sc-b2">
            <span className="sb-ic" style={{ background: "rgba(250,204,21,.16)", color: "#facc15" }}>
              <svg width="15" height="15" viewBox="0 0 18 18" fill="none">
                <path d="M9 1.5l2.1 4.6 5 .5-3.8 3.4 1.1 4.9L9 12.9 4.6 15.4l1.1-4.9L1.9 6.6l5-.5z" fill="currentColor" />
              </svg>
            </span>
            <div><div className="sb-t">Exports in seconds</div><div className="sb-s">Web · iOS · Android</div></div>
          </div>
        </div>
      </div>
    </section>
  );
}
