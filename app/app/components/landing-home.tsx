import { AppNavbar } from "@/app/components/app-navbar";
import { AdSlot } from "@/app/components/ad-slot";
import { Hero } from "./landing/hero";
import { PlatformPresets } from "./landing/platform-presets";
import { CrossPlatform } from "./landing/cross-platform";
import { HowItWorks } from "./landing/how-it-works";
import { Formats } from "./landing/formats";
import { Features } from "./landing/features";
import { SocialProof } from "./landing/social-proof";
import { FinalCta } from "./landing/final-cta";
import { Footer } from "./landing/footer";

export function LandingHome() {
  return (
    <div className="min-h-screen overflow-hidden bg-background text-foreground">
      <AppNavbar />
      <main>
        <Hero />
        <PlatformPresets />
        <CrossPlatform />
        <HowItWorks />
        <Formats />
        <Features />
        <div className="mx-auto max-w-md px-4 py-6">
          <AdSlot placement="HOME_BANNER" />
        </div>
        <SocialProof />
        <FinalCta />
      </main>
      <Footer />
    </div>
  );
}
