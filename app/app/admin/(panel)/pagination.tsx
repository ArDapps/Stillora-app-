import Link from "next/link";

type Params = Record<string, string | undefined>;

/** Builds a query string from the current params with `overrides` applied. */
function hrefWith(basePath: string, params: Params, overrides: Params): string {
  const merged = { ...params, ...overrides };
  const search = new URLSearchParams();
  for (const [key, value] of Object.entries(merged)) {
    if (value !== undefined && value !== "") search.set(key, value);
  }
  const qs = search.toString();
  return qs ? `${basePath}?${qs}` : basePath;
}

/**
 * Link-based pager for the admin tables (works in server components). Shows a
 * windowed set of page numbers plus Prev/Next, and preserves every other query
 * param (e.g. the analytics `range`) via the `params` prop.
 */
export function Pagination({
  basePath,
  params = {},
  pageParam = "page",
  page,
  pageSize,
  total,
}: {
  basePath: string;
  params?: Params;
  pageParam?: string;
  page: number;
  pageSize: number;
  total: number;
}) {
  const totalPages = Math.max(1, Math.ceil(total / pageSize));
  const current = Math.min(Math.max(1, page), totalPages);
  const from = total === 0 ? 0 : (current - 1) * pageSize + 1;
  const to = Math.min(current * pageSize, total);

  // Window of up to 5 page numbers centered on the current page.
  const windowSize = 5;
  let start = Math.max(1, current - Math.floor(windowSize / 2));
  const end = Math.min(totalPages, start + windowSize - 1);
  start = Math.max(1, end - windowSize + 1);
  const pages = Array.from({ length: end - start + 1 }, (_, i) => start + i);

  const href = (p: number) => hrefWith(basePath, params, { [pageParam]: String(p) });

  return (
    <div className="mt-4 flex flex-wrap items-center justify-between gap-3">
      <p className="text-xs" style={{ color: "var(--color-muted)" }}>
        {total === 0 ? "No results" : `${from}–${to} of ${total.toLocaleString()}`}
      </p>

      {totalPages > 1 && (
        <nav className="flex items-center gap-1">
          <PageLink href={href(current - 1)} disabled={current <= 1}>
            ‹ Prev
          </PageLink>

          {start > 1 && (
            <>
              <PageLink href={href(1)}>1</PageLink>
              {start > 2 && <Ellipsis />}
            </>
          )}

          {pages.map((p) => (
            <PageLink key={p} href={href(p)} active={p === current}>
              {p}
            </PageLink>
          ))}

          {end < totalPages && (
            <>
              {end < totalPages - 1 && <Ellipsis />}
              <PageLink href={href(totalPages)}>{totalPages}</PageLink>
            </>
          )}

          <PageLink href={href(current + 1)} disabled={current >= totalPages}>
            Next ›
          </PageLink>
        </nav>
      )}
    </div>
  );
}

function PageLink({
  href,
  children,
  active = false,
  disabled = false,
}: {
  href: string;
  children: React.ReactNode;
  active?: boolean;
  disabled?: boolean;
}) {
  const base =
    "inline-flex min-w-8 items-center justify-center rounded-lg border px-2.5 py-1.5 text-xs font-medium transition";

  if (disabled) {
    return (
      <span
        className={`${base} cursor-not-allowed opacity-40`}
        style={{ borderColor: "var(--color-border)", color: "var(--color-muted)" }}
      >
        {children}
      </span>
    );
  }

  return (
    <Link
      href={href}
      className={base}
      style={
        active
          ? { background: "var(--color-primary)", borderColor: "var(--color-primary)", color: "#fff" }
          : { borderColor: "var(--color-border)", color: "var(--color-foreground)" }
      }
    >
      {children}
    </Link>
  );
}

function Ellipsis() {
  return (
    <span className="px-1 text-xs" style={{ color: "var(--color-muted)" }}>
      …
    </span>
  );
}
