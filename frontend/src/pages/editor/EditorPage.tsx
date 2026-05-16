import { FormEvent, useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { articlesApi } from "@/lib/api/endpoints/articles";
import { unwrapApiError } from "@/lib/api/client";
import { ErrorList } from "@/components/error-list/ErrorList";
import { TagInput } from "@/components/tag-input/TagInput";

export function EditorPage() {
  const { slug } = useParams();
  const navigate = useNavigate();
  const isEdit = Boolean(slug);

  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [body, setBody] = useState("");
  const [tagList, setTagList] = useState<string[]>([]);
  const [errors, setErrors] = useState<Record<string, string[]> | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [loading, setLoading] = useState(isEdit);

  useEffect(() => {
    if (!slug) return;
    articlesApi
      .get(slug)
      .then((a) => {
        setTitle(a.title);
        setDescription(a.description);
        setBody(a.body);
        setTagList(a.tagList);
      })
      .catch(() => navigate("/"))
      .finally(() => setLoading(false));
  }, [slug, navigate]);

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setSubmitting(true);
    setErrors(null);
    try {
      const payload = { title, description, body, tagList };
      const article = isEdit
        ? await articlesApi.update(slug!, payload)
        : await articlesApi.create(payload);
      navigate(`/article/${article.slug}`);
    } catch (e) {
      setErrors(await unwrapApiError(e));
    } finally {
      setSubmitting(false);
    }
  }

  if (loading) {
    return <div className="container mx-auto p-8 text-neutral-muted">Loading editor…</div>;
  }

  return (
    <div className="container mx-auto max-w-3xl p-8">
      <ErrorList errors={errors} />
      <form onSubmit={onSubmit} className="space-y-3">
        <input className="input" placeholder="Article Title" required value={title} onChange={(e) => setTitle(e.target.value)} />
        <input className="input" placeholder="What's this article about?" required value={description} onChange={(e) => setDescription(e.target.value)} />
        <textarea
          className="input min-h-64 font-mono text-sm"
          placeholder="Write your article (in markdown)"
          required
          value={body}
          onChange={(e) => setBody(e.target.value)}
        />
        <TagInput value={tagList} onChange={setTagList} />
        <button className="btn-primary" type="submit" disabled={submitting}>
          {submitting ? "Publishing..." : isEdit ? "Update Article" : "Publish Article"}
        </button>
      </form>
    </div>
  );
}
