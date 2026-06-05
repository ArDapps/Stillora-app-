"use client";

import { Moon, Sun } from "lucide-react";
import { useSyncExternalStore } from "react";

type Theme = "dark" | "light";

const STORAGE_KEY = "stillora-theme";
const THEME_EVENT = "stillora-theme-change";

function subscribe(onChange: () => void) {
  window.addEventListener(THEME_EVENT, onChange);
  window.addEventListener("storage", onChange);
  return () => {
    window.removeEventListener(THEME_EVENT, onChange);
    window.removeEventListener("storage", onChange);
  };
}

function getSnapshot(): Theme {
  return document.documentElement.classList.contains("light") ? "light" : "dark";
}

function setTheme(theme: Theme) {
  document.documentElement.classList.toggle("light", theme === "light");
  window.localStorage.setItem(STORAGE_KEY, theme);
  window.dispatchEvent(new Event(THEME_EVENT));
}

export function ThemeToggle() {
  // useSyncExternalStore reads the real DOM as the source of truth (set pre-paint
  // by the inline script in layout.tsx), and renders "dark" during SSR/hydration.
  const theme = useSyncExternalStore(subscribe, getSnapshot, () => "dark" as Theme);
  const isDark = theme === "dark";

  return (
    <button
      aria-label={isDark ? "Switch to light theme" : "Switch to dark theme"}
      className="grid size-10 place-items-center rounded-md border border-[var(--color-border)] text-[var(--color-muted)] transition hover:border-[var(--color-primary)] hover:text-[var(--color-foreground)] focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)]"
      onClick={() => setTheme(isDark ? "light" : "dark")}
      type="button"
    >
      {isDark ? <Sun size={18} /> : <Moon size={18} />}
    </button>
  );
}
