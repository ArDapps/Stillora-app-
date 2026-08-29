import Link from "next/link";

import { AlertTriangle, Clock, Server, Smartphone } from "lucide-react";

import { getErrorsPage, getErrorStats, type ErrorFilter, type ErrorRecord } from "@/lib/error-log";

import { Pagination } from "../pagination";
import {
  Badge,
  Card,
  Empty,
  PageHeader,
  Section,
  StatCard,
  fmtAgo,
  fmtDate,
  fmtNumber,
  platformLabel,
  shortId,
} from "../ui";
import { ClearResolvedButton, ErrorRowActions } from "./error-actions";

export const dynamic = "force-dynamic";

const BASE = "/admin/errors";
const PAGE_SIZE = 25;

const FILTERS: { key: ErrorFilter; label: string }[] = [
  { key: "open", label: "Open" },
  { key: "resolved", label: "Resolved" },
  { key: "all", label: "All" },
];

function normalizeFilter(value: string | undefined): ErrorFilter {
  return value === "resolved" || value === "all" ? value : "open";
}

export default async function AdminErrorsPage({
  searchParams,
}: {
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}) {
  const sp = await searchParams;
  const filter = normalizeFilter(Array.isArray(sp.filter) ? sp.filter[0] : sp.filter);
  const pageRaw = Array.isArray(sp.page) ? sp.page[0] : sp.page;

  const [stats, errors] = await Promise.all([
    getErrorStats(),
    getErrorsPage(filter, pageRaw ? parseInt(pageRaw, 10) : 1, PAGE_SIZE),
  ]);

  const resolvedCount = filter === "resolved" ? errors.total : 0;

  return (
    <>
      <PageHeader
        title="Errors"
        subtitle="Anything that failed — a server route, a store function, or a crash inside one of the apps."
      >
        <ClearResolvedButton count={resolvedCount} />
        <FilterTabs active={filter} />
      </PageHeader>

      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <StatCard
          icon={AlertTriangle}
          label="Open"
          value={stats.open}
          tone={stats.open > 0 ? "danger" : "success"}
          hint={stats.open === 0 ? "nothing failing" : "unique failures"}
        />
        <StatCard icon={Clock} label="Seen in 24h" value={stats.last24h} tone={stats.last24h > 0 ? "danger" : "neutral"} />
        <StatCard icon={Server} label="Server-side" value={stats.serverOpen} />
        <StatCard icon={Smartphone} label="In the apps" value={stats.clientOpen} tone="secondary" />
      </div>

      <Section title={`${FILTERS.find((f) => f.key === filter)?.label} errors`} hint={`${fmtNumber(errors.total)} total`}>
        {errors.rows.length === 0 ? (
          <Empty
            text={
              filter === "open"
                ? "Nothing is failing right now. New errors appear here automatically."
                : "Nothing here."
            }
          />
        ) : (
          <>
            <div className="space-y-3">
              {errors.rows.map((error) => (
                <ErrorCard key={error.id} error={error} />
              ))}
            </div>
            <Pagination
              basePath={BASE}
              params={{ filter }}
              page={errors.page}
              pageSize={errors.pageSize}
              total={errors.total}
            />
          </>
        )}
      </Section>
    </>
  );
}

function ErrorCard({ error }: { error: ErrorRecord }) {
  const resolved = error.resolvedAt !== null;

  return (
    <Card>
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <Badge tone={error.scope === "client" ? "secondary" : "primary"}>
              {error.scope === "client" ? "App" : "Server"}
            </Badge>
            <span className="font-mono text-xs font-semibold" style={{ color: "var(--color-secondary)" }}>
              {error.source}
            </span>
            <Badge tone={resolved ? "muted" : "danger"}>
              {resolved ? "Resolved" : `×${fmtNumber(error.count)}`}
            </Badge>
          </div>

          <p className="mt-2 text-sm font-medium break-words" style={{ color: "var(--color-foreground)" }}>
            {error.name && error.name !== "Error" ? `${error.name}: ` : ""}
            {error.message}
          </p>

          <dl className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs" style={{ color: "var(--color-muted)" }}>
            <Meta label="Last seen" value={`${fmtAgo(error.lastSeen)} · ${fmtDate(error.lastSeen)}`} />
            <Meta label="First seen" value={fmtDate(error.firstSeen)} />
            {error.url ? <Meta label="Where" value={error.url} /> : null}
            {error.platform ? <Meta label="Platform" value={platformLabel(error.platform)} /> : null}
            {error.appVersion ? <Meta label="Version" value={`v${error.appVersion}`} /> : null}
            {error.deviceId ? <Meta label="Device" value={shortId(error.deviceId)} /> : null}
          </dl>
        </div>

        <ErrorRowActions id={error.id} resolved={resolved} />
      </div>

      {error.stack ? (
        <details className="mt-3">
          <summary
            className="cursor-pointer text-xs font-semibold"
            style={{ color: "var(--color-primary)" }}
          >
            Stack trace
          </summary>
          <pre
            className="mt-2 max-h-72 overflow-auto rounded-xl p-3 text-[11px] leading-relaxed"
            style={{ background: "var(--color-surface-dim)", color: "var(--color-muted)" }}
          >
            {error.stack}
          </pre>
        </details>
      ) : null}
    </Card>
  );
}

function Meta({ label, value }: { label: string; value: string }) {
  return (
    <span className="inline-flex gap-1">
      <dt className="font-semibold">{label}:</dt>
      <dd className="break-all">{value}</dd>
    </span>
  );
}

function FilterTabs({ active }: { active: ErrorFilter }) {
  return (
    <div
      className="inline-flex rounded-xl border p-0.5"
      style={{ borderColor: "var(--color-border)", background: "var(--color-card)" }}
    >
      {FILTERS.map(({ key, label }) => (
        <Link
          key={key}
          href={`${BASE}?filter=${key}`}
          className="rounded-lg px-3 py-1.5 text-xs font-semibold transition"
          style={
            key === active
              ? { background: "var(--color-primary)", color: "#fff" }
              : { color: "var(--color-muted)" }
          }
        >
          {label}
        </Link>
      ))}
    </div>
  );
}
