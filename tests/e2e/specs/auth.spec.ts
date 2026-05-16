import { expect, test } from "@playwright/test";

test.describe("auth", () => {
  test("register form renders all fields", async ({ page }) => {
    await page.goto("/register");
    await expect(page.locator("h1", { hasText: /sign up/i })).toBeVisible();
    await expect(page.locator('input[placeholder="Username"]')).toBeVisible();
    await expect(page.locator('input[placeholder="Email"]')).toBeVisible();
    await expect(page.locator('input[placeholder="Password"]')).toBeVisible();
  });

  test("login form renders", async ({ page }) => {
    await page.goto("/login");
    await expect(page.locator("h1", { hasText: /sign in/i })).toBeVisible();
  });

  test("protected route redirects to login with redirect query", async ({ page }) => {
    await page.goto("/settings");
    await expect(page).toHaveURL(/login\?redirect=/);
  });
});
