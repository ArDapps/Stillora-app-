import {
  getExportStats,
  getExportsPage,
  getPresetStats,
  getToolStats,
} from "@/lib/admin-store";
import { normalizeRange } from "@/lib/analytics-store";
import { Clapperboard, Film, Smartphone, Sparkles, Timer } from "lucide-react";

import { Pagination } from "../pagination";
import { RangeTabs } from "../range-tabs";
import {
  Badge,
  BarList,
  Card,
  Cell,
  Empty,
  PageHeader,
  PlatformTag,
  Row,
  Section,
  StatCard,
  Table,
  fmtAgo,
  fmtDate,
  fmtDuration,
  fmtNumber,
  shortId,
  toolLabel,
} from "../ui";

export const dynamic = "force-dynamic";

const BASE = "/admin/exports";
const PAGE_SIZE = 25;

export default async function AdminExportsPage({
  searchParams,
}: {
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}) {
  const sp = await searchParams;
  const rangeRaw = Array.isArray(sp.range) ? sp.range[0] : sp.range;
  const pageRaw = Array.isArray(sp.page) ? sp.page[0] : sp.page;
  const range = normalizeRange(rangeRaw);
  const page = pageRaw ? parseInt(pageRaw, 10) : 1;

  const [stats, tools, presets, exports] = await Promise.all([
    getExportStats(range),
    getToolStats(range),
    getPresetStats(range, 10),
    getExportsPage(range, page, PAGE_SIZE),
  ]);

  return (
    <>
      <PageHeader
        title="Exports"
        subtitle="Every finished render, from every app — web, iOS, Android and desktop."
      >
        <RangeTabs basePath={BASE} active={range} />
      </PageHeader>

      <div className="grid grid-cols-2 gap-3 lg:grid-cols-3 xl:grid-cols-5">
        <StatCard icon={Clapperboard} label="In range" value={stats.inRange} tone="secondary" />
        <StatCard icon={Sparkles} label="Today" value={stats.today} tone="secondary" />
        <StatCard icon={Film} label="All time" value={stats.total} />
        <StatCard icon={Smartphone} label="Exporting devices" value={stats.devices} hint="in range" />
        <StatCard
          label="Video rendered"
          value={fmtDuration(stats.totalVideoSeconds)}
          hint={`avg ${fmtDuration(stats.avgDurationSeconds)} per export`}
          tone="success"
        />
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <Section title="By tool">
          <Card>
            <BarList
              tone="secondary"
              emptyText="No exports in this range yet."
              rows={tools.map((tool) => ({
                key: tool.tool,
                label: toolLabel(tool.tool),
                value: tool.exports,
                meta: `${fmtNumber(tool.exports)} · ${fmtNumber(tool.devices)} devices · ${fmtDuration(tool.videoSeconds)}`,
              }))}
            />
          </Card>
        </Section>

        <Section title="By output preset">
          <Card>
            <BarList
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

      <Section title="Export log" hint={`${fmtNumber(exports.total)} in range`}>
        {exports.rows.length === 0 ? (
          <Empty text="No exports recorded in this range." />
        ) : (
          <>
            <Table headers={["Device", "Tool", "Platform", "Preset", "Length", "When", "Exact time"]}>
              {exports.rows.map((row) => (
                <Row key={row.id}>
                  <Cell mono muted>{shortId(row.deviceId)}</Cell>
                  <Cell>
                    <Badge tone="secondary">{toolLabel(row.tool)}</Badge>
                  </Cell>
                  <Cell muted>
                    {row.platform ? <PlatformTag platform={row.platform} /> : "—"}
                  </Cell>
                  <Cell muted mono>{row.presetId}</Cell>
                  <Cell nowrap>
                    <span className="font-medium tabular-nums" style={{ color: "var(--color-secondary)" }}>
                      {fmtDuration(row.duration)}
                    </span>
                  </Cell>
                  <Cell muted nowrap>{fmtAgo(row.timestamp)}</Cell>
                  <Cell muted nowrap>{fmtDate(row.timestamp)}</Cell>
                </Row>
              ))}
            </Table>
            <Pagination
              basePath={BASE}
              params={{ range }}
              page={exports.page}
              pageSize={exports.pageSize}
              total={exports.total}
            />
          </>
        )}
      </Section>
    </>
  );
}
