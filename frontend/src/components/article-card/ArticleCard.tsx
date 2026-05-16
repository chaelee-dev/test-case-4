import { Link } from "react-router-dom";
import type { Article } from "@/lib/api/schemas";

export interface ArticleCardProps {
  article: Article;
  onToggleFavorite?: (slug: string, favorited: boolean) => void;
}

export function ArticleCard({ article, onToggleFavorite }: ArticleCardProps) {
  const date = new Date(article.createdAt).toLocaleDateString();
  return (
    <article className="card">
      <header className="mb-2 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Link to={`/profile/${article.author.username}`} className="text-primary font-medium">
            {article.author.username}
          </Link>
          <span className="text-xs text-neutral-muted">{date}</span>
        </div>
        <button
          className={article.favorited ? "btn-primary text-xs" : "btn-outline text-xs"}
          onClick={() => onToggleFavorite?.(article.slug, article.favorited)}
        >
          ♥ {article.favoritesCount}
        </button>
      </header>
      <Link to={`/article/${article.slug}`} className="block">
        <h2 className="text-xl font-semibold">{article.title}</h2>
        <p className="text-neutral-muted">{article.description}</p>
        <div className="mt-2 flex flex-wrap gap-1">
          {article.tagList.map((t) => (
            <span key={t} className="tag-pill">
              {t}
            </span>
          ))}
        </div>
      </Link>
    </article>
  );
}
