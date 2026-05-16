import { expect, test } from "@playwright/test";

test.describe("home", () => {
  test("loads banner and global feed tab", async ({ page }) => {
    await page.goto("/");
    await expect(page.locator("h1", { hasText: /conduit/i })).toBeVisible();
    await expect(page.locator("text=Global Feed")).toBeVisible();
  });

  test("anonymous header shows sign in / sign up", async ({ page }) => {
    await page.goto("/");
    await expect(page.getByRole("link", { name: /sign in/i })).toBeVisible();
    await expect(page.getByRole("link", { name: /sign up/i })).toBeVisible();
  });
});
