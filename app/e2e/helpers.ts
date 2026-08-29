import { expect, type Page } from "@playwright/test";

/**
 * The super-admin credentials the dev server is running with. Read from the
 * environment so the suite works against whatever .env.local says, rather than
 * hard-coding a password into the repository.
 */
export const ADMIN_EMAIL = process.env.ADMIN_EMAILS?.split(",")[0]?.trim() ?? "";
export const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD ?? "";

/**
 * A token unique per run that survives the error log's fingerprint.
 *
 * `logError` normalizes digits out of a message so "row 41 not found" and
 * "row 92 not found" group into one row — which means a timestamp makes a poor
 * unique marker: two runs would collapse into the same error. Letters only.
 */
export function uniqueToken(): string {
  const letters = "abcdefghijklmnopqrstuvwxyz";
  return Array.from(
    { length: 10 },
    () => letters[Math.floor(Math.random() * letters.length)],
  ).join("");
}

/** Signs in at /admin/login and waits for the dashboard to render. */
export async function signInAsAdmin(page: Page): Promise<void> {
  await page.goto("/admin/login");
  await page.getByPlaceholder("admin@example.com").fill(ADMIN_EMAIL);
  await page.getByPlaceholder("••••••••").fill(ADMIN_PASSWORD);
  await page.getByRole("button", { name: "Sign in" }).click();
  await expect(page).toHaveURL(/\/admin$/);
  await expect(page.getByRole("heading", { name: "Overview" })).toBeVisible();
}

/**
 * Reports a crash the way a real client does, so the Errors page has something
 * to show. The message is unique per call so it survives the log's dedupe.
 */
export async function reportClientError(
  page: Page,
  message: string,
): Promise<number> {
  const response = await page.request.post("/api/errors", {
    data: {
      source: "e2e/playwright",
      name: "E2EError",
      message,
      stack: "at e2e (playwright.spec.ts:1:1)",
      url: "/e2e",
      platform: "web",
      deviceId: "d-e2e-device",
    },
  });
  return response.status();
}
