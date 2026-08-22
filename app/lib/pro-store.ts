import { query } from "./db";

/** Where an entitlement came from. */
export type ProSource = "apple" | "google" | "admin";

export type ProEntitlement = {
  userSub: string;
  source: ProSource;
  productId: string;
  platform: string;
  verified: boolean;
  grantedBy: string;
  note: string;
  grantedAt: string;
  revokedAt: string | null;
  revokedBy: string;
};

type EntitlementRow = {
  user_sub: string;
  source: string;
  product_id: string;
  platform: string;
  verified: boolean;
  granted_by: string;
  note: string;
  granted_at: Date;
  revoked_at: Date | null;
  revoked_by: string;
};

function toIso(value: Date | string): string {
  return value instanceof Date ? value.toISOString() : new Date(value).toISOString();
}

function mapEntitlement(row: EntitlementRow): ProEntitlement {
  return {
    userSub: row.user_sub,
    source: (["apple", "google", "admin"].includes(row.source) ? row.source : "admin") as ProSource,
    productId: row.product_id,
    platform: row.platform,
    verified: row.verified,
    grantedBy: row.granted_by,
    note: row.note,
    grantedAt: toIso(row.granted_at),
    revokedAt: row.revoked_at ? toIso(row.revoked_at) : null,
    revokedBy: row.revoked_by,
  };
}

/**
 * The entitlement row for one user, revoked ones included — callers decide what
 * a revocation means. `null` when the user has never had Pro.
 */
export async function getEntitlement(userSub: string): Promise<ProEntitlement | null> {
  const rows = await query<EntitlementRow>(
    `SELECT user_sub, source, product_id, platform, verified, granted_by, note,
            granted_at, revoked_at, revoked_by
       FROM pro_entitlements
      WHERE user_sub = $1`,
    [userSub],
  );
  return rows[0] ? mapEntitlement(rows[0]) : null;
}

/**
 * Records a store purchase against the Stillora account.
 *
 * Idempotent by design: the app re-posts its token on every launch that finds a
 * store entitlement, so this must be safe to call repeatedly. A repeat call
 * refreshes the token (Play rotates purchase tokens on re-download) and clears
 * any previous revocation — a real purchase outranks an admin comp being taken
 * back, because the user genuinely paid.
 *
 * The token is stored verbatim and `verified` stays false until something
 * actually checks it with Apple/Google. Nothing here calls the stores yet.
 */
export async function recordStorePurchase(input: {
  userSub: string;
  source: Exclude<ProSource, "admin">;
  productId: string;
  storeToken: string;
  platform: string;
}): Promise<ProEntitlement> {
  const rows = await query<EntitlementRow>(
    `INSERT INTO pro_entitlements
       (user_sub, source, product_id, store_token, platform, verified, granted_by, note)
     VALUES ($1, $2, $3, $4, $5, false, '', '')
     ON CONFLICT (user_sub) DO UPDATE
       SET source      = EXCLUDED.source,
           product_id  = EXCLUDED.product_id,
           store_token = CASE
                           WHEN EXCLUDED.store_token <> '' THEN EXCLUDED.store_token
                           ELSE pro_entitlements.store_token
                         END,
           platform    = EXCLUDED.platform,
           revoked_at  = NULL,
           revoked_by  = ''
     RETURNING user_sub, source, product_id, platform, verified, granted_by, note,
               granted_at, revoked_at, revoked_by`,
    [input.userSub, input.source, input.productId, input.storeToken, input.platform],
  );
  return mapEntitlement(rows[0]);
}

/** Comps Pro to a user from the admin panel. */
export async function adminGrantPro(input: {
  userSub: string;
  adminEmail: string;
  note?: string;
}): Promise<ProEntitlement> {
  const rows = await query<EntitlementRow>(
    `INSERT INTO pro_entitlements
       (user_sub, source, product_id, store_token, platform, verified, granted_by, note)
     VALUES ($1, 'admin', '', '', 'admin', true, $2, $3)
     ON CONFLICT (user_sub) DO UPDATE
       SET source     = 'admin',
           granted_by = EXCLUDED.granted_by,
           note       = EXCLUDED.note,
           granted_at = now(),
           revoked_at = NULL,
           revoked_by = ''
     RETURNING user_sub, source, product_id, platform, verified, granted_by, note,
               granted_at, revoked_at, revoked_by`,
    [input.userSub, input.adminEmail, input.note ?? ""],
  );
  return mapEntitlement(rows[0]);
}

/**
 * Takes back an **admin-granted** entitlement.
 *
 * Deliberately refuses to touch a real store purchase. The buyer's device would
 * still hear "owned" from Apple/Google on the next launch and re-grant itself,
 * so revoking here would achieve nothing except a confusing row in the panel —
 * an actual refund is the store's job, not ours.
 *
 * Returns false when there was nothing revocable.
 */
export async function adminRevokePro(input: {
  userSub: string;
  adminEmail: string;
}): Promise<boolean> {
  const rows = await query<{ user_sub: string }>(
    `UPDATE pro_entitlements
        SET revoked_at = now(), revoked_by = $2
      WHERE user_sub = $1 AND source = 'admin' AND revoked_at IS NULL
      RETURNING user_sub`,
    [input.userSub, input.adminEmail],
  );
  return rows.length > 0;
}

/** Active-Pro lookup for a page of users, keyed by sub. */
export async function getEntitlementsFor(
  subs: string[],
): Promise<Map<string, ProEntitlement>> {
  if (subs.length === 0) return new Map();
  const rows = await query<EntitlementRow>(
    `SELECT user_sub, source, product_id, platform, verified, granted_by, note,
            granted_at, revoked_at, revoked_by
       FROM pro_entitlements
      WHERE user_sub = ANY($1::text[])`,
    [subs],
  );
  return new Map(rows.map((row) => [row.user_sub, mapEntitlement(row)]));
}

/** How many users currently hold Pro, split by where it came from. */
export async function getProStats(): Promise<{ total: number; bySource: Record<string, number> }> {
  const rows = await query<{ source: string; count: string }>(
    `SELECT source, COUNT(*)::text AS count
       FROM pro_entitlements
      WHERE revoked_at IS NULL
      GROUP BY source`,
  );
  const bySource: Record<string, number> = {};
  let total = 0;
  for (const row of rows) {
    const count = Number(row.count) || 0;
    bySource[row.source] = count;
    total += count;
  }
  return { total, bySource };
}
