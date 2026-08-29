import { expect, test, type Page } from "@playwright/test";

/**
 * The landing page's three interactive promises: it adapts to the viewport,
 * it switches between light and dark, and it speaks English, French and Arabic
 * — the last one right-to-left.
 */

/** Elements that must never spill outside the viewport at any width. */
async function horizontalOverflow(page: Page): Promise<number> {
  return page.evaluate(() => {
    const doc = document.documentElement;
    return Math.max(0, doc.scrollWidth - doc.clientWidth);
  });
}

test.describe("responsive", () => {
  const VIEWPORTS = [
    { name: "phone", width: 390, height: 844 },
    { name: "tablet", width: 820, height: 1180 },
    { name: "laptop", width: 1280, height: 800 },
    { name: "wide", width: 1680, height: 1050 },
  ];

  for (const viewport of VIEWPORTS) {
    test(`no sideways scrolling on ${viewport.name} (${viewport.width}px)`, async ({
      page,
    }) => {
      await page.setViewportSize({ width: viewport.width, height: viewport.height });
      await page.goto("/");
      await expect(page.locator(".st-hero")).toBeVisible();

      // A page that scrolls horizontally on a phone is the classic broken
      // responsive symptom; 1px of rounding slack is tolerated.
      const overflow = await horizontalOverflow(page);
      expect(overflow, `${viewport.name} overflows by ${overflow}px`).toBeLessThanOrEqual(1);
    });
  }

  test("content stays in a centred column on very wide screens", async ({ page }) => {
    // Unconstrained, the headline ran to ~900px while the body copy sat in a
    // 350px block at the far left, with a lake of dead space between them.
    await page.setViewportSize({ width: 2560, height: 1000 });
    await page.goto("/");

    const headline = await page.getByRole("heading", { level: 1 }).boundingBox();
    if (!headline) throw new Error("headline not rendered");
    // Content is inset from the edge rather than starting at the section padding.
    expect(headline.x).toBeGreaterThan(300);
    // And it does not sprawl across the whole screen.
    expect(headline.width).toBeLessThan(1000);
  });

  test("the hero and nav stay visible from phone to desktop", async ({ page }) => {
    for (const width of [360, 768, 1440]) {
      await page.setViewportSize({ width, height: 900 });
      await page.goto("/");
      await expect(page.locator(".st-nav"), `nav at ${width}px`).toBeVisible();
      await expect(
        page.getByRole("heading", { level: 1 }),
        `headline at ${width}px`,
      ).toBeVisible();
    }
  });
});

test.describe("light and dark", () => {
  test("the toggle switches theme and the page repaints", async ({ page }) => {
    await page.goto("/");
    const root = page.locator(".st");

    await page.getByRole("button", { name: "☀" }).click();
    await expect(root).toHaveAttribute("data-theme", "light");
    const light = await root.evaluate((el) => getComputedStyle(el).backgroundColor);

    await page.getByRole("button", { name: "☾" }).click();
    await expect(root).toHaveAttribute("data-theme", "dark");
    const dark = await root.evaluate((el) => getComputedStyle(el).backgroundColor);

    // Not just an attribute flip — the tokens behind it have to actually change.
    expect(dark).not.toBe(light);
  });

  test("the chosen theme survives a reload", async ({ page }) => {
    await page.goto("/");
    await page.getByRole("button", { name: "☾" }).click();
    await expect(page.locator(".st")).toHaveAttribute("data-theme", "dark");

    await page.reload();
    await expect(page.locator(".st")).toHaveAttribute("data-theme", "dark");
  });
});

test.describe("button contrast", () => {
  // `.st a { color: inherit }` once outranked the button classes, so every CTA
  // rendered as a link took the surrounding text colour — the hero's primary
  // button was white-on-white in dark mode and dark-on-dark in light.
  for (const theme of ["light", "dark"]) {
    test(`CTA labels are readable in ${theme}`, async ({ page }) => {
      await page.addInitScript((value) => {
        window.localStorage.setItem("stillora-theme", value);
      }, theme);
      await page.goto("/");

      for (const selector of ["a.st-btn", "a.st-btn-grad"]) {
        const button = page.locator(selector).first();
        const { color, background } = await button.evaluate((el) => {
          const style = getComputedStyle(el);
          return { color: style.color, background: style.backgroundColor };
        });
        expect(color, `${selector} in ${theme} is invisible`).not.toBe(background);
      }
    });
  }
});

test.describe("languages", () => {
  test("English, French and Arabic each render their own copy", async ({ page }) => {
    await page.goto("/");

    await page.getByRole("button", { name: "EN", exact: true }).click();
    await expect(page.locator(".st")).toHaveAttribute("lang", "en");
    await expect(page.getByRole("heading", { level: 1 })).toContainText(/Turn your images/i);

    await page.getByRole("button", { name: "FR", exact: true }).click();
    await expect(page.locator(".st")).toHaveAttribute("lang", "fr");
    await expect(page.getByRole("heading", { level: 1 })).toContainText(/Transformez vos images/i);

    await page.getByRole("button", { name: "ع", exact: true }).click();
    await expect(page.locator(".st")).toHaveAttribute("lang", "ar");
    // Arabic script, not a Latin fallback.
    await expect(page.getByRole("heading", { level: 1 })).toContainText(/[؀-ۿ]/);
  });

  test("Arabic lays the page out right-to-left", async ({ page }) => {
    await page.goto("/");
    await expect(page.locator(".st")).toHaveAttribute("dir", "ltr");

    await page.getByRole("button", { name: "ع", exact: true }).click();
    await expect(page.locator(".st")).toHaveAttribute("dir", "rtl");

    const direction = await page
      .locator(".st")
      .evaluate((el) => getComputedStyle(el).direction);
    expect(direction).toBe("rtl");
  });

  test("Arabic does not break the layout on a phone", async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto("/");
    await page.getByRole("button", { name: "ع", exact: true }).click();
    await expect(page.locator(".st")).toHaveAttribute("dir", "rtl");

    // RTL flips every margin and float — the usual place a layout springs a leak.
    const overflow = await horizontalOverflow(page);
    expect(overflow, `Arabic phone layout overflows by ${overflow}px`).toBeLessThanOrEqual(1);
  });

  test("the chosen language survives a reload", async ({ page }) => {
    await page.goto("/");
    await page.getByRole("button", { name: "FR", exact: true }).click();
    await expect(page.locator(".st")).toHaveAttribute("lang", "fr");

    await page.reload();
    await expect(page.locator(".st")).toHaveAttribute("lang", "fr");
  });
});
