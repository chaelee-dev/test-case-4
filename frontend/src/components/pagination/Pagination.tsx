export interface PaginationProps {
  total: number;
  pageSize: number;
  currentPage: number; // 0-indexed
  onSelect: (page: number) => void;
}

export function Pagination({ total, pageSize, currentPage, onSelect }: PaginationProps) {
  const pages = Math.max(1, Math.ceil(total / pageSize));
  if (pages <= 1) return null;
  return (
    <nav aria-label="pagination" className="my-4 flex flex-wrap gap-1">
      {Array.from({ length: pages }).map((_, i) => (
        <button
          key={i}
          onClick={() => onSelect(i)}
          aria-current={i === currentPage ? "page" : undefined}
          className={`rounded px-3 py-1 text-sm border ${
            i === currentPage
              ? "bg-primary text-white border-primary"
              : "border-border text-neutral-muted hover:bg-primary/10"
          }`}
        >
          {i + 1}
        </button>
      ))}
    </nav>
  );
}
