function SecHead({ eyebrow, title, body }: { eyebrow: string; title: string; body: string }) {
  return (
    <div className="sec-head reveal">
      <span className="eyebrow"><span className="dot" />{eyebrow}</span>
      <h2>{title}</h2>
      <p>{body}</p>
    </div>
  );
}

export function Testimonials() {
  const stats = [
    ["10,000+", "Videos exported"],
    ["4.9/5", "Average rating"],
    ["3s", "Avg setup time"],
    ["5 presets", "Platform formats"],
  ];
  const quotes: { q: string; av: string; bg: string; color?: string; nm: string; rl: string }[] = [
    { q: "I used to open Premiere just to render a photo as a 10s clip for Shorts. Stillora saves me hours every week.", av: "SJ", bg: "#7c3aed", nm: "Sarah J.", rl: "Tech reviewer" },
    { q: "The blurred background when fitting landscape photos to vertical reels is perfect. Clean export every time.", av: "MT", bg: "#312e81", nm: "Mike T.", rl: "Music producer" },
    { q: "Fastest workflow ever. Drag, pick format, download. Exactly what I needed for podcast snippets.", av: "ER", bg: "#eec200", color: "#3c2f00", nm: "Elena R.", rl: "Podcaster" },
  ];
  return (
    <section className="section-pad" style={{ paddingTop: 0 }}>
      <div className="wrap">
        <SecHead
          eyebrow="Creator love"
          title="Loved by content creators"
          body="Creators use Stillora to turn static content into platform-ready videos without opening a complicated editor."
        />
        <div className="stats-strip">
          {stats.map(([sv, sl]) => (
            <div className="stat reveal" key={sl}>
              <div className="sv">{sv}</div>
              <div className="sl">{sl}</div>
            </div>
          ))}
        </div>
        <div className="quotes">
          {quotes.map((t) => (
            <figure className="quote reveal" key={t.nm}>
              <div className="stars" aria-label="5 out of 5 stars">★★★★★</div>
              <blockquote>&quot;{t.q}&quot;</blockquote>
              <figcaption className="who">
                <span className="av" style={{ background: t.bg, ...(t.color ? { color: t.color } : {}) }}>{t.av}</span>
                <span><span className="nm">{t.nm}</span><br /><span className="rl">{t.rl}</span></span>
              </figcaption>
            </figure>
          ))}
        </div>
      </div>
    </section>
  );
}

export function Faq() {
  const faqs = [
    { q: "Is Stillora free to use?", a: "Yes — Stillora is 100% free, with no plans, no paywalls, and no credit card required. Every export is free and there is no watermark on any video." },
    { q: "Can I combine images, video, and audio in one video?", a: "Yes. Stillora mixes still images, video clips, and a backing audio track into a single MP4 export. Images can be JPEG, PNG or WebP; video can be MP4, MOV or AVI; audio can be MP3, WAV, M4A, AAC or OGG." },
    { q: "Which social media formats does Stillora support?", a: "Stillora includes built-in presets for Reels, TikTok and Stories (1080×1920, 9:16), YouTube Shorts (1080×1920), YouTube long video (1920×1080, 16:9), Square posts (1080×1080, 1:1), and Original image size." },
    { q: "Do I need an account to use Stillora?", a: "No. You can start creating in your browser instantly — no sign-up and no account required." },
    { q: "What format does Stillora export?", a: "Stillora exports a share-ready H.264 MP4 with AAC audio at 30 FPS, rendered server-side with native FFmpeg." },
    { q: "What platforms is Stillora available on?", a: "Stillora is available now on every platform — a web app in any browser, a desktop app for Mac, Windows and Linux, and mobile apps for iOS and Android (including tablets)." },
  ];
  return (
    <section className="section-pad" id="faq" style={{ paddingTop: 0 }}>
      <div className="wrap">
        <SecHead
          eyebrow="FAQ"
          title="Questions, answered"
          body="Everything you need to know about turning images, video, and audio into share-ready MP4s."
        />
        <div className="faq-wrap">
          {faqs.map((f, i) => (
            <details className="faq reveal" key={f.q} open={i === 0}>
              <summary>
                {f.q}
                <span className="pm"><svg width="13" height="13" viewBox="0 0 16 16" fill="none"><path d="M8 3v10M3 8h10" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" /></svg></span>
              </summary>
              <div className="ans">{f.a}</div>
            </details>
          ))}
        </div>
      </div>
    </section>
  );
}
