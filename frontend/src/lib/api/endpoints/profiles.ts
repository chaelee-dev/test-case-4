import { api } from "@/lib/api/client";
import { profileResponseSchema } from "@/lib/api/schemas";

export const profilesApi = {
  async get(username: string) {
    const json = await api.get(`profiles/${username}`).json();
    return profileResponseSchema.parse(json).profile;
  },
  async follow(username: string) {
    const json = await api.post(`profiles/${username}/follow`).json();
    return profileResponseSchema.parse(json).profile;
  },
  async unfollow(username: string) {
    const json = await api.delete(`profiles/${username}/follow`).json();
    return profileResponseSchema.parse(json).profile;
  },
};
