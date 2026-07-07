import { APP_STORE_URL, GOOGLE_PLAY_URL, MACOS_DOWNLOAD_URL, WINDOWS_DOWNLOAD_URL } from "@/lib/site";

type Kind = "apple" | "play" | "windows";

const ICON: Record<Kind, React.ReactNode> = {
  apple: (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M16.5 1.6c.1 1-.3 2-1 2.8-.7.8-1.8 1.4-2.8 1.3-.1-1 .4-2 1-2.7.7-.8 1.9-1.4 2.8-1.4zM19.9 17c-.5 1.2-.8 1.7-1.5 2.8-1 1.5-2.3 3.3-4 3.3-1.5 0-1.9-1-3.9-1-2 0-2.4 1-3.9 1-1.7 0-2.9-1.7-3.9-3.1C-.2 16.6-.4 11.8 1.4 9.2c1-1.4 2.5-2.3 4-2.3 1.5 0 2.5 1 3.8 1 1.2 0 2-1 3.8-1 1.3 0 2.7.7 3.7 2-3.2 1.8-2.7 6.4.2 8.1z" /></svg>
  ),
  play: (
    <svg width="19" height="19" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M3.6 1.8c-.3.2-.5.5-.5 1v18.4c0 .5.2.8.5 1l10.3-10.2L3.6 1.8zM16 8.2l-2.3 2.3 2.3 2.3 3.7-2.1c.7-.4.7-1.3 0-1.7L16 8.2zM4.7 1.3l9.6 5.5 2 1.2-2.6 2.6L4.7 1.3zm0 21.4l9-9 2.6 2.6-2 1.1-9.6 5.3z" /></svg>
  ),
  windows: (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M3 5.4l7.6-1V11H3V5.4zM3 12.6h7.6v6.6L3 18.2v-5.6zM11.5 4.3L21 3v8.4h-9.5V4.3zM11.5 12.6H21V21l-9.5-1.3v-7.1z" /></svg>
  ),
};

const HREF: Record<string, string> = {
  "dl-app-store": APP_STORE_URL,
  "dl-app-store-cta": APP_STORE_URL,
  "dl-macos": MACOS_DOWNLOAD_URL,
  "dl-google-play": GOOGLE_PLAY_URL,
  "dl-windows": WINDOWS_DOWNLOAD_URL,
};

/**
 * Store / installer link. Markup, `id` and `data-download` mirror the design
 * handoff exactly; the real URL is resolved by id (empty = "#" placeholder).
 */
export function AppStoreLink({
  id,
  data,
  kind,
  top,
  bottom,
  url: urlOverride,
}: {
  id: string;
  data: "ios" | "android" | "macos" | "windows";
  kind: Kind;
  top: string;
  bottom: string;
  /** Admin-managed URL. Falls back to the compile-time default when undefined. */
  url?: string;
}) {
  const url = urlOverride !== undefined ? urlOverride : HREF[id] || "";
  const live = url.length > 0;

  return (
    <a
      id={id}
      data-download={data}
      href={live ? url : "#"}
      {...(live ? { target: "_blank", rel: "noopener noreferrer" } : {})}
      className="appstore"
    >
      {ICON[kind]}
      <span>
        <span className="as-t">{top}</span>
        <br />
        <span className="as-b">{bottom}</span>
      </span>
    </a>
  );
}
