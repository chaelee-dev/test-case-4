import ky, { type KyInstance, HTTPError } from "ky";
import { tokenStorage } from "@/lib/auth/storage";

const API_BASE_URL: string =
  (import.meta as unknown as { env?: { VITE_API_BASE_URL?: string } }).env?.VITE_API_BASE_URL ??
  "/api";

type UnauthorizedHandler = () => void;
let unauthorizedHandler: UnauthorizedHandler | null = null;

export function setUnauthorizedHandler(handler: UnauthorizedHandler | null): void {
  unauthorizedHandler = handler;
}

export const api: KyInstance = ky.create({
  prefixUrl: API_BASE_URL,
  hooks: {
    beforeRequest: [
      (request) => {
        const token = tokenStorage.get();
        if (token) {
          request.headers.set("Authorization", `Token ${token}`);
        }
      },
    ],
    afterResponse: [
      async (_request, _options, response) => {
        if (response.status === 401) {
          tokenStorage.clear();
          unauthorizedHandler?.();
        }
        return response;
      },
    ],
  },
});

export async function unwrapApiError(error: unknown): Promise<Record<string, string[]>> {
  if (error instanceof HTTPError) {
    try {
      const body = (await error.response.clone().json()) as { errors?: Record<string, string[]> };
      if (body && body.errors) return body.errors;
    } catch {
      /* fallthrough */
    }
  }
  return { error: ["network or server error"] };
}
