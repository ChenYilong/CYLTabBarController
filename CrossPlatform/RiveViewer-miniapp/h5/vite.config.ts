import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

export function normalizeBasePath(value = "/rive-viewer/"): string {
  const trimmed = value.trim() || "/";
  const withLeadingSlash = trimmed.startsWith("/") ? trimmed : `/${trimmed}`;
  return withLeadingSlash.endsWith("/") ? withLeadingSlash : `${withLeadingSlash}/`;
}

const base = normalizeBasePath(process.env.RIVE_VIEWER_BASE);

export default defineConfig({
  root: "./static",
  base,
  publicDir: "../public/rive-viewer",
  plugins: [react()],
  server: {
    proxy: {
      "/api": {
        target: process.env.RIVE_HOST_API_ORIGIN || "http://127.0.0.1:8097",
        changeOrigin: false,
      },
    },
  },
  build: {
    outDir: "../dist-static",
    emptyOutDir: true,
    sourcemap: false,
    target: "es2020",
  },
});
