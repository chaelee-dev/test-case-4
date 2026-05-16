import { useCallback, useEffect, useState } from "react";
import { useAuth } from "@/lib/auth/AuthContext";
import { articlesApi } from "@/lib/api/endpoints/articles";
import type { Article } from "@/lib/api/schemas";
import { ArticleCard } from "@/components/article-card/ArticleCard";
import { Pagination } from "@/components/pagination/Pagination";
import { PopularTagsSidebar } from "@/components/popular-tags/PopularTagsSidebar";

type Tab = "your" | "global" | { tag: string };

const PAGE_SIZE = 10;

export function HomePage() {
  const { user } = useAuth();
  const [tab, setTab] = useState<Tab>(user ? "your" : "global");
  const [articles, setArticles] = useState<Article[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(0);
  const [loading, setLoading] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const query = { limit: PAGE_SIZE, offset: page * PAGE_SIZE };
      if (tab === "your") {
        const res = await articlesApi.feed(query);
        setArticles(res.articles);
        setTotal(res.articlesCount);
      } else if (tab === "global") {
        const res = await articlesApi.list(query);
        setArticles(res.articles);
        setTotal(res.articlesCount);
      } else {
        const res = await articlesApi.list({ ...query, tag: tab.tag });
        setArticles(res.articles);
        setTotal(res.articlesCount);
      }
    } catch {
      setArticles([]);
      setTotal(0);
    } finally {
      setLoading(false);
    }
  }, [tab, page]);

  useEffect(() => {
    void load();
  }, [load]);

  function chooseTab(next: Tab) {
    setPage(0);
    setTab(next);
  }

  async function onToggleFavorite(slug: string, favorited: boolean) {
    const updated = favorited
      ? await articlesApi.unfavorite(slug)
      : await articlesApi.favorite(slug);
    setArticles((prev) => prev.map((a) => (a.slug === slug ? updated : a)));
  }

  return (
    <>
      <section className="bg-primary py-12 text-center text-white shadow-inner">
        <h1 className="text-5xl font-bold">conduit</h1>
        <p className="mt-2 text-xl">A place to share your knowledge.</p>
      </section>

      <div className="container mx-auto grid max-w-5xl gap-6 p-4 md:grid-cols-[1fr_240px]">
        <div>
          <ul className="mb-4 flex gap-3 border-b border-border text-sm">
            {user && (
              <li>
                <button
                  onClick={() => chooseTab("your")}
                  className={`-mb-px border-b-2 px-2 py-2 ${tab === "your" ? "border-primary text-primary" : "border-transparent text-neutral-muted"}`}
                >
                  Your Feed
                </button>
              </li>
            )}
            <li>
              <button
                onClick={() => chooseTab("global")}
                className={`-mb-px border-b-2 px-2 py-2 ${tab === "global" ? "border-primary text-primary" : "border-transparent text-neutral-muted"}`}
              >
                Global Feed
              </button>
            </li>
            {typeof tab === "object" && (
              <li>
                <span className="-mb-px border-b-2 border-primary px-2 py-2 text-primary"># {tab.tag}</span>
              </li>
            )}
          </ul>

          {loading ? (
            <p className="text-neutral-muted">Loading articles…</p>
          ) : articles.length === 0 ? (
            <p className="text-neutral-muted">No articles are here ... yet.</p>
          ) : (
            articles.map((a) => <ArticleCard key={a.slug} article={a} onToggleFavorite={onToggleFavorite} />)
          )}

          <Pagination total={total} pageSize={PAGE_SIZE} currentPage={page} onSelect={setPage} />
        </div>

        <PopularTagsSidebar onSelectTag={(tag) => chooseTab({ tag })} />
      </div>
    </>
  );
}
