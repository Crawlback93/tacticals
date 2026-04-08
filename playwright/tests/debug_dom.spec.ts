import { test } from '@playwright/test';

test('dump flutter DOM after load', async ({ page }) => {
  await page.goto('/');
  await page.waitForLoadState('networkidle', { timeout: 30_000 });
  // Give Flutter time to render first frame
  await page.waitForTimeout(3_000);

  // --- check top-level DOM ------------------------------------------------
  const topLevel = await page.evaluate(() =>
    [...document.body.children].map(el => el.tagName + (el.id ? '#' + el.id : '')).join(', ')
  );
  console.log('TOP-LEVEL BODY CHILDREN:', topLevel);

  // --- try shadow DOM traversal ------------------------------------------
  const shadowInfo = await page.evaluate(() => {
    function inspectShadow(root: Document | ShadowRoot, depth = 0): string[] {
      const lines: string[] = [];
      for (const el of Array.from(root.querySelectorAll('*')).slice(0, 20)) {
        const tag = el.tagName.toLowerCase();
        const ariaLabel = el.getAttribute('aria-label');
        const ariaRole = el.getAttribute('role');
        if (ariaLabel || ariaRole || (el as any).shadowRoot) {
          lines.push('  '.repeat(depth) + tag
            + (ariaLabel ? ` [aria-label="${ariaLabel}"]` : '')
            + (ariaRole ? ` [role="${ariaRole}"]` : '')
            + ((el as any).shadowRoot ? ' [has-shadow]' : ''));
        }
        if ((el as any).shadowRoot && depth < 4) {
          lines.push(...inspectShadow((el as any).shadowRoot, depth + 1));
        }
      }
      return lines;
    }
    return inspectShadow(document);
  });
  console.log('SHADOW DOM STRUCTURE:\n' + shadowInfo.join('\n'));

  // --- try pressing Tab and check again ----------------------------------
  await page.mouse.click(640, 400);
  await page.keyboard.press('Tab');
  await page.waitForTimeout(500);
  await page.keyboard.press('Alt+F2');
  await page.waitForTimeout(2_000);

  const afterA11y = await page.evaluate(() => {
    function inspectShadow(root: Document | ShadowRoot, depth = 0, maxDepth = 5): string[] {
      const lines: string[] = [];
      for (const el of Array.from(root.querySelectorAll('*'))) {
        const tag = el.tagName.toLowerCase();
        const ariaLabel = el.getAttribute('aria-label');
        if (ariaLabel) {
          lines.push('  '.repeat(depth) + `${tag}[aria-label="${ariaLabel}"]`);
        }
        if ((el as any).shadowRoot && depth < maxDepth) {
          lines.push(...inspectShadow((el as any).shadowRoot, depth + 1, maxDepth));
        }
      }
      return lines;
    }
    return inspectShadow(document);
  });
  console.log('AFTER A11Y - aria-label elements:\n' + (afterA11y.length ? afterA11y.join('\n') : '(none found)'));
});
