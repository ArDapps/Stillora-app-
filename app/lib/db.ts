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
      -- One row per completed export, from any surface. Stillora has no
      -- accounts, so exports are attributed to a device, never to a person.
      CREATE TABLE IF NOT EXISTS admin_exports (
        id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        device_id  TEXT NOT NULL DEFAULT '',
        platform   TEXT NOT NULL DEFAULT '',
        tool       TEXT NOT NULL DEFAULT 'create',
        preset_id  TEXT NOT NULL,
        duration   INTEGER NOT NULL DEFAULT 0,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      );

      CREATE INDEX IF NOT EXISTS admin_exports_created_at_idx ON admin_exports (created_at DESC);

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
      CREATE INDEX IF NOT EXISTS admin_sessions_country_idx ON admin_sessions (country_code);
      CREATE INDEX IF NOT EXISTS admin_sessions_platform_idx ON admin_sessions (platform);

      -- One row per screen/feature view, so the dashboard can rank which parts
      -- of the app get used. Linked back to a session via client_id.
      CREATE TABLE IF NOT EXISTS admin_screen_views (
        id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        client_id  TEXT NOT NULL DEFAULT '',
        platform   TEXT NOT NULL DEFAULT 'web',
        screen     TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      );

      CREATE INDEX IF NOT EXISTS admin_screen_views_created_at_idx ON admin_screen_views (created_at DESC);
      CREATE INDEX IF NOT EXISTS admin_screen_views_screen_idx ON admin_screen_views (screen);

      -- NOTE: admin_users and pro_entitlements are no longer created here.
      -- Both were keyed by a signed-in account, and Stillora has no accounts:
      -- Pro now lives on the device (the store plus local preferences), and
      -- usage is counted per device. Existing databases keep whatever rows
      -- those tables already hold; nothing reads or writes them.

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

      -- Every failure the app reports, from any surface: a server route or store
      -- function that threw, or an uncaught error in a client (web/mobile).
      -- Rows are deduped by the fingerprint column (scope + source + normalized message)
      -- so one broken function is a single row with a rising count, not a
      -- flood that buries everything else.
      CREATE TABLE IF NOT EXISTS admin_errors (
        id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        fingerprint TEXT NOT NULL UNIQUE,
        scope       TEXT NOT NULL DEFAULT 'server',
        source      TEXT NOT NULL DEFAULT '',
        name        TEXT NOT NULL DEFAULT '',
        message     TEXT NOT NULL DEFAULT '',
        stack       TEXT NOT NULL DEFAULT '',
        url         TEXT NOT NULL DEFAULT '',
        platform    TEXT NOT NULL DEFAULT '',
        app_version TEXT NOT NULL DEFAULT '',
        device_id   TEXT NOT NULL DEFAULT '',
        user_agent  TEXT NOT NULL DEFAULT '',
        count       INTEGER NOT NULL DEFAULT 1,
        first_seen  TIMESTAMPTZ NOT NULL DEFAULT now(),
        last_seen   TIMESTAMPTZ NOT NULL DEFAULT now(),
        resolved_at TIMESTAMPTZ
      );

      CREATE INDEX IF NOT EXISTS admin_errors_last_seen_idx ON admin_errors (last_seen DESC);
      CREATE INDEX IF NOT EXISTS admin_errors_scope_idx ON admin_errors (scope);

      -- One row, tracking when housekeeping last ran. Kept in the database so
      -- several app instances share the schedule rather than each keeping its
      -- own timer.
      CREATE TABLE IF NOT EXISTS admin_maintenance (
        id            TEXT PRIMARY KEY,
        last_purge_at TIMESTAMPTZ NOT NULL DEFAULT now()
      );

      -- Migrations for installs created before anonymous (account-less) tracking.
      -- Stillora has no sign-in any more, so every counter is keyed by device.
      ALTER TABLE admin_sessions     ADD COLUMN IF NOT EXISTS device_id TEXT NOT NULL DEFAULT '';
      ALTER TABLE admin_sessions     ADD COLUMN IF NOT EXISTS is_pro BOOLEAN NOT NULL DEFAULT false;
      ALTER TABLE admin_screen_views ADD COLUMN IF NOT EXISTS device_id TEXT NOT NULL DEFAULT '';
      ALTER TABLE admin_exports      ADD COLUMN IF NOT EXISTS device_id TEXT NOT NULL DEFAULT '';
      ALTER TABLE admin_exports      ADD COLUMN IF NOT EXISTS platform TEXT NOT NULL DEFAULT '';
      ALTER TABLE admin_exports      ADD COLUMN IF NOT EXISTS tool TEXT NOT NULL DEFAULT 'create';

      -- A database created back when exports belonged to a signed-in account
      -- still has admin_exports.user_sub, declared NOT NULL. Nothing writes it
      -- any more, so it has to stop being required or every insert fails. The
      -- guard is what makes this safe to run against a fresh database too,
      -- where the column was never created.
      DO $do$
      BEGIN
        IF EXISTS (
          SELECT 1 FROM information_schema.columns
          WHERE table_name = 'admin_exports' AND column_name = 'user_sub'
        ) THEN
          ALTER TABLE admin_exports ALTER COLUMN user_sub DROP NOT NULL;
        END IF;
      END
      $do$;

      CREATE INDEX IF NOT EXISTS admin_sessions_device_id_idx ON admin_sessions (device_id);
      CREATE INDEX IF NOT EXISTS admin_exports_device_id_idx ON admin_exports (device_id);
      CREATE INDEX IF NOT EXISTS admin_exports_tool_idx ON admin_exports (tool);
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
