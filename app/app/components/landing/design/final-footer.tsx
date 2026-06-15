import Link from "next/link";
import { EDITOR_PATH, TECNOBLOCKS_URL } from "@/lib/site";
import { BrandMark } from "./nav";
import { AppStoreLink } from "./store";

function Ck() {
  return (
    <span className="ck">
      <svg width="12" height="12" viewBox="0 0 16 16" fill="none"><path d="M3 8.5l3.2 3.2L13 5" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" /></svg>
    </span>
  );
}

export function FinalCta() {
  const perks = [
    "100% free — no credit card ever",
    "No watermark on any export",
    "All platform presets included",
    "Mix images, video and audio freely",
    "No account needed to start",
  ];
  return (
    <section className="final">
      <div className="wrap">
        <div className="final-card reveal">
          <div className="final-grid">
            <div>
              <h2>Start creating for free today</h2>
              <p>Mix images, video clips, and audio tracks into platform-ready MP4s. Available now on web, desktop, and mobile.</p>
              <div className="final-actions">
                <Link href={EDITOR_PATH} className="btn btn-gold btn-lg">Start Free</Link>
                <AppStoreLink id="dl-app-store-cta" data="ios" kind="apple" top="Download on the" bottom="App Store" />
              </div>
            </div>
            <ul className="check-list">
              {perks.map((p) => (
                <li key={p}><Ck />{p}</li>
              ))}
            </ul>
          </div>
        </div>
      </div>
    </section>
  );
}

export function DesignFooter() {
  return (
    <footer>
      <div className="wrap">
        <div className="foot-grid">
          <div className="foot-brand">
            <a className="brand" href="#top" aria-label="Stillora home">
              <BrandMark size={30} />
              <span className="word">Stillora</span>
            </a>
            <p>Mix images, video clips, and audio tracks into one platform-ready MP4. Free on web, desktop and mobile — Mac, Windows, Linux, iOS and Android.</p>
          </div>
          <div className="foot-col">
            <h4>Product</h4>
            <a href="#features">Features</a>
            <a href="#formats">Formats</a>
            <a href="#how">How it works</a>
            <a href="#platforms">Apps</a>
          </div>
          <div className="foot-col">
            <h4>Legal</h4>
            <Link href="/privacy">Privacy Policy</Link>
            <Link href="/terms">Terms of Service</Link>
            <a href="mailto:support@tecnoblocks.com">Contact</a>
          </div>
          <div className="foot-col">
            <h4>Get started</h4>
            <Link href={EDITOR_PATH}>Open Web App</Link>
            <a href="#platforms">Download iOS App</a>
            <a href="#faq">FAQ</a>
          </div>
        </div>
        <div className="foot-bottom">
          <span>© {new Date().getFullYear()} Stillora. Free to use. All rights reserved. Built by{" "}
            <a href={TECNOBLOCKS_URL} target="_blank" rel="noopener noreferrer" style={{ color: "var(--violet-bright)" }}>Tecno Blocks</a>
          </span>
          <div className="badges">
            <span className="tag">100% free</span>
            <span className="tag">No watermark</span>
            <span className="tag">No account</span>
          </div>
        </div>
      </div>
    </footer>
  );
}
