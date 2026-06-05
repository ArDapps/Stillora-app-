import { Faq } from "@/app/components/landing/faq";
import { Features } from "@/app/components/landing/features";
import { FinalCta } from "@/app/components/landing/final-cta";
import { Formats } from "@/app/components/landing/formats";
import { Hero } from "@/app/components/landing/hero";
import { HowItWorks } from "@/app/components/landing/how-it-works";
import { LandingJsonLd } from "@/app/components/landing/json-ld";
import { SiteFooter } from "@/app/components/landing/site-footer";
import { TrustStrip } from "@/app/components/landing/trust-strip";
import { UseCases } from "@/app/components/landing/use-cases";
import { SiteHeader } from "@/app/components/site-header";

export default function Landing() {
  return (
    <div className="landing-shell relative min-h-screen overflow-hidden bg-[var(--color-background)] text-[var(--color-foreground)]">
      <LandingJsonLd />
      <div className="relative z-10">
        <SiteHeader showNav showCta />

        <main id="main" className="pt-20">
          <Hero />
          <TrustStrip />
          <Formats />
          <UseCases />
          <Features />
          <HowItWorks />
          <Faq />
          <FinalCta />
        </main>

        <SiteFooter />
      </div>
    </div>
  );
}
