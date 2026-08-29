import type { DayPoint } from "@/lib/analytics-store";

import { fmtNumber } from "./ui";

const HEIGHT = 132;
const GAP = 3;

/**
 * Fourteen-ish days of activity as paired bars: sessions behind, exports in
 * front. Inline SVG on purpose — the panel ships no chart library, and a bar
 * per day is the whole requirement.
 *
 * Both series share one scale so the two bars in a day are directly comparable;
 * a day with traffic but no exports is then obvious at a glance.
 */
export function TrendChart({ points }: { points: DayPoint[] }) {
  if (points.length === 0) {
    return (
      <p className="py-10 text-center text-sm" style={{ color: "var(--color-muted)" }}>
        No activity recorded yet.
      </p>
    );
  }

  const max = Math.max(1, ...points.map((p) => Math.max(p.sessions, p.exports)));
  const totalSessions = points.reduce((sum, p) => sum + p.sessions, 0);
  const totalExports = points.reduce((sum, p) => sum + p.exports, 0);

  return (
    <div>
      <div className="mb-4 flex flex-wrap items-center gap-4 text-xs">
        <Legend color="var(--color-primary)" label={`${fmtNumber(totalSessions)} sessions`} />
        <Legend color="var(--color-secondary)" label={`${fmtNumber(totalExports)} exports`} />
        <span className="ml-auto tabular-nums" style={{ color: "var(--color-muted)" }}>
          peak {fmtNumber(max)}/day
        </span>
      </div>

      <div className="flex items-end gap-[3px]" style={{ height: HEIGHT }} role="img"
        aria-label={`Daily activity: ${fmtNumber(totalSessions)} sessions and ${fmtNumber(totalExports)} exports over ${points.length} days.`}>
        {points.map((point) => (
          <div key={point.day} className="flex h-full min-w-0 flex-1 flex-col justify-end">
            <div className="flex h-full items-end justify-center" style={{ gap: GAP }}>
              <Bar
                height={(point.sessions / max) * 100}
                color="var(--color-primary)"
                title={`${point.day}: ${point.sessions} sessions`}
              />
              <Bar
                height={(point.exports / max) * 100}
                color="var(--color-secondary)"
                title={`${point.day}: ${point.exports} exports`}
              />
            </div>
          </div>
        ))}
      </div>

      <div className="mt-2 flex justify-between text-[11px]" style={{ color: "var(--color-muted)" }}>
        <span>{dayLabel(points[0].day)}</span>
        <span>{dayLabel(points[points.length - 1].day)}</span>
      </div>
    </div>
  );
}

function Bar({ height, color, title }: { height: number; color: string; title: string }) {
  return (
    <div
      title={title}
      className="w-full max-w-3 rounded-t-sm transition-all"
      style={{
        // A hairline for an empty day, so the axis still reads as a timeline.
        height: `${Math.max(1.5, height)}%`,
        background: height > 0 ? color : "var(--color-border)",
        opacity: height > 0 ? 1 : 0.5,
      }}
    />
  );
}

function Legend({ color, label }: { color: string; label: string }) {
  return (
    <span className="inline-flex items-center gap-1.5" style={{ color: "var(--color-muted)" }}>
      <span className="size-2 rounded-sm" style={{ background: color }} />
      {label}
    </span>
  );
}

function dayLabel(day: string): string {
  return new Date(`${day}T00:00:00Z`).toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    timeZone: "UTC",
  });
}
