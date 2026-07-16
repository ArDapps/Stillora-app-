import { query } from "./db";

export type GeoLocation = {
  country: string;
  countryCode: string;
  region: string;
  city: string;
};

const EMPTY: GeoLocation = { country: "", countryCode: "", region: "", city: "" };

// Cache freshness: re-lookup an IP at most once every 30 days.
const CACHE_TTL_MS = 30 * 24 * 60 * 60 * 1000;

/**
 * Pulls the caller's public IP out of the usual reverse-proxy headers. Returns
 * an empty string when only a private/loopback address is available (local dev,
 * container-internal traffic), which callers should treat as "no location".
 */
export function getClientIp(request: Request): string {
  const forwarded = request.headers.get("x-forwarded-for");
  const candidates = [
    ...(forwarded ? forwarded.split(",") : []),
    request.headers.get("x-real-ip") ?? "",
    request.headers.get("cf-connecting-ip") ?? "",
  ]
    .map((value) => value.trim())
    .filter(Boolean);

  for (const ip of candidates) {
    if (!isPrivateIp(ip)) {
      return ip;
    }
  }
  return "";
}

function isPrivateIp(ip: string): boolean {
  if (!ip) return true;
  if (ip === "::1" || ip.startsWith("127.") || ip.startsWith("::ffff:127.")) return true;
  if (ip === "localhost") return true;
  if (ip.startsWith("10.") || ip.startsWith("192.168.")) return true;
  if (/^172\.(1[6-9]|2\d|3[0-1])\./.test(ip)) return true;
  if (ip.startsWith("169.254.") || ip.startsWith("fc") || ip.startsWith("fd")) return true;
  return false;
}

type GeoRow = {
  country: string;
  country_code: string;
  region: string;
  city: string;
  fetched_at: Date;
};

/**
 * Resolves an IP to a coarse location (country/region/city), caching results in
 * `admin_geo_cache`. Falls back to an empty location on any failure so tracking
 * never breaks because the geo provider is slow or rate-limited.
 */
export async function lookupGeo(ip: string): Promise<GeoLocation> {
  if (!ip || isPrivateIp(ip)) return EMPTY;

  try {
    const cached = await query<GeoRow>(
      `SELECT country, country_code, region, city, fetched_at
       FROM admin_geo_cache WHERE ip = $1`,
      [ip],
    );
    const row = cached[0];
    if (row && Date.now() - new Date(row.fetched_at).getTime() < CACHE_TTL_MS) {
      return {
        country: row.country,
        countryCode: row.country_code,
        region: row.region,
        city: row.city,
      };
    }
  } catch (error) {
    console.error("lookupGeo cache read failed:", error);
  }

  const fresh = await fetchGeo(ip);
  if (!fresh) return EMPTY;

  try {
    await query(
      `INSERT INTO admin_geo_cache (ip, country, country_code, region, city, fetched_at)
       VALUES ($1, $2, $3, $4, $5, now())
       ON CONFLICT (ip) DO UPDATE
         SET country = EXCLUDED.country,
             country_code = EXCLUDED.country_code,
             region = EXCLUDED.region,
             city = EXCLUDED.city,
             fetched_at = now()`,
      [ip, fresh.country, fresh.countryCode, fresh.region, fresh.city],
    );
  } catch (error) {
    console.error("lookupGeo cache write failed:", error);
  }

  return fresh;
}

async function fetchGeo(ip: string): Promise<GeoLocation | null> {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 4000);
    const response = await fetch(
      `http://ip-api.com/json/${encodeURIComponent(ip)}?fields=status,country,countryCode,regionName,city`,
      { signal: controller.signal, cache: "no-store" },
    );
    clearTimeout(timeout);

    if (!response.ok) return null;
    const data = (await response.json()) as {
      status?: string;
      country?: string;
      countryCode?: string;
      regionName?: string;
      city?: string;
    };
    if (data.status !== "success") return null;

    return {
      country: data.country ?? "",
      countryCode: data.countryCode ?? "",
      region: data.regionName ?? "",
      city: data.city ?? "",
    };
  } catch (error) {
    console.error("fetchGeo failed:", error);
    return null;
  }
}
