import { KeyboardEvent, useState } from "react";

export interface TagInputProps {
  value: string[];
  onChange: (next: string[]) => void;
}

export function TagInput({ value, onChange }: TagInputProps) {
  const [draft, setDraft] = useState("");

  function addTag(raw: string) {
    const t = raw.trim();
    if (!t) return;
    if (value.includes(t)) return;
    onChange([...value, t]);
  }

  function onKey(e: KeyboardEvent<HTMLInputElement>) {
    if (e.key === "Enter" || e.key === "Tab" || e.key === ",") {
      e.preventDefault();
      addTag(draft);
      setDraft("");
    }
  }

  return (
    <div>
      <input
        className="input"
        placeholder="Enter tags"
        value={draft}
        onChange={(e) => setDraft(e.target.value)}
        onKeyDown={onKey}
      />
      {value.length > 0 && (
        <div className="mt-2 flex flex-wrap gap-1">
          {value.map((t) => (
            <button
              key={t}
              type="button"
              onClick={() => onChange(value.filter((v) => v !== t))}
              className="tag-pill-active text-xs"
              aria-label={`Remove tag ${t}`}
            >
              {t} ×
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
