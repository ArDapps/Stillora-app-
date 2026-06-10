import { query } from "./db";

export type UserRecord = {
  sub: string;
  email: string;
  name: string;
  picture: string;
  firstSeen: string;
  lastSeen: string;
  exportCount: number;
};

export type ExportRecord = {
  id: string;
  userSub: string;
  userEmail: string;
  userName: string;
  timestamp: string;
  presetId: string;
  duration: number;
};

type UserRow = {
  sub: string;
  email: string;
  name: string;
  picture: string;
  first_seen: Date;
  last_seen: Date;
  export_count: number;
};

type ExportRow = {
  id: string;
  user_sub: string;
  user_email: string;
  user_name: string;
  preset_id: string;
  duration: number;
  created_at: Date;
};

function toIso(value: Date | string): string {
  return value instanceof Date ? value.toISOString() : new Date(value).toISOString();
}

function mapUser(row: UserRow): UserRecord {
  return {
    sub: row.sub,
    email: row.email,
    name: row.name,
    picture: row.picture,
    firstSeen: toIso(row.first_seen),
    lastSeen: toIso(row.last_seen),
    exportCount: Number(row.export_count) || 0,
  };
}

function mapExport(row: ExportRow): ExportRecord {
  return {
    id: row.id,
    userSub: row.user_sub,
    userEmail: row.user_email,
    userName: row.user_name,
    timestamp: toIso(row.created_at),
    presetId: row.preset_id,
    duration: Number(row.duration) || 0,
  };
}

export async function recordUserLogin(user: {
  sub: string;
  email: string;
  name: string;
  picture: string;
}): Promise<void> {
  try {
    await query(
      `INSERT INTO admin_users (sub, email, name, picture, first_seen, last_seen)
       VALUES ($1, $2, $3, $4, now(), now())
       ON CONFLICT (sub) DO UPDATE
         SET email = EXCLUDED.email,
             name = EXCLUDED.name,
             picture = EXCLUDED.picture,
             last_seen = now()`,
      [user.sub, user.email, user.name, user.picture],
    );
  } catch (error) {
    // Never fail a login because of store errors.
    console.error("recordUserLogin failed:", error);
  }
}

/**
 * Returns the `sub` of an existing user with this exact email, if any. Used to
 * link an Apple sign-in to a pre-existing (e.g. Google) account when the email
 * is verified, so both providers resolve to the same Stillora user.
 */
export async function findUserSubByEmail(
  email: string,
): Promise<string | null> {
  const normalized = email.trim().toLowerCase();
  if (!normalized) {
    return null;
  }
  try {
    const rows = await query<{ sub: string }>(
      `SELECT sub FROM admin_users
       WHERE lower(email) = $1
       ORDER BY first_seen ASC
       LIMIT 1`,
      [normalized],
    );
    return rows[0]?.sub ?? null;
  } catch (error) {
    console.error("findUserSubByEmail failed:", error);
    return null;
  }
}

export async function recordExport(
  user: { sub: string; email: string; name: string },
  data: { presetId: string; duration: number },
): Promise<void> {
  try {
    // Ensure the user row exists even if the login event was missed (e.g. a
    // returning native client that only restored its session).
    await query(
      `INSERT INTO admin_users (sub, email, name, last_seen)
       VALUES ($1, $2, $3, now())
       ON CONFLICT (sub) DO UPDATE SET last_seen = now()`,
      [user.sub, user.email, user.name],
    );
    await query(
      `INSERT INTO admin_exports (user_sub, user_email, user_name, preset_id, duration)
       VALUES ($1, $2, $3, $4, $5)`,
      [user.sub, user.email, user.name, data.presetId, data.duration],
    );
  } catch (error) {
    // Never fail an export because of store errors.
    console.error("recordExport failed:", error);
  }
}

export async function getUsers(): Promise<UserRecord[]> {
  try {
    const rows = await query<UserRow>(
      `SELECT u.sub, u.email, u.name, u.picture, u.first_seen, u.last_seen,
              COUNT(e.id)::int AS export_count
       FROM admin_users u
       LEFT JOIN admin_exports e ON e.user_sub = u.sub
       GROUP BY u.sub
       ORDER BY u.last_seen DESC`,
    );
    return rows.map(mapUser);
  } catch (error) {
    console.error("getUsers failed:", error);
    return [];
  }
}

export async function getRecentExports(limit = 50): Promise<ExportRecord[]> {
  try {
    const rows = await query<ExportRow>(
      `SELECT id, user_sub, user_email, user_name, preset_id, duration, created_at
       FROM admin_exports
       ORDER BY created_at DESC
       LIMIT $1`,
      [limit],
    );
    return rows.map(mapExport);
  } catch (error) {
    console.error("getRecentExports failed:", error);
    return [];
  }
}

export async function deleteUser(sub: string): Promise<void> {
  await query(`DELETE FROM admin_exports WHERE user_sub = $1`, [sub]);
  await query(`DELETE FROM admin_users WHERE sub = $1`, [sub]);
}

export async function getStats(): Promise<{
  totalUsers: number;
  totalExports: number;
  exportsToday: number;
}> {
  try {
    const rows = await query<{
      total_users: number;
      total_exports: number;
      exports_today: number;
    }>(
      `SELECT
         (SELECT COUNT(*)::int FROM admin_users) AS total_users,
         (SELECT COUNT(*)::int FROM admin_exports) AS total_exports,
         (SELECT COUNT(*)::int FROM admin_exports
            WHERE created_at >= date_trunc('day', now())) AS exports_today`,
    );
    const row = rows[0];
    return {
      totalUsers: Number(row?.total_users) || 0,
      totalExports: Number(row?.total_exports) || 0,
      exportsToday: Number(row?.exports_today) || 0,
    };
  } catch (error) {
    console.error("getStats failed:", error);
    return { totalUsers: 0, totalExports: 0, exportsToday: 0 };
  }
}
