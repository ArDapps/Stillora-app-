import { Film, Music, Zap } from "lucide-react";

export function AppMockup() {
  return (
    <div className="relative mx-auto w-full max-w-sm">
      <div className="animate-spin-slow pointer-events-none absolute inset-[-20px] rounded-full border border-dashed border-primary/10" />
      <div
        className="pointer-events-none absolute inset-[-40px] rounded-full border border-accent/10"
        style={{ animation: "spin-slow 30s linear infinite reverse" }}
      />

      <div className="animate-float relative mx-auto w-56 overflow-hidden rounded-[2.5rem] border-4 border-white/10 bg-card shadow-2xl shadow-primary/20 sm:w-64">
        <div className="flex h-6 items-center justify-center bg-muted/50">
          <div className="h-1.5 w-16 rounded-full bg-white/20" />
        </div>

        <div className="relative flex aspect-[9/16] flex-col overflow-hidden bg-gradient-to-b from-[#0f0c29] via-[#302b63] to-[#24243e]">
          <div className="z-10 flex flex-shrink-0 items-center justify-between bg-black/30 px-3 py-2 backdrop-blur-sm">
            <span className="text-[9px] font-semibold text-white/80">Stillora</span>
            <div className="flex gap-1">
              {["Reels", "Shorts", "TikTok"].map((format, index) => (
                <span
                  key={format}
                  className={`rounded-full px-1.5 py-0.5 text-[7px] font-medium ${
                    index === 0 ? "bg-primary/80 text-white" : "bg-white/10 text-white/70"
                  }`}
                >
                  {format}
                </span>
              ))}
            </div>
          </div>

          <div className="absolute right-2 top-10 z-20">
            <span className="rounded-full bg-blue-500/80 px-2 py-0.5 text-[7px] font-bold text-white">
              Video
            </span>
          </div>

          <div className="relative flex flex-1 items-center justify-center">
            <div className="absolute inset-0 bg-gradient-to-br from-purple-900/60 via-blue-900/40 to-indigo-900/60" />
            <svg
              viewBox="0 0 200 280"
              className="absolute inset-0 size-full opacity-80"
              preserveAspectRatio="xMidYMid slice"
              aria-hidden
            >
              <defs>
                <linearGradient id="hero-phone-sky" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#1a0533" />
                  <stop offset="50%" stopColor="#2d1b69" />
                  <stop offset="100%" stopColor="#0f3460" />
                </linearGradient>
                <linearGradient id="hero-phone-mountain-one" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#7c3aed" />
                  <stop offset="100%" stopColor="#312e81" />
                </linearGradient>
                <linearGradient id="hero-phone-mountain-two" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#5b21b6" />
                  <stop offset="100%" stopColor="#1e1b4b" />
                </linearGradient>
              </defs>
              <rect width="200" height="280" fill="url(#hero-phone-sky)" />
              {[20, 50, 90, 140, 170, 30, 80, 160, 190, 10, 120].map((x, index) => (
                <circle
                  key={`${x}-${index}`}
                  cx={x}
                  cy={(index * 7) % 60 + 5}
                  r="1"
                  fill="white"
                  opacity="0.7"
                />
              ))}
              <path
                d="M0 100 Q50 60 100 90 Q150 120 200 80 L200 130 Q150 160 100 130 Q50 100 0 140Z"
                fill="#7c3aed"
                opacity="0.15"
              />
              <path
                d="M0 220 L40 140 L80 170 L120 120 L160 155 L200 130 L200 280 L0 280Z"
                fill="url(#hero-phone-mountain-two)"
                opacity="0.8"
              />
              <path
                d="M0 260 L50 180 L90 210 L130 160 L170 195 L200 170 L200 280 L0 280Z"
                fill="url(#hero-phone-mountain-one)"
              />
              <path d="M130 160 L140 175 L150 168 L155 178 L130 160Z" fill="white" opacity="0.8" />
              <ellipse cx="100" cy="272" rx="60" ry="10" fill="#2563eb" opacity="0.25" />
            </svg>

            <div className="animate-pulse-glow absolute bottom-4 left-1/2 flex -translate-x-1/2 items-center gap-1.5 rounded-full bg-primary/90 px-3 py-1.5 shadow-lg backdrop-blur-sm">
              <Film className="size-2.5 text-white" />
              <span className="text-[8px] font-bold text-white">Exporting MP4...</span>
            </div>
            <div className="absolute bottom-12 left-3 right-3">
              <div className="h-0.5 overflow-hidden rounded-full bg-white/10">
                <div className="animate-progress h-full rounded-full bg-gradient-to-r from-primary to-accent" />
              </div>
            </div>
          </div>

          <div className="flex flex-shrink-0 gap-1 bg-black/40 px-2 py-1.5 backdrop-blur-sm">
            {[
              { label: "Reels", active: true },
              { label: "Shorts", active: false },
              { label: "Square", active: false },
            ].map((format) => (
              <span
                key={format.label}
                className={`flex-1 rounded-md py-1 text-center text-[8px] font-semibold ${
                  format.active ? "bg-primary text-white" : "text-white/50"
                }`}
              >
                {format.label}
              </span>
            ))}
          </div>
        </div>
      </div>

      <div
        className="animate-badge-pop absolute -left-6 top-12 flex items-center gap-2 rounded-lg border border-border/80 bg-card px-3 py-2 shadow-xl sm:-left-10"
        style={{ animationDelay: "0.8s" }}
      >
        <div className="grid size-7 flex-shrink-0 place-items-center rounded-md bg-green-500/20">
          <Zap className="size-3.5 text-green-400" />
        </div>
        <div>
          <p className="text-[10px] font-bold text-foreground">Free forever</p>
          <p className="text-[9px] text-muted-foreground">No credit card</p>
        </div>
      </div>

      <div
        className="animate-badge-pop absolute -right-6 top-1/3 flex items-center gap-2 rounded-lg border border-border/80 bg-card px-3 py-2 shadow-xl sm:-right-10"
        style={{ animationDelay: "1.1s" }}
      >
        <div className="grid size-7 flex-shrink-0 place-items-center rounded-md bg-primary/20">
          <Film className="size-3.5 text-primary" />
        </div>
        <div>
          <p className="text-[10px] font-bold text-foreground">1080x1920</p>
          <p className="text-[9px] text-muted-foreground">9:16 Vertical</p>
        </div>
      </div>

      <div
        className="animate-badge-pop absolute -left-4 bottom-16 flex items-center gap-2 rounded-lg border border-border/80 bg-card px-3 py-2 shadow-xl sm:-left-8"
        style={{ animationDelay: "1.4s" }}
      >
        <div className="grid size-7 flex-shrink-0 place-items-center rounded-md bg-pink-500/20">
          <Music className="size-3.5 text-pink-400" />
        </div>
        <div>
          <p className="text-[10px] font-bold text-foreground">Image + Audio</p>
          <p className="text-[9px] text-muted-foreground">Mixed in one file</p>
        </div>
      </div>
    </div>
  );
}
