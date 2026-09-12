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
      reporter: ["text-summary", "json-summary"],
      reportsDirectory: "coverage",
      // A ratchet, not a target. These sit just below the current numbers so
      // coverage can never fall, and they are raised as tests land.
      // Destination is 50%. See docs/coverage.md for how to raise them.
      thresholds: {
        statements: 7,
        branches: 0,
        functions: 6,
        lines: 7,
      },
    },
  },
});
