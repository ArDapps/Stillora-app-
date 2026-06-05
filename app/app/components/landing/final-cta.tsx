import { ArrowRight } from "lucide-react";
import Link from "next/link";
import { EDITOR_PATH } from "@/lib/site";

export function FinalCta() {
  return (
    <section className="border-t border-[var(--color-border)]">
      <div className="mx-auto w-full max-w-7xl px-5 py-20">
        <div className="relative overflow-hidden rounded-3xl border border-[var(--color-border)] bg-[var(--color-card)] px-6 py-14 text-center shadow-sm sm:px-12">
          <div
            aria-hidden
            className="landing-hero-glow pointer-events-none absolute inset-0"
            style={{ background: "var(--landing-cta-glow)" }}
          />
          <div className="relative">
            <h2 className="mx-auto max-w-2xl text-3xl font-semibold tracking-tight sm:text-4xl">
              Turn your next image into a video
            </h2>
            <p className="mx-auto mt-4 max-w-xl text-lg text-[var(--color-muted)]">
              Create a ready-to-post MP4 for Reels, TikTok, YouTube, and more. No complicated editor
              required.
            </p>
            <Link
              href={EDITOR_PATH}
              className="mt-8 inline-flex items-center gap-2 rounded-md bg-[var(--color-primary)] px-7 py-3 text-base font-semibold text-[var(--color-primary-text)] shadow-sm shadow-[var(--shadow-primary)] transition hover:bg-[var(--color-primary-hover)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)] focus-visible:ring-offset-2 focus-visible:ring-offset-[var(--color-background)]"
            >
              Create your video — free
              <ArrowRight size={18} />
            </Link>
          </div>
        </div>
      </div>
    </section>
  );
}
