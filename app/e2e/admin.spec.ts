import { expect, test } from "@playwright/test";

import {
  ADMIN_EMAIL,
  ADMIN_PASSWORD,
  reportClientError,
  signInAsAdmin,
  uniqueToken,
} from "./helpers";

test.describe("admin login", () => {
  test("the credentials are configured", () => {
    // A blank password would make every other test here pass vacuously.
    expect(ADMIN_EMAIL, "ADMIN_EMAILS is not set").not.toBe("");
    expect(ADMIN_PASSWORD, "ADMIN_PASSWORD is not set").not.toBe("");
  });

  test("a wrong password is rejected", async ({ page }) => {
    await page.goto("/admin/login");
    await page.getByPlaceholder("admin@example.com").fill(ADMIN_EMAIL);
    await page.getByPlaceholder("••••••••").fill("definitely-not-the-password");
    await page.getByRole("button", { name: "Sign in" }).click();
    await expect(page.getByText(/invalid credentials/i)).toBeVisible();
    await expect(page).toHaveURL(/\/admin\/login/);
  });

  test("an unknown email is rejected even with the right password", async ({ page }) => {
    await page.goto("/admin/login");
    await page.getByPlaceholder("admin@example.com").fill("stranger@example.com");
    await page.getByPlaceholder("••••••••").fill(ADMIN_PASSWORD);
    await page.getByRole("button", { name: "Sign in" }).click();
    await expect(page.getByText(/invalid credentials/i)).toBeVisible();
  });

  test("the super admin gets in", async ({ page }) => {
    await signInAsAdmin(page);
    await expect(page.getByText(ADMIN_EMAIL)).toBeVisible();
  });
});

test.describe("dashboard", () => {
  test.beforeEach(async ({ page }) => {
    await signInAsAdmin(page);
  });

  test("the overview shows every headline counter", async ({ page }) => {
    for (const label of [
      "Devices",
      "Sessions",
      "Exports",
      "Time in app",
      "Pro devices",
      "Open errors",
    ]) {
      await expect(page.getByText(label, { exact: true }).first()).toBeVisible();
    }
    await expect(page.getByText(/active now/i)).toBeVisible();
    await expect(page.getByText(/sessions vs exports/i)).toBeVisible();
  });

  test("no account-era section survives", async ({ page }) => {
    const nav = page.locator("nav").first();
    await expect(nav).toContainText("Overview");
    await expect(nav).toContainText("Usage");
    await expect(nav).toContainText("Exports");
    await expect(nav).toContainText("Errors");
    await expect(nav).toContainText("Downloads");
    await expect(nav).not.toContainText("Activity");
    await expect(nav).not.toContainText("Analytics");

    // The old per-user pages are gone, not merely unlinked.
    for (const path of ["/admin/users", "/admin/activity", "/admin/analytics"]) {
      const response = await page.request.get(path);
      expect(response.status(), `${path} should be gone`).toBe(404);
    }
  });

  test("every page in the panel loads", async ({ page }) => {
    const pages: [string, string][] = [
      ["/admin/usage", "Usage"],
      ["/admin/exports", "Exports"],
      ["/admin/errors", "Errors"],
      ["/admin/downloads", "Downloads"],
    ];
    for (const [path, heading] of pages) {
      await page.goto(path);
      await expect(page.getByRole("heading", { name: heading, level: 1 })).toBeVisible();
    }
  });

  test("the range tabs re-query without breaking", async ({ page }) => {
    for (const range of ["today", "7d", "30d", "all"]) {
      await page.goto(`/admin/usage?range=${range}`);
      await expect(page.getByRole("heading", { name: "Usage", level: 1 })).toBeVisible();
    }
  });
});

test.describe("data reaches the dashboard", () => {
  test("a tracked session turns into a device and a session row", async ({
    page,
    request,
  }) => {
    const clientId = `e2e-session-${Date.now()}`;
    const deviceId = `d-e2e-${Date.now()}`;

    const started = await request.post("/api/track", {
      data: { clientId, deviceId, event: "start", platform: "web", isPro: true },
    });
    expect(started.status()).toBe(202);

    await signInAsAdmin(page);
    await page.goto("/admin/usage?range=today");

    // Device ids are shown abbreviated, so match the prefix the table renders.
    const shortened = deviceId.replace(/^d-/, "").slice(0, 8);
    await expect(page.getByText(shortened, { exact: false }).first()).toBeVisible();
    // is_pro rode in on the beacon.
    await expect(page.getByText("Pro", { exact: true }).first()).toBeVisible();
  });

  test("a recorded export appears in the export log", async ({ page, request }) => {
    const recorded = await request.post("/api/exports/record", {
      data: { presetId: "e2e-preset", duration: 42, tool: "html", platform: "ios" },
      headers: { "x-stillora-device": `d-e2e-export-${Date.now()}` },
    });
    expect(recorded.status()).toBe(201);

    await signInAsAdmin(page);
    await page.goto("/admin/exports?range=today");
    await expect(page.getByText("e2e-preset").first()).toBeVisible();
    await expect(page.getByText("HTML → Video").first()).toBeVisible();
  });

  test("a client crash shows on the errors page and can be resolved", async ({
    page,
  }) => {
    const message = `e2e crash ${uniqueToken()}`;
    expect(await reportClientError(page, message)).toBe(202);

    await signInAsAdmin(page);
    await page.goto("/admin/errors?filter=open");

    // The innermost element holding both the message and its own Resolve
    // button — that is the card, not one of its wrappers.
    const card = page
      .locator("div")
      .filter({ hasText: message })
      .filter({ has: page.getByRole("button", { name: "Resolve" }) })
      .last();
    await expect(page.getByText(message).first()).toBeVisible();
    await expect(page.getByText("e2e/playwright").first()).toBeVisible();

    // Resolving moves it off the open list.
    await card.getByRole("button", { name: "Resolve" }).first().click();
    await expect(page.getByText(message)).toHaveCount(0, { timeout: 20_000 });

    await page.goto("/admin/errors?filter=resolved");
    await expect(page.getByText(message).first()).toBeVisible();
  });

  test("repeat crashes collapse into one row with a count", async ({ page }) => {
    const message = `e2e repeated ${uniqueToken()}`;
    for (let i = 0; i < 3; i++) {
      expect(await reportClientError(page, message)).toBe(202);
    }

    await signInAsAdmin(page);
    await page.goto("/admin/errors?filter=open");
    await expect(page.getByText(message).first()).toBeVisible();
    // Deduped by fingerprint: three reports, one row, ×3.
    await expect(page.getByText("×3").first()).toBeVisible();
  });
});

test.describe("admin session", () => {
  test("signing out closes the panel again", async ({ page }) => {
    await signInAsAdmin(page);
    // The button signs out then sends the browser to "/" itself; navigating
    // before that lands would abort it mid-flight.
    await page.getByRole("button", { name: /sign out admin/i }).click();
    await page.waitForURL((url) => url.pathname === "/");
    await page.goto("/admin");
    await expect(page).toHaveURL(/\/admin\/login/);
  });
});
