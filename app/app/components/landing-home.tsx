import { AppNavbar } from "@/app/components/app-navbar";
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
        <SocialProof />
        <FinalCta />
      </main>
      <Footer />
    </div>
  );
}
