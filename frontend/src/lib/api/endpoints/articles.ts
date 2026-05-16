import { api } from "@/lib/api/client";
import {
  articleResponseSchema,
  articlesResponseSchema,
} from "@/lib/api/schemas";

export interface ArticleListQuery {
  tag?: string;
  author?: string;
  favorited?: string;
  limit?: number;
  offset?: number;
}

function toSearchParams(q: ArticleListQuery): URLSearchParams {
  const params = new URLSearchParams();
  if (q.tag) params.set("tag", q.tag);
  if (q.author) params.set("author", q.author);
  if (q.favorited) params.set("favorited", q.favorited);
  if (q.limit != null) params.set("limit", String(q.limit));
  if (q.offset != null) params.set("offset", String(q.offset));
  return params;
}

export const articlesApi = {
  async list(query: ArticleListQuery = {}) {
    const json = await api.get("articles", { searchParams: toSearchParams(query) }).json();
    return articlesResponseSchema.parse(json);
  },
  async feed(query: { limit?: number; offset?: number } = {}) {
    const json = await api.get("articles/feed", { searchParams: toSearchParams(query) }).json();
    return articlesResponseSchema.parse(json);
  },
  async get(slug: string) {
    const json = await api.get(`articles/${slug}`).json();
    return articleResponseSchema.parse(json).article;
  },
  async create(payload: { title: string; description: string; body: string; tagList: string[] }) {
    const json = await api.post("articles", { json: { article: payload } }).json();
    return articleResponseSchema.parse(json).article;
  },
  async update(slug: string, payload: Partial<{ title: string; description: string; body: string; tagList: string[] }>) {
    const json = await api.put(`articles/${slug}`, { json: { article: payload } }).json();
    return articleResponseSchema.parse(json).article;
  },
  async remove(slug: string) {
    await api.delete(`articles/${slug}`);
  },
  async favorite(slug: string) {
    const json = await api.post(`articles/${slug}/favorite`).json();
    return articleResponseSchema.parse(json).article;
  },
  async unfavorite(slug: string) {
    const json = await api.delete(`articles/${slug}/favorite`).json();
    return articleResponseSchema.parse(json).article;
  },
};
