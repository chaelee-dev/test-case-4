import { api } from "@/lib/api/client";
import { tagsResponseSchema } from "@/lib/api/schemas";

export const tagsApi = {
  async list() {
    const json = await api.get("tags").json();
    return tagsResponseSchema.parse(json).tags;
  },
};
