import { FormEvent, useCallback, useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { articlesApi } from "@/lib/api/endpoints/articles";
import { commentsApi } from "@/lib/api/endpoints/comments";
import { profilesApi } from "@/lib/api/endpoints/profiles";
import type { Article, Comment } from "@/lib/api/schemas";
import { MarkdownView } from "@/lib/markdown/MarkdownView";
import { useAuth } from "@/lib/auth/AuthContext";
import { unwrapApiError } from "@/lib/api/client";
import { ErrorList } from "@/components/error-list/ErrorList";

export function ArticlePage() {
  const { slug } = useParams();
  const navigate = useNavigate();
  const { user } = useAuth();
  const [article, setArticle] = useState<Article | null>(null);
  const [comments, setComments] = useState<Comment[]>([]);
  const [loading, setLoading] = useState(true);
  const [notFound, setNotFound] = useState(false);
  const [body, setBody] = useState("");
  const [errors, setErrors] = useState<Record<string, string[]> | null>(null);

  const load = useCallback(async () => {
    if (!slug) return;
    setLoading(true);
    try {
      const a = await articlesApi.get(slug);
      setArticle(a);
      const list = await commentsApi.list(slug);
      setComments(list);
      setNotFound(false);
    } catch {
      setNotFound(true);
    } finally {
      setLoading(false);
    }
  }, [slug]);

  useEffect(() => {
    void load();
  }, [load]);

  if (loading) return <div className="container mx-auto p-8 text-neutral-muted">Loading article…</div>;
  if (notFound || !article) {
    return (
      <div className="container mx-auto max-w-3xl p-8">
        <h2 className="text-xl font-semibold">Article not found</h2>
        <Link to="/" className="text-primary">Back to home</Link>
      </div>
    );
  }

  const isOwn = user?.username === article.author.username;

  async function onToggleFavorite() {
    if (!article) return;
    const next = article.favorited ? await articlesApi.unfavorite(article.slug) : await articlesApi.favorite(article.slug);
    setArticle(next);
  }

  async function onToggleFollow() {
    if (!article) return;
    const profile = article.author.following
      ? await profilesApi.unfollow(article.author.username)
      : await profilesApi.follow(article.author.username);
    setArticle({ ...article, author: profile });
  }

  async function onDeleteArticle() {
    if (!article || !confirm("Delete this article?")) return;
    await articlesApi.remove(article.slug);
    navigate("/");
  }

  async function onSubmitComment(event: FormEvent) {
    event.preventDefault();
    if (!article || !body.trim()) return;
    try {
      const c = await commentsApi.create(article.slug, body);
      setComments((prev) => [...prev, c]);
      setBody("");
    } catch (e) {
      setErrors(await unwrapApiError(e));
    }
  }

  async function onDeleteComment(id: number) {
    if (!article) return;
    await commentsApi.remove(article.slug, id);
    setComments((prev) => prev.filter((c) => c.id !== id));
  }

  return (
    <>
      <section className="bg-secondary py-12 text-white">
        <div className="container mx-auto max-w-4xl px-4">
          <h1 className="text-4xl font-semibold">{article.title}</h1>
          <div className="mt-4 flex items-center gap-3 text-sm">
            <Link to={`/profile/${article.author.username}`} className="text-white font-medium">
              {article.author.username}
            </Link>
            <span className="text-white/70">{new Date(article.createdAt).toLocaleDateString()}</span>
            {user && !isOwn && (
              <button onClick={onToggleFollow} className={article.author.following ? "btn-primary text-xs" : "btn-outline text-xs"}>
                {article.author.following ? "Unfollow" : "Follow"} {article.author.username}
              </button>
            )}
            {user && !isOwn && (
              <button onClick={onToggleFavorite} className={article.favorited ? "btn-primary text-xs" : "btn-outline text-xs"}>
                ♥ {article.favorited ? "Unfavorite" : "Favorite"} ({article.favoritesCount})
              </button>
            )}
            {isOwn && (
              <>
                <Link to={`/editor/${article.slug}`} className="btn-outline text-xs">Edit Article</Link>
                <button onClick={onDeleteArticle} className="btn-danger text-xs">Delete Article</button>
              </>
            )}
          </div>
        </div>
      </section>

      <article className="container mx-auto max-w-4xl px-4 py-8">
        <MarkdownView source={article.body} />
        <div className="mt-4 flex flex-wrap gap-1">
          {article.tagList.map((t) => (
            <span key={t} className="tag-pill">{t}</span>
          ))}
        </div>
      </article>

      <section className="container mx-auto max-w-3xl px-4 pb-10">
        <h3 className="mb-3 text-lg font-semibold">Comments</h3>
        {user ? (
          <>
            <ErrorList errors={errors} />
            <form onSubmit={onSubmitComment} className="mb-4 rounded border border-border">
              <textarea
                className="block w-full p-3 text-sm focus:outline-none"
                rows={3}
                placeholder="Write a comment..."
                value={body}
                onChange={(e) => setBody(e.target.value)}
              />
              <div className="flex justify-end border-t border-border bg-neutral-bg p-2">
                <button className="btn-primary text-xs" type="submit">Post Comment</button>
              </div>
            </form>
          </>
        ) : (
          <p className="text-sm text-neutral-muted">
            <Link to="/login" className="text-primary">Sign in</Link> or{" "}
            <Link to="/register" className="text-primary">sign up</Link> to add comments on this article.
          </p>
        )}
        <ul className="space-y-2">
          {comments.map((c) => (
            <li key={c.id} className="rounded border border-border">
              <p className="p-3 text-sm">{c.body}</p>
              <footer className="flex items-center justify-between border-t border-border bg-neutral-bg p-2 text-xs text-neutral-muted">
                <span>{c.author.username} · {new Date(c.createdAt).toLocaleDateString()}</span>
                {user?.username === c.author.username && (
                  <button onClick={() => onDeleteComment(c.id)} className="text-danger" aria-label="Delete comment">🗑</button>
                )}
              </footer>
            </li>
          ))}
        </ul>
      </section>
    </>
  );
}
