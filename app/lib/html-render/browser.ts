import http from "node:http";
import type { AddressInfo } from "node:net";
import puppeteer, { type Browser, type CDPSession, type Page } from "puppeteer";

import { RenderError, isPrivateHost } from "./options";

/** Max time to wait for Chromium to launch before failing fast (vs. hanging). */
const BROWSER_LAUNCH_TIMEOUT_MS = 30_000;

let browserPromise: Promise<Browser> | null = null;

/** Lazily launches a shared headless Chromium and reuses it across requests. */
export async function getBrowser(): Promise<Browser> {
  // Reuse the existing browser only if it's still connected; a crashed/closed
  // browser would otherwise hang every later request until it times out.
  if (browserPromise) {
    try {
      const existing = await browserPromise;
      if (existing.connected) return existing;
    } catch {
      // Fall through and relaunch below.
    }
    browserPromise = null;
  }
  if (!browserPromise) {
    browserPromise = withTimeout(
      puppeteer.launch({
        headless: true,
        args: [
          "--no-sandbox",
          "--disable-setuid-sandbox",
          "--disable-dev-shm-usage",
          "--disable-gpu",
          "--hide-scrollbars",
          "--force-color-profile=srgb",
        ],
        executablePath: process.env.PUPPETEER_EXECUTABLE_PATH || undefined,
      }),
      BROWSER_LAUNCH_TIMEOUT_MS,
      "Chromium took too long to start. Please try again.",
    ).catch((error) => {
      // Never cache a failed/timed-out launch — the next request retries fresh.
      browserPromise = null;
      throw error;
    });
  }
  return browserPromise;
}

/** Advances the page's virtual clock by `budgetMs` and waits for it to elapse. */
export function advanceVirtualTime(client: CDPSession, budgetMs: number) {
  return new Promise<void>((resolve, reject) => {
    let settled = false;
    const done = () => {
      if (settled) return;
      settled = true;
      resolve();
    };
    client.once("Emulation.virtualTimeBudgetExpired", done);
    client
      .send("Emulation.setVirtualTimePolicy", {
        policy: "advance",
        budget: budgetMs,
        maxVirtualTimeTaskStarvationCount: 1_000_000,
      })
      .catch((error) => {
        if (settled) return;
        settled = true;
        reject(error);
      });
  });
}

export async function blockUnsafeRequests(page: Page, allowedOrigin: string | null) {
  await page.setRequestInterception(true);
  page.on("request", (request) => {
    const reqUrl = request.url();
    if (reqUrl.startsWith("data:") || reqUrl.startsWith("blob:")) {
      void request.continue();
      return;
    }
    try {
      const parsed = new URL(reqUrl);
      // The loopback origin we serve the user's own HTML from is always allowed.
      if (allowedOrigin && parsed.origin === allowedOrigin) {
        void request.continue();
        return;
      }
      const httpScheme =
        parsed.protocol === "http:" || parsed.protocol === "https:";
      if (!httpScheme || isPrivateHost(parsed.hostname)) {
        void request.abort();
        return;
      }
    } catch {
      void request.abort();
      return;
    }
    void request.continue();
  });
}

export type LocalServer = { origin: string; close: () => Promise<void> };

/**
 * Serves the HTML over an ephemeral loopback origin. Navigating to a real
 * `http://` URL (rather than `setContent`, whose base is `about:blank`) lets the
 * page's `fetch`, blob URLs, web workers, and relative asset URLs resolve — which
 * bundled/self-unpacking exports depend on to render at all.
 */
export function startLocalServer(html: string): Promise<LocalServer> {
  return new Promise((resolve, reject) => {
    const server = http.createServer((_req, res) => {
      res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
      res.end(html);
    });
    server.once("error", reject);
    server.listen(0, "127.0.0.1", () => {
      const { port } = server.address() as AddressInfo;
      resolve({
        origin: `http://127.0.0.1:${port}`,
        close: () =>
          new Promise<void>((done) => server.close(() => done())),
      });
    });
  });
}

export function delay(ms: number) {
  return new Promise<void>((resolve) => setTimeout(resolve, ms));
}

/** Rejects with a RenderError if [promise] doesn't settle within [ms]. */
export function withTimeout<T>(promise: Promise<T>, ms: number, message: string) {
  return new Promise<T>((resolve, reject) => {
    const timer = setTimeout(() => reject(new RenderError(message, 504)), ms);
    promise.then(
      (value) => {
        clearTimeout(timer);
        resolve(value);
      },
      (error) => {
        clearTimeout(timer);
        reject(error);
      },
    );
  });
}
