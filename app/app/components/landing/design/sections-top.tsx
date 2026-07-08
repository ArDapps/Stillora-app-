import { BrandLogo, BRANDS, type BrandName } from "./brand-logos";

function SecHead({ eyebrow, title, body }: { eyebrow: string; title: string; body: string }) {
  return (
    <div className="sec-head reveal">
      <span className="eyebrow"><span className="dot" />{eyebrow}</span>
      <h2>{title}</h2>
      <p>{body}</p>
    </div>
  );
}

export function TrustStrip() {
  const brands: BrandName[] = [
    "instagram",
    "tiktok",
    "youtube",
    "facebook",
    "x",
    "linkedin",
  ];
  return (
    <section className="trust">
      <div className="wrap">
        <span className="lbl">Built for</span>
        <div className="plat-badges">
          {brands.map((name) => (
            <span
              key={name}
              className="pbadge"
              style={{ background: BRANDS[name].bg }}
              title={BRANDS[name].label}
              aria-label={BRANDS[name].label}
            >
              <BrandLogo name={name} size={22} />
            </span>
          ))}
        </div>
        <span className="lbl">and more</span>
      </div>
    </section>
  );
}

export function Pillars() {
  const pillars: { big: string; gold?: boolean; t: string; s: string }[] = [
    { big: "Free", gold: true, t: "Always, no paywall", s: "No plans, no credit card, no account." },
    { big: "3-in-1", t: "Images, video, audio", s: "Mix every media type in one file." },
    { big: "6 formats", t: "Platform presets", s: "The right dimensions, every feed." },
    { big: "Everywhere", t: "Web, desktop & mobile", s: "Mac, Windows, Linux, iOS & Android." },
  ];
  return (
    <section className="pillars" id="why">
      <div className="wrap">
        <div className="pillar-grid">
          {pillars.map((p) => (
            <div className="pillar reveal" key={p.big}>
              <div className={`big${p.gold ? " gold" : ""}`}>{p.big}</div>
              <div className="pt">{p.t}</div>
              <div className="ps">{p.s}</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

export function MediaCards() {
  const cards = [
    {
      h: "Images",
      formats: "JPEG, PNG and WebP",
      ic: <svg width="24" height="24" viewBox="0 0 20 20" fill="none"><rect x="2.5" y="3.5" width="15" height="13" rx="2.5" stroke="currentColor" strokeWidth="1.4" /><circle cx="7" cy="8" r="1.6" fill="currentColor" /><path d="M3.5 14l4-4 3.5 3 2.5-2.5 3 3.5" stroke="currentColor" strokeWidth="1.4" fill="none" strokeLinecap="round" strokeLinejoin="round" /></svg>,
    },
    {
      h: "Video clips",
      formats: "MP4, MOV and AVI",
      ic: <svg width="24" height="24" viewBox="0 0 20 20" fill="none"><rect x="2" y="5" width="11" height="10" rx="2.5" stroke="currentColor" strokeWidth="1.4" /><path d="M13 9l5-2.5v7L13 11" stroke="currentColor" strokeWidth="1.4" fill="none" strokeLinejoin="round" /></svg>,
    },
    {
      h: "Audio tracks",
      formats: "MP3, WAV, M4A, AAC and OGG",
      ic: <svg width="22" height="22" viewBox="0 0 18 18" fill="none"><path d="M3 7v4M6 5v8M9 3v12M12 6v6M15 8v2" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" /></svg>,
    },
  ];
  return (
    <section className="section-pad" id="features">
      <div className="wrap">
        <SecHead
          eyebrow="Mix any media"
          title="Mix any media into one MP4 file"
          body="Combine a still photo, a video clip, and a backing audio track. Stillora renders it all into one polished export."
        />
        <div className="media-cards">
          {cards.map((c) => (
            <article className="media-card reveal" key={c.h}>
              <div className="mc-ic">{c.ic}</div>
              <h3>{c.h}</h3>
              <p className="formats">{c.formats}</p>
              <span className="glowline" />
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

export function Steps() {
  const steps = [
    { n: "01", h: "Drop your media", p: "Drag and drop images, clips, or audio. Stillora reads the file details and prepares a clean preview.", meta: "JPG · PNG · WebP · MP4 · MOV" },
    { n: "02", h: "Choose your format", p: "Pick a platform preset, switch Fit or Fill, add optional audio, and choose the export duration.", meta: "5 presets · Fit & Fill · Audio" },
    { n: "03", h: "Export your MP4", p: "Render a share-ready H.264 MP4 with AAC audio, then download it for any social platform.", meta: "H.264 · 30 FPS · AAC audio" },
  ];
  return (
    <section className="section-pad" id="how" style={{ paddingTop: 0 }}>
      <div className="wrap">
        <SecHead
          eyebrow="Simple workflow"
          title="Three steps to a ready-to-post video"
          body="No timelines, no keyframes. Just your media and the video you need."
        />
        <div className="steps">
          {steps.map((s) => (
            <article className="step reveal" key={s.n}>
              <span className="scount">{s.n}</span>
              <div className="num">Step {s.n}</div>
              <h3>{s.h}</h3>
              <p>{s.p}</p>
              <div className="meta">{s.meta}</div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

export function Presets() {
  const rows: { w: number; h: number; dashed?: boolean; pn: string; pd: string }[] = [
    { w: 17, h: 30, pn: "Reels / TikTok / Stories", pd: "1080 × 1920 · 9:16" },
    { w: 17, h: 30, pn: "YouTube Shorts", pd: "1080 × 1920 · 9:16" },
    { w: 32, h: 18, pn: "YouTube Long Video", pd: "1920 × 1080 · 16:9" },
    { w: 24, h: 24, pn: "Square Post", pd: "1080 × 1080 · 1:1" },
    { w: 28, h: 21, dashed: true, pn: "Original Image Size", pd: "As uploaded · As-is" },
  ];
  return (
    <section className="section-pad" id="formats" style={{ paddingTop: 0 }}>
      <div className="wrap">
        <SecHead
          eyebrow="Platform presets"
          title="Built for every feed"
          body="Stop guessing dimensions. Every major platform preset is built in."
        />
        <div className="presets">
          <div className="preset-list">
            {rows.map((r) => (
              <div className="preset-row reveal" key={r.pn}>
                <div className="preset-shape">
                  <i style={{ width: r.w, height: r.h, ...(r.dashed ? { borderStyle: "dashed" } : {}) }} />
                </div>
                <div className="preset-info">
                  <div className="pn">{r.pn}</div>
                  <div className="pd">{r.pd}</div>
                </div>
              </div>
            ))}
          </div>
          <div className="preset-card-mock reveal" role="img" aria-label="Stillora upload and format selection interface showing a vertical video preview with format tabs">
            <div className="pcm-head">
              <span className="pcm-badge">Vertical · 9:16</span>
              <span style={{ fontFamily: "var(--mono)", fontSize: 12, color: "var(--dim)" }}>1080 × 1920</span>
            </div>
            <div className="pcm-frame">
              <div className="ph2"><svg width="18" height="18" viewBox="0 0 16 16" fill="none"><path d="M5 3l8 5-8 5V3z" fill="#fff" /></svg></div>
            </div>
            <div className="pcm-tabs"><span className="on">Reels</span><span>Shorts</span><span>Square</span><span>Video</span></div>
          </div>
        </div>
      </div>
    </section>
  );
}

export function PlatformCards() {
  const cards: { ic: BrandName; h: string; sub: string; dim: string }[] = [
    { ic: "instagram", h: "Instagram", sub: "Reels, Stories & feed", dim: "1080 × 1920" },
    { ic: "tiktok", h: "TikTok", sub: "For You feed", dim: "1080 × 1920" },
    { ic: "youtube", h: "YouTube", sub: "Shorts & long video", dim: "1080×1920 / 1920×1080" },
    { ic: "facebook", h: "Facebook", sub: "Reels & feed", dim: "1080 × 1920" },
  ];
  return (
    <section className="section-pad" style={{ paddingTop: 0 }}>
      <div className="wrap">
        <SecHead
          eyebrow="Perfect presets"
          title="Perfect presets for every platform"
          body="Pick a platform and Stillora handles the dimensions, framing, and export settings."
        />
        <div className="platform-grid">
          {cards.map((c) => (
            <article className="pcard reveal" key={c.h}>
              <div className="pc-ic" style={{ background: BRANDS[c.ic].bg }}>
                <BrandLogo name={c.ic} size={26} />
              </div>
              <h3>{c.h}</h3>
              <div className="pc-sub">{c.sub}</div>
              <div className="pc-dim">{c.dim}</div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
