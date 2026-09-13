import path from "node:path";
import { defineConfig } from "vitest/config";

export default defineConfig({
  resolve: {
    alias: {
      "@": path.resolve(import.meta.dirname),
    },
  },
  test: {
    coverage: {
      provider: "v8",
      // `include` counts every matching source file, not only the ones a test
      // happened to import. Without it an untested file is simply absent from the
      // report and the number flatters us. (Vitest 4 dropped the old `all` flag;
      // this is now the default behaviour for whatever `include` matches.)
      include: ["lib/**/*.ts", "app/**/*.ts", "app/**/*.tsx", "components/**/*.tsx"],
      exclude: ["**/*.d.ts", "app/layout.tsx"],
      // text-summary for humans, json-summary for the totals, and json for
      // per-line data. json-summary carries only totals, so without "json"
      // there is no way to say which lines are uncovered.
      reporter: ["text-summary", "json-summary", "json"],
      reportsDirectory: "coverage",
      // A ratchet, not a target. These sit just below the current numbers so
      // coverage can never fall, and they are raised as tests land.
      // The 50% destination was reached once the contract tests joined the
      // measured suite. See docs/coverage.md for how to raise them further.
      thresholds: {
        statements: 59,
        branches: 66,
        functions: 49,
        lines: 60,
      },
    },
  },
});
