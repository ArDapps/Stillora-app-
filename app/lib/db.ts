import { Pool } from "pg";

/**
 * Shared Postgres connection pool. Cached on `globalThis` so Next.js HMR in dev
 * (and repeated route invocations) reuse a single pool instead of leaking one
 * per reload.
 */
const globalForPg = globalThis as unknown as { _stilloraPgPool?: Pool };

export function getPool(): Pool {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error("DATABASE_URL is not set.");
  }
  globalForPg._stilloraPgPool ??= new Pool({
    connectionString,
    // Allow self-signed certs when DATABASE_SSL=require (managed providers).
    ssl: process.env.DATABASE_SSL === "require" ? { rejectUnauthorized: false } : undefined,
  });
  return globalForPg._stilloraPgPool;
}

/** Runs DDL once per process; the resulting promise is cached. */
let schemaReady: Promise<void> | undefined;

export function ensureSchema(): Promise<void> {
  schemaReady ??= getPool()
    .query(`
      CREATE TABLE IF NOT EXISTS admin_users (
        sub        TEXT PRIMARY KEY,
        email      TEXT NOT NULL,
        name       TEXT NOT NULL,
        picture    TEXT NOT NULL DEFAULT '',
        first_seen TIMESTAMPTZ NOT NULL DEFAULT now(),
        last_seen  TIMESTAMPTZ NOT NULL DEFAULT now()
      );

      CREATE TABLE IF NOT EXISTS admin_exports (
        id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_sub   TEXT NOT NULL,
        user_email TEXT NOT NULL,
        user_name  TEXT NOT NULL,
        preset_id  TEXT NOT NULL,
        duration   INTEGER NOT NULL DEFAULT 0,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      );

      CREATE INDEX IF NOT EXISTS admin_exports_created_at_idx ON admin_exports (created_at DESC);
      CREATE INDEX IF NOT EXISTS admin_exports_user_sub_idx ON admin_exports (user_sub);

      CREATE TABLE IF NOT EXISTS download_links (
        platform     TEXT PRIMARY KEY,
        kind         TEXT NOT NULL,
        external_url TEXT NOT NULL DEFAULT '',
        file_name    TEXT NOT NULL DEFAULT '',
        file_path    TEXT NOT NULL DEFAULT '',
        content_type TEXT NOT NULL DEFAULT '',
        size_bytes   BIGINT NOT NULL DEFAULT 0,
        version      TEXT NOT NULL DEFAULT '',
        updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
      );

      -- One row per app usage session (web, mobile, or desktop). A session is
      -- created on app open and kept alive by heartbeats; duration_seconds is
      -- the wall-clock time between the first and last heartbeat.
      CREATE TABLE IF NOT EXISTS admin_sessions (
        id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        client_id        TEXT NOT NULL UNIQUE,
        user_sub         TEXT,
        user_email       TEXT NOT NULL DEFAULT '',
        user_name        TEXT NOT NULL DEFAULT '',
        platform         TEXT NOT NULL DEFAULT 'web',
        app_version      TEXT NOT NULL DEFAULT '',
        country          TEXT NOT NULL DEFAULT '',
        country_code     TEXT NOT NULL DEFAULT '',
        region           TEXT NOT NULL DEFAULT '',
        city             TEXT NOT NULL DEFAULT '',
        os               TEXT NOT NULL DEFAULT '',
        browser          TEXT NOT NULL DEFAULT '',
        device           TEXT NOT NULL DEFAULT '',
        user_agent       TEXT NOT NULL DEFAULT '',
        ip_hash          TEXT NOT NULL DEFAULT '',
        started_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
        last_seen_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
        ended_at         TIMESTAMPTZ,
        duration_seconds INTEGER NOT NULL DEFAULT 0
      );

      CREATE INDEX IF NOT EXISTS admin_sessions_started_at_idx ON admin_sessions (started_at DESC);
      CREATE INDEX IF NOT EXISTS admin_sessions_user_sub_idx ON admin_sessions (user_sub);
      CREATE INDEX IF NOT EXISTS admin_sessions_country_idx ON admin_sessions (country_code);
      CREATE INDEX IF NOT EXISTS admin_sessions_platform_idx ON admin_sessions (platform);

      -- One row per screen/feature view, so the dashboard can rank which parts
      -- of the app get used. Linked back to a session via client_id.
      CREATE TABLE IF NOT EXISTS admin_screen_views (
        id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        client_id  TEXT NOT NULL DEFAULT '',
        user_sub   TEXT,
        platform   TEXT NOT NULL DEFAULT 'web',
        screen     TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      );

      CREATE INDEX IF NOT EXISTS admin_screen_views_created_at_idx ON admin_screen_views (created_at DESC);
      CREATE INDEX IF NOT EXISTS admin_screen_views_screen_idx ON admin_screen_views (screen);

      -- One row per user who owns lifetime Pro, whatever granted it. This is
      -- what makes the unlock follow the Stillora *account* rather than a
      -- store account, so Linux and Windows -- which have no store at all --
      -- and a buyer who switches between Apple and Google can still be Pro.
      --
      -- The source column is where the entitlement came from: 'apple' or
      -- 'google' from a real purchase, 'admin' for a comp granted from the
      -- panel. The store's own token is kept verbatim in store_token so a
      -- purchase recorded today can be verified against Apple/Google
      -- retroactively, once those server credentials exist.
      --
      -- Revoking sets revoked_at rather than deleting: a support case needs
      -- to see that a comp was given and taken back, not a missing row.
      CREATE TABLE IF NOT EXISTS pro_entitlements (
        user_sub     TEXT PRIMARY KEY,
        source       TEXT NOT NULL,
        product_id   TEXT NOT NULL DEFAULT '',
        store_token  TEXT NOT NULL DEFAULT '',
        platform     TEXT NOT NULL DEFAULT '',
        verified     BOOLEAN NOT NULL DEFAULT false,
        granted_by   TEXT NOT NULL DEFAULT '',
        note         TEXT NOT NULL DEFAULT '',
        granted_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
        revoked_at   TIMESTAMPTZ,
        revoked_by   TEXT NOT NULL DEFAULT ''
      );

      CREATE INDEX IF NOT EXISTS pro_entitlements_granted_at_idx
        ON pro_entitlements (granted_at DESC);

      -- Server-side IP -> location cache so we don't call the geo API on every
      -- heartbeat. Keyed by raw IP; sessions only persist a hashed IP.
      CREATE TABLE IF NOT EXISTS admin_geo_cache (
        ip           TEXT PRIMARY KEY,
        country      TEXT NOT NULL DEFAULT '',
        country_code TEXT NOT NULL DEFAULT '',
        region       TEXT NOT NULL DEFAULT '',
        city         TEXT NOT NULL DEFAULT '',
        fetched_at   TIMESTAMPTZ NOT NULL DEFAULT now()
      );
    `)
    .then(() => undefined)
    .catch((error) => {
      // Reset so a later call can retry after a transient DB outage.
      schemaReady = undefined;
      throw error;
    });
  return schemaReady;
}

/** Acquires the pool, ensures the schema exists, then runs a parameterized query. */
export async function query<T extends Record<string, unknown>>(
  text: string,
  params: unknown[] = [],
): Promise<T[]> {
  await ensureSchema();
  const result = await getPool().query(text, params);
  return result.rows as T[];
}
