import js from "@eslint/js";
import { defineConfig, globalIgnores } from "eslint/config";
import reactHooks from "eslint-plugin-react-hooks";
import globals from "globals";
import tseslint from "typescript-eslint";

export default defineConfig([
  globalIgnores(["dist/**", "dist-static/**", ".next/**", ".vinext/**", "node_modules/**"]),
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ["**/*.{js,mjs,ts,tsx,mts}"],
    languageOptions: {
      globals: { ...globals.browser, ...globals.node },
    },
  },
  {
    files: ["**/*.{ts,tsx}"],
    plugins: { "react-hooks": reactHooks },
    rules: reactHooks.configs.flat.recommended.rules,
  },
]);
