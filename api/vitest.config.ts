import path from 'node:path';
import { cloudflareTest, readD1Migrations } from '@cloudflare/vitest-plugin';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  plugins: [
    cloudflareTest(async () => {
      const migracoes = await readD1Migrations(path.join(import.meta.dirname, '..', 'db', 'migrations'));
      return {
        wrangler: { configPath: './wrangler.jsonc' },
        miniflare: { bindings: { TEST_MIGRATIONS: migracoes } },
      };
    }),
  ],
  test: {
    setupFiles: ['./test/aplicar-migracoes.ts'],
  },
});
