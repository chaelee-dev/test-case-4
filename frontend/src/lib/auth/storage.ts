const STORAGE_KEY = "conduit.jwt";

export const tokenStorage = {
  get(): string | null {
    try {
      return localStorage.getItem(STORAGE_KEY);
    } catch {
      return null;
    }
  },
  set(token: string): void {
    try {
      localStorage.setItem(STORAGE_KEY, token);
    } catch {
      /* quota exceeded etc */
    }
  },
  clear(): void {
    try {
      localStorage.removeItem(STORAGE_KEY);
    } catch {
      /* ignore */
    }
  },
};
