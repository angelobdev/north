// vite.config.js
import react from "@vitejs/plugin-react";
import { resolve } from "path";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [react()],
  server: {
    watch: {
      usePolling: true,
    },
    host: true,
    strictPort: true,
    port: 5173,
  },
  resolve: {
    alias: {
      "@": resolve(__dirname, "src"),
      "~": resolve(__dirname, "node_modules"),
    },
  },
  build: {
    assetsInlineLimit: 102400,
    rollupOptions: {
      output: {
        assetFileNames: "src/assets/[name].[ext]",
        manualChunks: (id) => {
          if (id.includes("node_modules")) {
            if (id.includes("@nitrots/nitro-renderer")) return "nitro-renderer";

            return "vendor";
          }
        },
      },
    },
  },
});
