import type { Metadata } from "next";
import { LegalDocument } from "@/app/components/legal-document";

export const metadata: Metadata = {
  title: "Terms of Service",
  description: "Terms of Service for the Stillora web and mobile apps.",
};

const sections = [
  {
    title: "Agreement",
    body: [
      "These Terms of Service govern your use of Stillora, including the website, web editor, mobile apps, export tools, and related services.",
      "By using Stillora, you agree to these terms. If you do not agree, do not use the app.",
    ],
  },
  {
    title: "Using Stillora",
    body: [
      "Stillora lets you upload images, video clips, and audio tracks, choose format settings, and render MP4 exports for personal or commercial projects.",
      "You are responsible for your account, your uploads, your export settings, and your use of the finished files.",
    ],
  },
  {
    title: "Your Content",
    body: [
      "You keep ownership of the media you upload and the exports you create. You grant Stillora the limited permission needed to host, process, render, store, and deliver your files as part of the service.",
      "You must have the rights and permissions needed for any images, videos, audio, logos, names, or other content you upload.",
    ],
  },
  {
    title: "Acceptable Use",
    body: [
      "Do not use Stillora to upload or create content that is illegal, infringing, abusive, exploitative, deceptive, malicious, or harmful.",
      "Do not attempt to disrupt the service, bypass security, overload rendering systems, scrape private data, or use Stillora in a way that interferes with other users.",
    ],
  },
  {
    title: "Accounts and Access",
    body: [
      "Some features may work without an account, while others may require sign-in. You are responsible for keeping your sign-in method secure.",
      "We may suspend or restrict access if we believe an account or project violates these terms, creates risk, or harms the service.",
    ],
  },
  {
    title: "Availability and Changes",
    body: [
      "Stillora may change, pause, or discontinue features at any time. Web and mobile app features may differ by device, operating system, app version, region, and service availability.",
      "We may update these terms as Stillora evolves. Continued use after changes means you accept the updated terms.",
    ],
  },
  {
    title: "Disclaimers",
    body: [
      "Stillora is provided as is and as available. We do not guarantee uninterrupted service, perfect exports, compatibility with every platform, or that every upload can be processed.",
      "You are responsible for reviewing exports before publishing them and for following the rules of any platform where you post content.",
    ],
  },
  {
    title: "Limitation of Liability",
    body: [
      "To the maximum extent allowed by law, Tecno Blocks and Stillora are not liable for indirect, incidental, special, consequential, or punitive damages, or for lost profits, data, content, or business opportunities.",
    ],
  },
  {
    title: "Contact",
    body: [
      "For questions about these terms, contact Tecno Blocks at support@tecnoblocks.com.",
    ],
  },
];

export default function TermsPage() {
  return (
    <LegalDocument
      title="Terms of Service"
      intro="The rules for using Stillora across the web editor, mobile apps, and export services."
      sections={sections}
    />
  );
}
