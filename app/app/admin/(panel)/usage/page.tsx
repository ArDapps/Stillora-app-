import {
  Activity,
  Clapperboard,
  Crown,
  Smartphone,
  Sparkles,
  Timer,
} from "lucide-react";

import {
  getAnalyticsOverview,
  getCountryPage,
  getDeviceUsage,
  getPlatformStats,
  getRecentSessions,
  getScreenPage,
  normalizeRange,
} from "@/lib/analytics-store";

import { Pagination } from "../pagination";
import { RangeTabs } from "../range-tabs";
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
  fmtDate,
  fmtDuration,
  fmtNumber,
  screenLabel,
  shortId,
} from "../ui";

export const dynamic = "force-dynamic";

const BASE = "/admin/usage";
const PAGE_SIZE = 25;
// Ranked lists are read at a glance; a short page keeps the card compact.
const RANK_PAGE_SIZE = 10;

export default async function AdminUsagePage({
  searchParams,
}: {
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}) {
  const sp = await searchParams;
  const rangeRaw = first(sp.range);
  const devicesPageRaw = first(sp.dp);
  const sessionsPageRaw = first(sp.sp);
  const countriesPageRaw = first(sp.cp);
  const screensPageRaw = first(sp.scp);
  const range = normalizeRange(rangeRaw);

  const [overview, devices, sessions, countries, platforms, screens] = await Promise.all([
    getAnalyticsOverview(range),
    getDeviceUsage(range, toInt(devicesPageRaw), PAGE_SIZE),
    getRecentSessions(range, toInt(sessionsPageRaw), PAGE_SIZE),
    getCountryPage(range, toInt(countriesPageRaw), RANK_PAGE_SIZE),
    getPlatformStats(range),
    getScreenPage(range, toInt(screensPageRaw), RANK_PAGE_SIZE),
  ]);

  // Every pager keeps the others' pages and the range in the URL.
  const shared = {
    range,
    dp: devicesPageRaw,
    sp: sessionsPageRaw,
    cp: countriesPageRaw,
    scp: screensPageRaw,
  };

  return (
    <>
      <PageHeader
        title="Usage"
        subtitle="Who is using Stillora, from where, for how long — tracked per device, never per account."
      >
        <LiveDot label={`${fmtNumber(overview.activeNow)} active now`} />
        <RangeTabs basePath={BASE} active={range} />
      </PageHeader>

      <div className="grid grid-cols-2 gap-3 lg:grid-cols-3 xl:grid-cols-6">
        <StatCard icon={Smartphone} label="Devices" value={overview.devices} hint="distinct installs" />
        <StatCard icon={Sparkles} label="New devices" value={overview.newDevices} hint="first seen in range" />
        <StatCard icon={Activity} label="Sessions" value={overview.totalSessions} hint={`${fmtNumber(overview.sessionsToday)} today`} tone="secondary" />
        <StatCard icon={Timer} label="Time in app" value={fmtDuration(overview.totalUsageSeconds)} tone="secondary" />
        <StatCard icon={Timer} label="Avg session" value={fmtDuration(overview.avgSessionSeconds)} tone="secondary" />
        <StatCard icon={Crown} label="Pro devices" value={overview.proDevices} tone="success" />
      </div>

      <Section title="Time used per device" hint={`${fmtNumber(devices.total)} devices in range`}>
        {devices.rows.length === 0 ? (
          <Empty text="No usage in this range yet." />
        ) : (
          <>
            <Table
              headers={["Device", "Platforms", "Location", "Sessions", "Exports", "Total time", "First seen", "Last seen"]}
            >
              {devices.rows.map((device) => (
                <Row key={device.deviceId}>
                  <Cell mono>
                    <span className="inline-flex items-center gap-2">
                      {shortId(device.deviceId)}
                      {device.isPro ? <Badge tone="success">Pro</Badge> : null}
                    </span>
                  </Cell>
                  <Cell>
                    <span className="flex flex-wrap gap-1">
                      {device.platforms.map((platform) => (
                        <Badge key={platform}>
                          <PlatformTag platform={platform} />
                        </Badge>
                      ))}
                    </span>
                  </Cell>
                  <Cell muted nowrap>
                    {device.country
                      ? `${flagEmoji(device.countryCode)} ${[device.city, device.country].filter(Boolean).join(", ")}`
                      : "Unknown"}
                  </Cell>
                  <Cell muted>{fmtNumber(device.sessions)}</Cell>
                  <Cell>
                    <span className="font-semibold tabular-nums" style={{ color: "var(--color-primary)" }}>
                      {fmtNumber(device.exports)}
                    </span>
                  </Cell>
                  <Cell nowrap>
                    <span className="font-semibold tabular-nums" style={{ color: "var(--color-secondary)" }}>
                      {fmtDuration(device.totalSeconds)}
                    </span>
                  </Cell>
                  <Cell muted nowrap>{fmtDate(device.firstSeen)}</Cell>
                  <Cell muted nowrap>{fmtAgo(device.lastSeen)}</Cell>
                </Row>
              ))}
            </Table>
            <Pagination
              basePath={BASE}
              params={{ ...shared, dp: undefined }}
              pageParam="dp"
              page={devices.page}
              pageSize={devices.pageSize}
              total={devices.total}
            />
          </>
        )}
      </Section>

      <div className="grid gap-6 lg:grid-cols-2">
        <Section title="Countries" hint={`${fmtNumber(countries.total)} total`}>
          <Card>
            <BarList
              emptyText="No location data yet."
              rows={countries.rows.map((country) => ({
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
            <Pagination
              basePath={BASE}
              params={{ ...shared, cp: undefined }}
              pageParam="cp"
              page={countries.page}
              pageSize={countries.pageSize}
              total={countries.total}
            />
          </Card>
        </Section>

        <div className="space-y-6">
          <Section title="Platforms">
            <Card>
              <BarList
                tone="secondary"
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

          <Section title="Screens & features" hint={`${fmtNumber(screens.total)} total`}>
            <Card>
              <BarList
                emptyText="No screen views in this range yet."
                rows={screens.rows.map((screen) => ({
                  key: screen.screen,
                  label: <span className="font-mono text-xs">{screenLabel(screen.screen)}</span>,
                  value: screen.views,
                  meta: `${fmtNumber(screen.views)} views · ${fmtNumber(screen.devices)} devices`,
                }))}
              />
              <Pagination
                basePath={BASE}
                params={{ ...shared, scp: undefined }}
                pageParam="scp"
                page={screens.page}
                pageSize={screens.pageSize}
                total={screens.total}
              />
            </Card>
          </Section>
        </div>
      </div>

      <Section title="Sessions" hint={`${fmtNumber(sessions.total)} in range`}>
        {sessions.rows.length === 0 ? (
          <Empty text="No sessions recorded yet. Open the app to generate the first one." />
        ) : (
          <>
            <Table headers={["Device", "Platform", "Location", "Hardware", "Duration", "Last seen"]}>
              {sessions.rows.map((session) => (
                <Row key={session.id}>
                  <Cell mono>
                    <span className="inline-flex items-center gap-2">
                      {session.active ? (
                        <span
                          title="Active"
                          className="inline-block size-2 shrink-0 rounded-full"
                          style={{ background: "var(--color-success)" }}
                        />
                      ) : null}
                      {shortId(session.deviceId)}
                      {session.isPro ? <Badge tone="success">Pro</Badge> : null}
                    </span>
                  </Cell>
                  <Cell>
                    <Badge>
                      <PlatformTag platform={session.platform} />
                    </Badge>
                  </Cell>
                  <Cell muted nowrap>
                    {session.country
                      ? `${flagEmoji(session.countryCode)} ${[session.city, session.country].filter(Boolean).join(", ")}`
                      : "Unknown"}
                  </Cell>
                  <Cell muted>
                    {[session.os, session.browser].filter(Boolean).join(" · ") || session.device || "—"}
                    {session.appVersion ? ` · v${session.appVersion}` : ""}
                  </Cell>
                  <Cell nowrap>
                    <span className="font-medium tabular-nums" style={{ color: "var(--color-secondary)" }}>
                      {fmtDuration(session.durationSeconds)}
                    </span>
                  </Cell>
                  <Cell muted nowrap>{fmtAgo(session.lastSeenAt)}</Cell>
                </Row>
              ))}
            </Table>
            <Pagination
              basePath={BASE}
              params={{ ...shared, sp: undefined }}
              pageParam="sp"
              page={sessions.page}
              pageSize={sessions.pageSize}
              total={sessions.total}
            />
          </>
        )}
      </Section>
    </>
  );
}

/** Search-param values can be string | string[]; take the first string. */
function first(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

function toInt(value: string | undefined): number {
  const n = value ? parseInt(value, 10) : 1;
  return Number.isFinite(n) && n >= 1 ? n : 1;
}
