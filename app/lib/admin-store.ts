import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";

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

type AdminStore = {
  users: UserRecord[];
  exports: ExportRecord[];
};

function getStorePath(): string {
  return (
    process.env.ADMIN_STORE_PATH ??
    path.join(process.cwd(), "data", "admin-store.json")
  );
}

async function readStore(): Promise<AdminStore> {
  try {
    const raw = await readFile(getStorePath(), "utf-8");
    return JSON.parse(raw) as AdminStore;
  } catch {
    return { users: [], exports: [] };
  }
}

async function writeStore(store: AdminStore): Promise<void> {
  const storePath = getStorePath();
  await mkdir(path.dirname(storePath), { recursive: true });
  await writeFile(storePath, JSON.stringify(store, null, 2));
}

export async function recordUserLogin(user: {
  sub: string;
  email: string;
  name: string;
  picture: string;
}): Promise<void> {
  try {
    const store = await readStore();
    const now = new Date().toISOString();
    const existing = store.users.find((u) => u.sub === user.sub);
    if (existing) {
      existing.lastSeen = now;
      existing.name = user.name;
      existing.picture = user.picture;
    } else {
      store.users.push({ ...user, firstSeen: now, lastSeen: now, exportCount: 0 });
    }
    await writeStore(store);
  } catch {
    // Never fail a login because of store errors
  }
}

export async function recordExport(
  user: { sub: string; email: string; name: string },
  data: { presetId: string; duration: number },
): Promise<void> {
  try {
    const store = await readStore();
    store.exports.push({
      id: crypto.randomUUID(),
      userSub: user.sub,
      userEmail: user.email,
      userName: user.name,
      timestamp: new Date().toISOString(),
      presetId: data.presetId,
      duration: data.duration,
    });
    if (store.exports.length > 1000) {
      store.exports = store.exports.slice(-1000);
    }
    const rec = store.users.find((u) => u.sub === user.sub);
    if (rec) rec.exportCount += 1;
    await writeStore(store);
  } catch {
    // Never fail an export because of store errors
  }
}

export async function getUsers(): Promise<UserRecord[]> {
  const store = await readStore();
  return [...store.users].sort(
    (a, b) => new Date(b.lastSeen).getTime() - new Date(a.lastSeen).getTime(),
  );
}

export async function getRecentExports(limit = 50): Promise<ExportRecord[]> {
  const store = await readStore();
  return [...store.exports]
    .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
    .slice(0, limit);
}

export async function deleteUser(sub: string): Promise<void> {
  const store = await readStore();
  store.users = store.users.filter((u) => u.sub !== sub);
  store.exports = store.exports.filter((e) => e.userSub !== sub);
  await writeStore(store);
}

export async function getStats(): Promise<{
  totalUsers: number;
  totalExports: number;
  exportsToday: number;
}> {
  const store = await readStore();
  const today = new Date().toISOString().slice(0, 10);
  return {
    totalUsers: store.users.length,
    totalExports: store.exports.length,
    exportsToday: store.exports.filter((e) => e.timestamp.startsWith(today)).length,
  };
}
