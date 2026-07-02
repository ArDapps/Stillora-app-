import type { Metadata } from "next";
import { LegalDocument } from "@/app/components/legal-document";

export const metadata: Metadata = {
  title: "Delete Account",
  description: "How to delete your Stillora account and associated data.",
};

const sections = [
  {
    title: "Delete your account in the app",
    body: [
      "Open Stillora, sign in, go to Settings, then choose Delete account. Confirm the prompt to permanently delete your account and associated server-side data.",
      "The mobile app includes this deletion flow so signed-in users can request deletion directly without contacting support.",
    ],
  },
  {
    title: "What is deleted",
    body: [
      "Account deletion removes your Stillora account record, authentication tokens, saved project records, and associated server-side account data.",
      "Files that you exported or saved locally on your own device are not removed automatically because they are stored outside Stillora's server account system.",
    ],
  },
  {
    title: "Need help",
    body: [
      "If you cannot access your account in the app, contact Tecno Blocks at support@tecnoblocks.com and include the email address you used to sign in.",
    ],
  },
];

export default function DeleteAccountPage() {
  return (
    <LegalDocument
      title="Delete Account"
      intro="Stillora lets signed-in users permanently delete their account and associated data from inside the mobile app."
      sections={sections}
    />
  );
}
