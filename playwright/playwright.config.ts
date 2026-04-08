import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright config for Tactics Board e2e tests.
 *
 * Before running tests make sure the Flutter web dev server is running:
 *   flutter run -d web-server --web-port 8080 --web-renderer html
 *
 * Or build first and serve statically:
 *   flutter build web --web-renderer html
 *   npx serve ../build/web -p 8080
 */
export default defineConfig({
  testDir: './tests',
  timeout: 30_000,
  retries: 1,
  use: {
    baseURL: 'http://localhost:8080',
    // Enable screenshot on failure
    screenshot: 'only-on-failure',
    // Enable video on failure
    video: 'retain-on-failure',
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  // Serve the pre-built Flutter web output.
  // Run `npm run build:e2e` first (or just `npm test` which builds automatically).
  webServer: {
    command: 'npx serve ../build/web -p 8080 --single --no-clipboard',
    port: 8080,
    timeout: 15_000,
    reuseExistingServer: true,
  },
});
