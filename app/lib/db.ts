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
