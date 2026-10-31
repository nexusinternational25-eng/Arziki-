import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    // Les tests des règles partagent un émulateur : on les lance l'un après l'autre.
    fileParallelism: false,
    testTimeout: 20000,
  },
});
