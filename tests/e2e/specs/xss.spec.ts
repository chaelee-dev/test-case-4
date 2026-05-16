import { expect, test } from "@playwright/test";

test.describe("xss safety", () => {
  test("no script execution from any rendered markdown content", async ({ page }) => {
    let alertFired = false;
    page.on("dialog", (dialog) => {
      alertFired = true;
      void dialog.dismiss();
    });
    await page.goto("/");
    await page.waitForLoadState("networkidle");
    expect(alertFired).toBe(false);
  });
});
