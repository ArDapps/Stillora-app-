import Link from "next/link";
import { ANALYTICS_RANGES, type AnalyticsRange } from "@/lib/analytics-store";

/**
 * Date-range switcher for the Analytics page. Renders as a segmented control of
 * links; picking a range resets pagination back to page 1.
 */
export function RangeTabs({
  basePath,
  active,
}: {
  basePath: string;
  active: AnalyticsRange;
}) {
  return (
    <div
      className="inline-flex rounded-lg border p-0.5"
      style={{ borderColor: "var(--color-border)", background: "var(--color-card)" }}
    >
      {ANALYTICS_RANGES.map(({ key, label }) => {
        const isActive = key === active;
        return (
          <Link
            key={key}
            href={`${basePath}?range=${key}`}
            className="rounded-md px-3 py-1.5 text-xs font-semibold transition"
            style={
              isActive
                ? { background: "var(--color-primary)", color: "#fff" }
                : { color: "var(--color-muted)" }
            }
          >
            {label}
          </Link>
        );
      })}
    </div>
  );
}
