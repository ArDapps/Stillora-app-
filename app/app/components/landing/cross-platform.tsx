import { Check, Film, ImageIcon, Music } from "lucide-react";
import { AppStoreButton, SectionHeading } from "./shared";
import { appPlatforms } from "./data";

export function CrossPlatform() {
  return (
    <section className="relative overflow-hidden py-20 sm:py-28">
      <div className="mx-auto w-full max-w-7xl px-4 sm:px-6">
        <SectionHeading
          eyebrow="Available everywhere"
          title="Web, mobile and"
          highlight="desktop - free"
          body="Start in your browser. Continue on your phone. Power up on desktop when it launches."
        />
        <div className="mb-16 grid grid-cols-1 gap-5 sm:mb-20 sm:gap-6 md:grid-cols-3">
          {appPlatforms.map((platform) => (
            <div key={platform.name} className={`relative rounded-lg border bg-card/60 p-6 transition hover:-translate-y-2 hover:bg-card sm:p-8 ${platform.bg}`}>
              <div className="absolute right-4 top-4">
                <span className={`rounded-full border px-2 py-0.5 text-[10px] font-semibold ${platform.status === "Live" ? "border-green-500/25 bg-green-500/15 text-green-400" : "border-amber-500/25 bg-amber-500/15 text-amber-400"}`}>
                  {platform.status}
                </span>
              </div>
              <div className={`mb-5 grid size-14 place-items-center rounded-lg border ${platform.bg}`}>
                <platform.icon className={`size-7 ${platform.color}`} />
              </div>
              <h3 className="mb-1 text-xl font-bold text-foreground">{platform.name}</h3>
              <p className="mb-5 text-sm text-muted-foreground">{platform.sub}</p>
              <ul className="space-y-2">
                {platform.features.map((feature) => (
                  <li key={feature} className="flex items-center gap-2.5">
                    <span className="grid size-4 flex-shrink-0 place-items-center rounded-full border border-green-500/20 bg-green-500/15">
                      <Check className="size-2.5 text-green-400" />
                    </span>
                    <span className="text-sm text-muted-foreground">{feature}</span>
                  </li>
                ))}
              </ul>
              {"appStore" in platform && platform.appStore ? (
                <AppStoreButton className="mt-6 w-full px-5 py-3" />
              ) : null}
            </div>
          ))}
        </div>
        <div className="text-center">
          <h3 className="mb-3 text-2xl font-extrabold text-foreground sm:text-3xl">
            Mix any media into <span className="gradient-text">one MP4 file</span>
          </h3>
          <p className="mx-auto mb-8 max-w-xl text-sm text-muted-foreground sm:text-base">
            Combine a still photo, a video clip, and a backing audio track. Stillora renders it all into one polished export.
          </p>
          <div className="mx-auto grid max-w-3xl grid-cols-1 gap-4 sm:grid-cols-3">
            {[
              { icon: ImageIcon, label: "Images", desc: "JPEG, PNG and WebP", color: "text-violet-300", bg: "from-violet-500/20 to-purple-600/20 border-violet-500/20" },
              { icon: Film, label: "Video clips", desc: "MP4, MOV and AVI", color: "text-blue-300", bg: "from-blue-500/20 to-cyan-600/20 border-blue-500/20" },
              { icon: Music, label: "Audio tracks", desc: "MP3, WAV, M4A, AAC and OGG", color: "text-pink-300", bg: "from-pink-500/20 to-rose-600/20 border-pink-500/20" },
            ].map((item) => (
              <div key={item.label} className={`rounded-lg border bg-gradient-to-br p-5 text-center ${item.bg}`}>
                <item.icon className={`mx-auto mb-3 size-8 ${item.color}`} />
                <p className={`mb-1 text-base font-bold ${item.color}`}>{item.label}</p>
                <p className="font-mono text-xs text-muted-foreground">{item.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
