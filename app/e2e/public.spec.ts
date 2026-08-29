import { expect, test } from "@playwright/test";

/**
 * The parts of Stillora anyone can reach, and the parts nobody can without the
 * admin password. Since sign-in was removed, "logged out" is the only public
 * state there is — so these also prove no auth surface came back.
 */
test.describe("public site", () => {
  test("the landing page renders", async ({ page }) => {
    await page.goto("/");
    await expect(page).toHaveTitle(/Stillora/i);
    await expect(page.getByRole("heading", { level: 1 })).toContainText(
      /Turn your images into video/i,
    );
    await expect(page.locator(".st-nav")).toBeVisible();
    await expect(page.locator(".st-hero")).toBeVisible();
  });

  test("the hero art and brand mark actually load", async ({ page }) => {
    await page.goto("/");
    // A broken <img> reports naturalWidth 0 — catches a missing asset that a
    // visual check would miss on a fast connection.
    const broken = await page.evaluate(() =>
      Array.from(document.images)
        .filter((image) => image.complete && image.naturalWidth === 0)
        .map((image) => image.getAttribute("src")),
    );
    expect(broken, `broken images: ${broken.join(", ")}`).toEqual([]);
  });

  test("the store strip points at the admin-managed downloads", async ({ page }) => {
    await page.goto("/");
    const stores = page.locator(".st-store");
    // macOS, iOS, Android and Windows — Linux has no download configured, and
    // the strip drops any surface without one rather than linking nowhere.
    await expect(stores).toHaveCount(4);

    const hrefs = await stores.evaluateAll((links) =>
      links.map((link) => link.getAttribute("href")),
    );
    expect(hrefs.every((href) => Boolean(href))).toBe(true);
    // These come from lib/site.ts / the Downloads panel, not the design's
    // placeholder "search the App Store" links.
    const joined = hrefs.join(" ");
    expect(joined).not.toContain("search?term=");
    // Android points at the live Play listing, not the sideload APK.
    expect(joined).toContain("play.google.com/store/apps/details?id=app.loopara.stillora");
    expect(joined).not.toContain("stillora-android.apk");
  });

  test("no unverified stats or testimonials are published", async ({ page }) => {
    await page.goto("/");
    const body = await page.locator("body").innerText();
    // The marketing brief flags these as placeholder data.
    expect(body).not.toMatch(/10,?000\+/);
    expect(body).not.toMatch(/4\.9\s*\/\s*5/);
    expect(body).not.toMatch(/loved by content creators/i);
  });

  test("no sign-in is offered anywhere on the landing page", async ({ page }) => {
    await page.goto("/");
    const body = await page.locator("body").innerText();
    expect(body).not.toMatch(/sign in with google/i);
    expect(body).not.toMatch(/create an account/i);
  });

  test("the deleted auth endpoints are gone", async ({ request }) => {
    for (const path of ["/api/auth/me", "/api/auth/google", "/api/pro/entitlement"]) {
      const response = await request.get(path);
      expect(response.status(), `${path} should not exist`).toBe(404);
    }
  });

  test("privacy policy states that no email is collected", async ({ page }) => {
    await page.goto("/privacy");
    await expect(page.locator("body")).toContainText(/no user accounts/i);
  });

  test("the browser creation tools are gone entirely", async ({ request }) => {
    // The web is the landing page plus the admin dashboard; creating happens in
    // the apps, which render on-device.
    for (const path of ["/editor", "/batch", "/html-to-video"]) {
      const response = await request.get(path);
      expect(response.status(), `${path} should be removed`).toBe(404);
    }
  });

  test("the web-only export and upload APIs are gone", async ({ request }) => {
    for (const path of ["/api/exports", "/api/uploads/image", "/api/convert/audio"]) {
      const response = await request.post(path, { data: {} });
      expect(response.status(), `${path} should be removed`).toBe(404);
    }
  });

  test("the API the mobile apps depend on is still served", async ({ request }) => {
    // HTML → Video renders server-side on every platform except macOS, so this
    // route must survive the web cleanup. Unauthenticated but rate-limited: an
    // empty body is a 400, never a 404.
    const response = await request.post("/api/convert/html", { data: {} });
    expect(response.status()).not.toBe(404);
  });

  test("the admin panel redirects to its login when signed out", async ({ page }) => {
    await page.goto("/admin");
    await expect(page).toHaveURL(/\/admin\/login/);
    await expect(page.getByRole("heading", { name: /Admin/i })).toBeVisible();
  });
});

test.describe("anonymous tracking", () => {
  test("the session beacon accepts a device id", async ({ request }) => {
    const response = await request.post("/api/track", {
      data: {
        clientId: `e2e-${Date.now()}`,
        deviceId: "d-e2e-device",
        event: "start",
        platform: "web",
        isPro: false,
      },
    });
    expect(response.status()).toBe(202);
  });

  test("the export beacon records without any credentials", async ({ request }) => {
    const response = await request.post("/api/exports/record", {
      data: { presetId: "9x16", duration: 12, tool: "create", platform: "web" },
      headers: { "x-stillora-device": "d-e2e-device" },
    });
    expect(response.status()).toBe(201);
  });

  test("the crash endpoint never fails a client, flood or not", async ({ request }) => {
    const first = await request.post("/api/errors", {
      data: { source: "e2e/smoke", message: "smoke test error", platform: "web" },
    });
    expect(first.status()).toBe(202);

    // Over the limit the report is dropped silently rather than rejected: a
    // client that retries a failed crash report only makes the flood worse.
    // That contract has to hold whatever ERROR_REPORT_RATE_LIMIT is set to.
    for (let i = 0; i < 40; i++) {
      const response = await request.post("/api/errors", {
        data: { source: "e2e/flood", message: `flood ${i}`, platform: "web" },
      });
      expect(response.status(), `report ${i}`).toBe(202);
    }
  });
});
