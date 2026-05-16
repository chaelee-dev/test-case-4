import { z } from "zod";

export const userSchema = z.object({
  email: z.string(),
  token: z.string(),
  username: z.string(),
  bio: z.string().nullable().optional(),
  image: z.string().nullable().optional(),
});

export const userResponseSchema = z.object({ user: userSchema });

export const profileSchema = z.object({
  username: z.string(),
  bio: z.string().nullable().optional(),
  image: z.string().nullable().optional(),
  following: z.boolean(),
});

export const profileResponseSchema = z.object({ profile: profileSchema });

export const articleSchema = z.object({
  slug: z.string(),
  title: z.string(),
  description: z.string(),
  body: z.string(),
  tagList: z.array(z.string()),
  createdAt: z.string(),
  updatedAt: z.string(),
  favorited: z.boolean(),
  favoritesCount: z.number(),
  author: profileSchema,
});

export const articleResponseSchema = z.object({ article: articleSchema });
export const articlesResponseSchema = z.object({
  articles: z.array(articleSchema),
  articlesCount: z.number(),
});

export const commentSchema = z.object({
  id: z.number(),
  body: z.string(),
  createdAt: z.string(),
  updatedAt: z.string(),
  author: profileSchema,
});
export const commentsResponseSchema = z.object({ comments: z.array(commentSchema) });
export const commentResponseSchema = z.object({ comment: commentSchema });

export const tagsResponseSchema = z.object({ tags: z.array(z.string()) });

export type User = z.infer<typeof userSchema>;
export type Profile = z.infer<typeof profileSchema>;
export type Article = z.infer<typeof articleSchema>;
export type Comment = z.infer<typeof commentSchema>;
