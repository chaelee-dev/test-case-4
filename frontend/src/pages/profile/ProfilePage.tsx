import { useCallback, useEffect, useState } from "react";
import { Link, NavLink, useLocation, useParams } from "react-router-dom";
import { articlesApi } from "@/lib/api/endpoints/articles";
import { profilesApi } from "@/lib/api/endpoints/profiles";
import type { Article, Profile } from "@/lib/api/schemas";
import { ArticleCard } from "@/components/article-card/ArticleCard";
import { Pagination } from "@/components/pagination/Pagination";
import { useAuth } from "@/lib/auth/AuthContext";

const PAGE_SIZE = 10;

export function ProfilePage() {
  const { user } = useAuth();
  const { username } = useParams();
  const location = useLocation();
  const isFavoritedTab = location.pathname.endsWith("/favorites");
  const [profile, setProfile] = useState<Profile | null>(null);
  const [articles, setArticles] = useState<Article[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(0);
  const [notFound, setNotFound] = useState(false);

  const loadProfile = useCallback(async () => {
    if (!username) return;
    try {
      const p = await profilesApi.get(username);
      setProfile(p);
      setNotFound(false);
    } catch {
      setNotFound(true);
    }
  }, [username]);

  const loadArticles = useCallback(async () => {
    if (!username) return;
    const query = { limit: PAGE_SIZE, offset: page * PAGE_SIZE };
    const res = isFavoritedTab
      ? await articlesApi.list({ ...query, favorited: username })
      : await articlesApi.list({ ...query, author: username });
    setArticles(res.articles);
    setTotal(res.articlesCount);
  }, [username, page, isFavoritedTab]);

  useEffect(() => {
    void loadProfile();
  }, [loadProfile]);

  useEffect(() => {
    void loadArticles();
  }, [loadArticles]);

  async function onToggleFollow() {
    if (!profile) return;
    const next = profile.following
      ? await profilesApi.unfollow(profile.username)
      : await profilesApi.follow(profile.username);
    setProfile(next);
  }

  if (notFound) {
    return (
      <div className="container mx-auto max-w-3xl p-8">
        <h2 className="text-xl font-semibold">Profile not found</h2>
        <Link to="/" className="text-primary">Back to home</Link>
      </div>
    );
  }

  if (!profile) return <div className="container mx-auto p-8 text-neutral-muted">Loading profile…</div>;

  const isOwn = user?.username === profile.username;

  return (
    <>
      <section className="bg-neutral-bg border-b border-border py-8 text-center">
        <h1 className="text-3xl font-semibold">{profile.username}</h1>
        {profile.bio && <p className="mt-2 text-neutral-muted">{profile.bio}</p>}
        <div className="mt-4">
          {isOwn ? (
            <Link to="/settings" className="btn-outline text-xs">Edit Profile Settings</Link>
          ) : (
            <button onClick={onToggleFollow} className={profile.following ? "btn-primary text-xs" : "btn-outline text-xs"}>
              {profile.following ? "Unfollow" : "Follow"} {profile.username}
            </button>
          )}
        </div>
      </section>

      <div className="container mx-auto max-w-3xl p-4">
        <ul className="mb-4 flex gap-3 border-b border-border text-sm">
          <li>
            <NavLink
              to={`/profile/${profile.username}`}
              end
              className={({ isActive }) =>
                `-mb-px border-b-2 px-2 py-2 ${isActive ? "border-primary text-primary" : "border-transparent text-neutral-muted"}`
              }
            >
              My Articles
            </NavLink>
          </li>
          <li>
            <NavLink
              to={`/profile/${profile.username}/favorites`}
              className={({ isActive }) =>
                `-mb-px border-b-2 px-2 py-2 ${isActive ? "border-primary text-primary" : "border-transparent text-neutral-muted"}`
              }
            >
              Favorited Articles
            </NavLink>
          </li>
        </ul>

        {articles.length === 0 ? (
          <p className="text-neutral-muted">No articles are here ... yet.</p>
        ) : (
          articles.map((a) => <ArticleCard key={a.slug} article={a} />)
        )}

        <Pagination total={total} pageSize={PAGE_SIZE} currentPage={page} onSelect={setPage} />
      </div>
    </>
  );
}
