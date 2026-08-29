/**
 * Fixed-window per-IP limiter for the endpoints the apps call without any
 * credentials — Stillora has no accounts, so an IP is the only handle there is.
 *
 * In-memory and per-instance: enough to stop a stuck client or a single abuser
 * from monopolising an expensive route, not a defence against a distributed
 * one. Anything stronger belongs at the edge/proxy.
 */
type Bucket = { count: number; resetAt: number };

const buckets = new Map<string, Bucket>();

// Bounds the map so a long-running instance cannot accumulate an entry per IP
// seen that day.
const MAX_TRACKED = 5000;

export function overRateLimit(
  key: string,
  limit: number,
  windowMs: number,
): boolean {
  const now = Date.now();
  const bucket = buckets.get(key);

  if (!bucket || now >= bucket.resetAt) {
    if (buckets.size > MAX_TRACKED) buckets.clear();
    buckets.set(key, { count: 1, resetAt: now + windowMs });
    return false;
  }

  bucket.count += 1;
  return bucket.count > limit;
}
