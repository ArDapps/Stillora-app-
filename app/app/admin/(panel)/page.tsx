import {
  getExportStats,
  getPresetStats,
  getRecentExports,
  getToolStats,
} from "@/lib/admin-store";
import {
  getAnalyticsOverview,
  getCountryStats,
  getDailySeries,
  getPlatformStats,
  getTopScreens,
  normalizeRange,
} from "@/lib/analytics-store";
import { getErrorStats, getRecentErrors } from "@/lib/error-log";
import {
  AlertTriangle,
  Clapperboard,
  Crown,
  Layers,
  Smartphone,
  Timer,
} from "lucide-react";

import { RangeTabs } from "./range-tabs";
import { TrendChart } from "./trend-chart";
import {
  Badge,
  BarList,
  Card,
  Cell,
  Empty,
  LiveDot,
  PageHeader,
  PlatformTag,
  Row,
  Section,
  StatCard,
  Table,
  flagEmoji,
  fmtAgo,
  fmtDuration,
  fmtNumber,
  screenLabel,
  shortId,
  toolLabel,
} from "./ui";

export const dynamic = "force-dynamic";

const BASE = "/admin";
const TREND_DAYS = 14;

export default async function AdminOverview({
  searchParams,
}: {
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}) {
  const sp = await searchParams;
  const rangeRaw = Array.isArray(sp.range) ? sp.range[0] : sp.range;
  const range = normalizeRange(rangeRaw);

  const [
    overview,
    exports,
    trend,
    tools,
    presets,
    platforms,
    countries,
    screens,
    recentExports,
    errorStats,
    recentErrors,
  ] = await Promise.all([
    getAnalyticsOverview(range),
    getExportStats(range),
    getDailySeries(TREND_DAYS),
    getToolStats(range),
    getPresetStats(range, 6),
    getPlatformStats(range),
    getCountryStats(range, 6),
    getTopScreens(range, 6),
    getRecentExports(8),
    getErrorStats(),
    getRecentErrors(4),
  ]);

  return (
    <>
      <PageHeader
        title="Overview"
        subtitle="Stillora has no accounts — every number here is counted per device."
      >
        <LiveDot label={`${fmtNumber(overview.activeNow)} active now`} />
        <RangeTabs basePath={BASE} active={range} />
      </PageHeader>

      <div className="grid grid-cols-2 gap-3 lg:grid-cols-3 xl:grid-cols-6">
        <StatCard
          label="Devices"
          icon={Smartphone}
          value={overview.devices}
          hint={`${fmtNumber(overview.newDevices)} new`}
          tone="primary"
          href="/admin/usage"
        />
        <StatCard
          label="Sessions"
          icon={Layers}
          value={overview.totalSessions}
          hint={`${fmtNumber(overview.sessionsToday)} today`}
          tone="primary"
          href="/admin/usage"
        />
        <StatCard
          label="Exports"
          icon={Clapperboard}
          value={exports.inRange}
          hint={`${fmtNumber(exports.today)} today · ${fmtNumber(exports.total)} all time`}
          tone="secondary"
          href="/admin/exports"
        />
        <StatCard
          label="Time in app"
          icon={Timer}
          value={fmtDuration(overview.totalUsageSeconds)}
          hint={`avg ${fmtDuration(overview.avgSessionSeconds)} / session`}
          tone="secondary"
        />
        <StatCard
          label="Pro devices"
          icon={Crown}
          value={overview.proDevices}
          hint={overview.devices > 0 ? `${pct(overview.proDevices, overview.devices)} of devices` : "no data yet"}
          tone="success"
        />
        <StatCard
          label="Open errors"
          icon={AlertTriangle}
          value={errorStats.open}
          hint={errorStats.open > 0 ? `${fmtNumber(errorStats.totalOccurrences)} occurrences` : "all clear"}
          tone={errorStats.open > 0 ? "danger" : "neutral"}
          href="/admin/errors"
        />
      </div>

      <Section title={`Last ${TREND_DAYS} days`} hint="sessions vs exports, per day">
        <Card>
          <TrendChart points={trend} />
        </Card>
      </Section>

      {recentErrors.length > 0 ? (
        <Section title="Needs attention" action={{ href: "/admin/errors", label: "All errors" }}>
          <Card padded={false}>
            <ul>
              {recentErrors.map((error) => (
                <li
                  key={error.id}
                  className="flex flex-wrap items-center gap-x-3 gap-y-1 px-5 py-3"
                  style={{ borderBottom: "1px solid var(--color-border-subtle)" }}
                >
                  <Badge tone="danger">×{fmtNumber(error.count)}</Badge>
                  <span className="font-mono text-xs" style={{ color: "var(--color-secondary)" }}>
                    {error.source}
                  </span>
                  <span className="min-w-0 flex-1 truncate text-sm" style={{ color: "var(--color-foreground)" }}>
                    {error.message}
                  </span>
                  <span className="text-xs" style={{ color: "var(--color-muted)" }}>
                    {fmtAgo(error.lastSeen)}
                  </span>
                </li>
              ))}
            </ul>
          </Card>
        </Section>
      ) : null}

      <div className="grid gap-6 lg:grid-cols-2">
        <Section title="Exports by tool" action={{ href: "/admin/exports", label: "Details" }}>
          <Card>
            <BarList
              tone="secondary"
              emptyText="No exports in this range yet."
              rows={tools.map((tool) => ({
                key: tool.tool,
                label: toolLabel(tool.tool),
                value: tool.exports,
                meta: `${fmtNumber(tool.exports)} · ${fmtNumber(tool.devices)} devices`,
              }))}
            />
          </Card>
        </Section>

        <Section title="Platforms" action={{ href: "/admin/usage", label: "Details" }}>
          <Card>
            <BarList
              emptyText="No sessions in this range yet."
              rows={platforms.map((platform) => ({
                key: platform.platform,
                label: <PlatformTag platform={platform.platform} />,
                value: platform.sessions,
                meta: `${fmtNumber(platform.devices)} devices · ${fmtDuration(platform.usageSeconds)}`,
              }))}
            />
          </Card>
        </Section>

        <Section title="Top countries" action={{ href: "/admin/usage", label: "Details" }}>
          <Card>
            <BarList
              emptyText="No location data yet."
              rows={countries.map((country) => ({
                key: `${country.country}-${country.countryCode}`,
                label: (
                  <span className="inline-flex items-center gap-2">
                    <span aria-hidden>{flagEmoji(country.countryCode)}</span>
                    {country.country}
                  </span>
                ),
                value: country.sessions,
                meta: `${fmtNumber(country.devices)} devices · ${fmtDuration(country.usageSeconds)}`,
              }))}
            />
          </Card>
        </Section>

        <Section title="Most-opened screens" action={{ href: "/admin/usage", label: "Details" }}>
          <Card>
            <BarList
              emptyText="No screen views in this range yet."
              rows={screens.map((screen) => ({
                key: screen.screen,
                label: <span className="font-mono text-xs">{screenLabel(screen.screen)}</span>,
                value: screen.views,
                meta: `${fmtNumber(screen.views)} views · ${fmtNumber(screen.devices)} devices`,
              }))}
            />
          </Card>
        </Section>
      </div>

      <div className="grid gap-6 lg:grid-cols-[2fr_1fr]">
        <Section title="Latest exports" action={{ href: "/admin/exports", label: "All exports" }}>
          {recentExports.length === 0 ? (
            <Empty text="No exports recorded yet. They appear here the moment any app finishes one." />
          ) : (
            <Table headers={["Device", "Tool", "Preset", "Length", "When"]}>
              {recentExports.map((row) => (
                <Row key={row.id}>
                  <Cell mono muted>{shortId(row.deviceId)}</Cell>
                  <Cell>
                    <Badge tone="secondary">{toolLabel(row.tool)}</Badge>
                  </Cell>
                  <Cell muted>{row.presetId}</Cell>
                  <Cell muted nowrap>{fmtDuration(row.duration)}</Cell>
                  <Cell muted nowrap>{fmtAgo(row.timestamp)}</Cell>
                </Row>
              ))}
            </Table>
          )}
        </Section>

        <Section title="Output presets" hint="in range">
          <Card>
            <BarList
              tone="secondary"
              emptyText="No exports in this range yet."
              rows={presets.map((preset) => ({
                key: preset.presetId,
                label: <span className="font-mono text-xs">{preset.presetId}</span>,
                value: preset.exports,
              }))}
            />
          </Card>
        </Section>
      </div>
    </>
  );
}

function pct(part: number, whole: number): string {
  if (whole <= 0) return "0%";
  return `${Math.round((part / whole) * 100)}%`;
}
