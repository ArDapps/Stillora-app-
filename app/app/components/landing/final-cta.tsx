import { ArrowRight, Check } from "lucide-react";
import Image from "next/image";
import { PrimaryCta } from "@/app/components/app-navbar";
import stilloraIcon from "@/public/logo/stillora-icon.svg";
import { ctaPerks } from "./data";

export function FinalCta() {
  return (
    <section className="relative overflow-hidden py-20 sm:py-28">
      <div className="mx-auto w-full max-w-7xl px-4 sm:px-6">
        <div className="gradient-border mx-auto max-w-4xl rounded-lg">
          <div className="relative overflow-hidden rounded-lg bg-card/90 p-8 text-center backdrop-blur-xl sm:p-12 md:p-16">
            <div className="animate-float mx-auto mb-6 grid size-16 place-items-center rounded-lg bg-[image:var(--brand-mark)] shadow-2xl shadow-primary/40 sm:mb-8 sm:size-20">
              <Image
                src={stilloraIcon}
                alt="Stillora"
                width={48}
                height={29}
                className="size-9 object-contain sm:size-11"
              />
            </div>
            <h2 className="mb-4 text-3xl font-extrabold text-foreground sm:text-4xl md:text-5xl">
              Start creating for <span className="gradient-text-animated">free today</span>
            </h2>
            <p className="mx-auto mb-8 max-w-2xl text-base text-muted-foreground sm:text-lg md:text-xl">
              Mix images, video clips, and audio tracks into platform-ready MP4s. Web and mobile app are available now.
            </p>
            <div className="mx-auto mb-8 grid max-w-xl grid-cols-1 gap-2 text-left sm:grid-cols-2 sm:gap-3">
              {ctaPerks.map((perk) => (
                <div key={perk} className="flex items-center gap-2.5">
                  <span className="grid size-5 flex-shrink-0 place-items-center rounded-full border border-green-500/30 bg-green-500/20">
                    <Check className="size-3 text-green-400" />
                  </span>
                  <span className="text-sm text-muted-foreground">{perk}</span>
                </div>
              ))}
            </div>
            <PrimaryCta className="px-10 py-4 text-base sm:px-12 sm:text-lg">
              Start Free
              <ArrowRight className="ml-3 size-5" />
            </PrimaryCta>
          </div>
        </div>
      </div>
    </section>
  );
}
