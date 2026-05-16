import { useEffect, useState } from "react";
import { tagsApi } from "@/lib/api/endpoints/tags";

export interface PopularTagsSidebarProps {
  onSelectTag: (tag: string) => void;
}

export function PopularTagsSidebar({ onSelectTag }: PopularTagsSidebarProps) {
  const [tags, setTags] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    tagsApi
      .list()
      .then(setTags)
      .catch(() => setTags([]))
      .finally(() => setLoading(false));
  }, []);

  return (
    <aside className="rounded border border-border bg-neutral-bg p-3">
      <p className="mb-2 font-medium">Popular Tags</p>
      {loading ? (
        <p className="text-xs text-neutral-muted">Loading…</p>
      ) : tags.length === 0 ? (
        <p className="text-xs text-neutral-muted">No tags yet.</p>
      ) : (
        <div className="flex flex-wrap gap-1">
          {tags.map((t) => (
            <button key={t} onClick={() => onSelectTag(t)} className="tag-pill-active text-xs">
              {t}
            </button>
          ))}
        </div>
      )}
    </aside>
  );
}
