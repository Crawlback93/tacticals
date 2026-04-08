import { test, expect, Page } from '@playwright/test';

async function waitForFlutter(page: Page) {
  await page.waitForLoadState('networkidle', { timeout: 30_000 });
  // Click Flutter's built-in accessibility toggle button.
  // This causes Flutter to build its full semantic overlay (aria-label tree).
  const placeholder = page.locator('flt-semantics-placeholder');
  await placeholder.waitFor({ state: 'attached', timeout: 10_000 });
  await placeholder.click();
  // Wait for the semantic overlay DOM to be built and the toolbar open-animation to finish
  await page.waitForTimeout(2_000);
}

async function getSemanticRect(page: Page, label: string) {
  const el = page.locator(`[aria-label="${label}"]`).first();
  await el.waitFor({ state: 'visible', timeout: 10_000 });
  return el.boundingBox();
}

test.describe('Drawing Pad', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await waitForFlutter(page);
  });

  test('drawing toolbar is open at the bottom by default', async ({ page }) => {
    const toolbar = page.locator('[aria-label="drawing-toolbar-bottom"]').first();
    await expect(toolbar).toBeVisible({ timeout: 8_000 });
    await expect(page).toHaveScreenshot('toolbar-open-bottom.png', { maxDiffPixelRatio: 0.02 });
  });

  test('dragging toolbar into the left blue zone flips it to vertical', async ({ page }) => {
    await page.locator('[aria-label="drawing-toolbar-bottom"]').first().waitFor({ state: 'visible' });

    const handleRect = await getSemanticRect(page, 'drawing-toolbar-drag-handle');
    expect(handleRect).not.toBeNull();

    const startX = handleRect!.x + handleRect!.width / 2;
    const startY = handleRect!.y + handleRect!.height / 2;
    const viewportSize = page.viewportSize()!;
    const targetX = viewportSize.width * 0.05;
    const targetY = viewportSize.height * 0.5;

    await page.mouse.move(startX, startY);
    await page.mouse.down();
    for (let i = 1; i <= 25; i++) {
      await page.mouse.move(
        startX + (targetX - startX) * (i / 25),
        startY + (targetY - startY) * (i / 25),
      );
      await page.waitForTimeout(16);
    }
    await page.mouse.up();
    await page.waitForTimeout(700);

    await expect(page.locator('[aria-label="drawing-toolbar-left"]').first()).toBeVisible({ timeout: 5_000 });
    await expect(page.locator('[aria-label="drawing-toolbar-bottom"]').first()).not.toBeVisible();
    await expect(page).toHaveScreenshot('toolbar-flipped-left.png', { maxDiffPixelRatio: 0.02 });
  });

  test('dragging toolbar from left zone back to center flips it back to horizontal', async ({ page }) => {
    await page.locator('[aria-label="drawing-toolbar-bottom"]').first().waitFor({ state: 'visible' });
    const viewportSize = page.viewportSize()!;

    const h1 = await getSemanticRect(page, 'drawing-toolbar-drag-handle');
    await page.mouse.move(h1!.x + h1!.width / 2, h1!.y + h1!.height / 2);
    await page.mouse.down();
    const leftX = viewportSize.width * 0.05;
    const leftY = viewportSize.height * 0.5;
    for (let i = 1; i <= 25; i++) {
      await page.mouse.move(
        (h1!.x + h1!.width / 2) + (leftX - (h1!.x + h1!.width / 2)) * (i / 25),
        (h1!.y + h1!.height / 2) + (leftY - (h1!.y + h1!.height / 2)) * (i / 25),
      );
      await page.waitForTimeout(16);
    }
    await page.mouse.up();
    await page.waitForTimeout(700);
    await page.locator('[aria-label="drawing-toolbar-left"]').first().waitFor({ state: 'visible' });

    const h2 = await getSemanticRect(page, 'drawing-toolbar-drag-handle');
    const cx = h2!.x + h2!.width / 2;
    const cy = h2!.y + h2!.height / 2;
    const backX = viewportSize.width * 0.6;
    const backY = viewportSize.height * 0.9;
    await page.mouse.move(cx, cy);
    await page.mouse.down();
    for (let i = 1; i <= 25; i++) {
      await page.mouse.move(cx + (backX - cx) * (i / 25), cy + (backY - cy) * (i / 25));
      await page.waitForTimeout(16);
    }
    await page.mouse.up();
    await page.waitForTimeout(700);

    await expect(page.locator('[aria-label="drawing-toolbar-bottom"]').first()).toBeVisible({ timeout: 5_000 });
    await expect(page.locator('[aria-label="drawing-toolbar-left"]').first()).not.toBeVisible();
    await expect(page).toHaveScreenshot('toolbar-flipped-back-bottom.png', { maxDiffPixelRatio: 0.02 });
  });

  test('floating toolbar follows the cursor during drag', async ({ page }) => {
    await page.locator('[aria-label="drawing-toolbar-bottom"]').first().waitFor({ state: 'visible' });
    const handleRect = await getSemanticRect(page, 'drawing-toolbar-drag-handle');
    const startX = handleRect!.x + handleRect!.width / 2;
    const startY = handleRect!.y + handleRect!.height / 2;

    await page.mouse.move(startX, startY);
    await page.mouse.down();
    await page.mouse.move(startX + 80, startY - 80, { steps: 10 });
    await page.waitForTimeout(150);
    await expect(page).toHaveScreenshot('toolbar-dragging-mid.png', { maxDiffPixelRatio: 0.03 });
    await page.mouse.up();
  });
});
