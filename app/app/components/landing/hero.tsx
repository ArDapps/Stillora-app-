import { ArrowRight, Film, ImageIcon, Music, Play, Upload, Wand2 } from "lucide-react";
import { PrimaryCta } from "@/app/components/app-navbar";
import { AppMockup } from "./app-mockup";
import { SocialBadge } from "./shared";
import { platforms } from "./data";

export function Hero() {
  return (
    <section className="relative overflow-hidden pb-16 pt-28 sm:pb-24 sm:pt-36">
      <div className="pointer-events-none absolute inset-0 overflow-hidden">
        <div className="animate-orb absolute left-1/2 top-0 h-[500px] w-[900px] -translate-x-1/2 rounded-full bg-primary/15 blur-[140px]" />
        <div className="animate-orb-reverse absolute left-1/4 top-1/4 h-[300px] w-[400px] rounded-full bg-accent/10 blur-[100px]" />
        <div
          className="absolute inset-0 opacity-[0.035]"
          style={{
            backgroundImage:
              "linear-gradient(var(--color-border-subtle) 1px, transparent 1px), linear-gradient(90deg, var(--color-border-subtle) 1px, transparent 1px)",
            backgroundSize: "64px 64px",
          }}
        />
      </div>

      <div className="relative z-10 mx-auto grid w-full max-w-7xl grid-cols-1 items-center gap-12 px-4 sm:px-6 lg:grid-cols-2 lg:gap-16">
        <div className="text-center lg:text-left">
          <div className="mb-5 inline-flex items-center gap-2 rounded-full border border-primary/20 bg-primary/10 px-3 py-1.5 text-primary">
            <Wand2 className="size-3.5" />
            <span className="text-xs font-semibold tracking-wide">Free - Web - Mobile - Desktop soon</span>
          </div>
          <h1 className="mb-5 text-4xl font-extrabold leading-[1.08] tracking-tight text-foreground sm:text-5xl md:text-6xl lg:text-5xl xl:text-6xl">
            Mix images, video and audio into one <span className="gradient-text-animated">polished MP4</span>
          </h1>
          <p className="mx-auto mb-6 max-w-lg text-base leading-relaxed text-muted-foreground sm:text-lg lg:mx-0">
            Stillora combines still images, video clips, and audio tracks into a single export-ready video formatted for Reels, Shorts, TikTok, YouTube, and more.
          </p>
          <div className="mb-6 flex flex-wrap items-center justify-center gap-1.5 rounded-full border border-border/60 bg-card/80 px-3 py-1.5 backdrop-blur-sm lg:inline-flex">
            {[
              { icon: ImageIcon, label: "Images" },
              { icon: Film, label: "Video clips" },
              { icon: Music, label: "Audio tracks" },
            ].map((item) => (
              <span key={item.label} className="flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-semibold text-muted-foreground">
                <item.icon className="size-3" />
                {item.label}
              </span>
            ))}
            <span className="ml-1 text-[10px] text-muted-foreground/70">to MP4</span>
          </div>
          <div className="mb-8 flex items-center justify-center gap-3 lg:justify-start">
            <span className="text-xs font-medium text-muted-foreground">Works for</span>
            <div className="flex items-center gap-2">
              {platforms.slice(0, 3).map((platform) => (
                <SocialBadge key={platform.name} {...platform} label={platform.name} size="sm" />
              ))}
              <span className="ml-1 text-xs text-muted-foreground">and more</span>
            </div>
          </div>
          <div className="flex flex-col items-center justify-center gap-3 sm:flex-row lg:justify-start">
            <PrimaryCta className="w-full py-4 text-base sm:w-auto">
              <Upload className="mr-2 size-4" />
              Start Free - No Sign-up
              <ArrowRight className="ml-2 size-4" />
            </PrimaryCta>
            <a
              href="#formats"
              className="inline-flex w-full items-center justify-center rounded-full border border-border/60 px-7 py-4 text-base font-semibold text-foreground transition hover:bg-foreground/5 sm:w-auto"
            >
              <Play className="mr-2 size-4 fill-primary text-primary" />
              Watch Demo
            </a>
          </div>
          <p className="mt-5 text-xs text-muted-foreground">
            100% free - Web, mobile and desktop - No watermark - No account needed
          </p>
        </div>

        <div className="flex justify-center">
          <AppMockup />
        </div>
      </div>

      <div className="mx-auto mt-16 grid max-w-3xl grid-cols-2 gap-4 px-4 sm:mt-20 md:grid-cols-4">
        {[
          ["Free", "Always, no paywall"],
          ["3-in-1", "Images, video, audio"],
          ["5 formats", "Platform presets"],
          ["Web + App", "Desktop coming soon"],
        ].map(([value, label]) => (
          <div key={label} className="rounded-lg border border-border/60 bg-card/60 p-4 text-center backdrop-blur-sm">
            <div className="gradient-text mb-0.5 text-xl font-extrabold sm:text-2xl">{value}</div>
            <div className="text-xs text-muted-foreground">{label}</div>
          </div>
        ))}
      </div>
    </section>
  );
}
