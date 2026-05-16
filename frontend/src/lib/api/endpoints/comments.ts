import { api } from "@/lib/api/client";
import { commentResponseSchema, commentsResponseSchema } from "@/lib/api/schemas";

export const commentsApi = {
  async list(slug: string) {
    const json = await api.get(`articles/${slug}/comments`).json();
    return commentsResponseSchema.parse(json).comments;
  },
  async create(slug: string, body: string) {
    const json = await api.post(`articles/${slug}/comments`, { json: { comment: { body } } }).json();
    return commentResponseSchema.parse(json).comment;
  },
  async remove(slug: string, id: number) {
    await api.delete(`articles/${slug}/comments/${id}`);
  },
};
