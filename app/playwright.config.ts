import { defineConfig, devices } from "@playwright/test";
import dotenv from "dotenv";

// Next loads .env.local for the server it runs; the test process needs the same
// admin credentials to sign in with, so load it here too.
dotenv.config({ path: ".env.local", quiet: true });

const PORT = Number(process.env.E2E_PORT ?? 3000);
const baseURL = `http://localhost:${PORT}`;

/**
 * End-to-end config.
 *
 * The suite runs against a real dev server and a real Postgres, because the
 * things worth testing here — the admin gate, the analytics beacons, the error
 * log — are all round trips through the database. `webServer` starts `next dev`
 * and waits for it; Next loads .env.local itself, which is where the admin
 * credentials and DATABASE_URL live.
 */
export default defineConfig({
  testDir: "./e2e",
  // Admin tests share one dashboard and assert on counts that other tests
  // would move underneath them.
  workers: 1,
  fullyParallel: false,
  forbidOnly: Boolean(process.env.CI),
  retries: process.env.CI ? 1 : 0,
  reporter: [["list"]],
  timeout: 60_000,
  expect: { timeout: 15_000 },
  use: {
    baseURL,
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
  },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
  webServer: {
    command: `npm run dev -- --port ${PORT}`,
    url: baseURL,
    reuseExistingServer: true,
    // A cold `next dev` compiles on first request; give it room.
    timeout: 180_000,
    stdout: "pipe",
    stderr: "pipe",
  },
});
