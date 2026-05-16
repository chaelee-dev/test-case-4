import { api } from "@/lib/api/client";
import { userResponseSchema } from "@/lib/api/schemas";

export const usersApi = {
  async register(username: string, email: string, password: string) {
    const json = await api
      .post("users", { json: { user: { username, email, password } } })
      .json();
    return userResponseSchema.parse(json).user;
  },
  async login(email: string, password: string) {
    const json = await api.post("users/login", { json: { user: { email, password } } }).json();
    return userResponseSchema.parse(json).user;
  },
  async getCurrent() {
    const json = await api.get("user").json();
    return userResponseSchema.parse(json).user;
  },
  async update(payload: { email?: string; username?: string; password?: string; bio?: string; image?: string }) {
    const json = await api.put("user", { json: { user: payload } }).json();
    return userResponseSchema.parse(json).user;
  },
};
