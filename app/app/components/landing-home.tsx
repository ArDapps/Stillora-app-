import "@/app/landing-design.css";
import { DesignNav } from "./landing/design/nav";
import { DesignAura, DesignHero } from "./landing/design/hero";
import {
  MediaCards,
  Pillars,
  PlatformCards,
  Presets,
  Steps,
  TrustStrip,
} from "./landing/design/sections-top";
import { Availability, FeatureGrid } from "./landing/design/availability";
import { Faq, Testimonials } from "./landing/design/proof";
import { DesignFooter, FinalCta } from "./landing/design/final-footer";

export function LandingHome() {
  return (
    <>
      <DesignAura />
      <DesignNav />
      <main id="top">
        <DesignHero />
        <TrustStrip />
        <Pillars />
        <MediaCards />
        <Steps />
        <Presets />
        <PlatformCards />
        <Availability />
        <FeatureGrid />
        <Testimonials />
        <Faq />
        <FinalCta />
      </main>
      <DesignFooter />
    </>
  );
}
