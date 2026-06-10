"use client";

import { useEffect } from "react";

/** Áp dụng theme từ localStorage sau mount — tránh script tag trong layout gây hydration warning. */
export function ThemeInit() {
  useEffect(() => {
    try {
      const stored = localStorage.getItem("unimove-theme");
      const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
      const isDark = stored === "dark" || (!stored && prefersDark);
      document.documentElement.classList.toggle("dark", isDark);
    } catch {
      /* ignore */
    }
  }, []);

  return null;
}
