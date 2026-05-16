import { describe, expect, it, vi, beforeEach } from "vitest";
import { setUnauthorizedHandler } from "@/lib/api/client";
import { tokenStorage } from "@/lib/auth/storage";

describe("api client", () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it("tokenStorage round-trips token", () => {
    tokenStorage.set("abc.def.ghi");
    expect(tokenStorage.get()).toBe("abc.def.ghi");
    tokenStorage.clear();
    expect(tokenStorage.get()).toBeNull();
  });

  it("setUnauthorizedHandler installs and clears handler", () => {
    const handler = vi.fn();
    setUnauthorizedHandler(handler);
    setUnauthorizedHandler(null);
    expect(handler).not.toHaveBeenCalled();
  });
});
