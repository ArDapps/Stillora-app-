import type { Metadata } from "next";
import { LegalDocument } from "@/app/components/legal-document";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description: "Privacy Policy for the Stillora web and mobile apps.",
};

const sections = [
  {
    title: "What This Policy Covers",
    body: [
      "This Privacy Policy explains how Stillora handles information when you use the Stillora website, web editor, mobile apps, and related export services.",
      "Stillora is built by Tecno Blocks. The app helps you upload images, video clips, and audio tracks, then render them into share-ready MP4 files.",
    ],
  },
  {
    title: "Information We Collect",
    body: [
      "Stillora has no user accounts. There is nothing to sign up for and no sign-in, so we do not collect your name, email address, or profile image.",
      "Project and upload information may include the media files you upload, export settings, generated export records, and download information needed to provide the service.",
      "Technical information may include device type, browser, app version, IP address, local preferences, logs, and diagnostics used to keep the app reliable and secure.",
    ],
  },
  {
    title: "How We Use Information",
    body: [
      "We use information to process uploads, render exports, provide downloads, remember preferences, troubleshoot errors, prevent abuse, and improve Stillora.",
      "Uploaded media is used to create the exports you request. We do not claim ownership of your uploaded files or finished exports.",
    ],
  },
  {
    title: "Mobile App Permissions",
    body: [
      "The mobile apps may request access to photos, videos, files, camera, microphone, or storage only when those permissions are needed for importing media, recording content, saving exports, or sharing output.",
      "You can manage mobile permissions through your device settings. Disabling a permission may limit related app features.",
    ],
  },
  {
    title: "Sharing and Service Providers",
    body: [
      "We may share limited information with service providers that help operate hosting, file storage, rendering, analytics, security, and customer support.",
      "We may also disclose information if required by law, to protect rights and safety, or to investigate misuse of the service.",
    ],
  },
  {
    title: "Retention and Deletion",
    body: [
      "We keep information only as long as needed to provide Stillora, maintain records, comply with legal obligations, resolve disputes, and secure the service.",
      "Temporary uploaded media and rendered exports may be removed automatically. Because there is no account, there is no profile to delete: usage analytics are tied to a random per-install identifier, and uninstalling the app discards it.",
      "To ask about the anonymous usage data recorded for a device, contact us using the information below.",
    ],
  },
  {
    title: "Security",
    body: [
      "We use reasonable technical and organizational measures to protect information. No online service can guarantee absolute security, so use care when uploading sensitive media.",
    ],
  },
  {
    title: "Children",
    body: [
      "Stillora is not intended for children under 13. If you believe a child provided personal information through Stillora, contact us so we can review and delete it when appropriate.",
    ],
  },
  {
    title: "Contact",
    body: [
      "For privacy requests or questions, contact Tecno Blocks at support@tecnoblocks.com.",
    ],
  },
];

export default function PrivacyPage() {
  return (
    <LegalDocument
      title="Privacy Policy"
      intro="How Stillora handles data across the web editor, mobile apps, and export services."
      sections={sections}
    />
  );
}
