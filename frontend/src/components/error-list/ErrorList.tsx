export interface ErrorListProps {
  errors: Record<string, string[]> | null;
}

export function ErrorList({ errors }: ErrorListProps) {
  if (!errors) return null;
  const flat = Object.entries(errors).flatMap(([field, msgs]) => msgs.map((m) => `${field} ${m}`));
  if (flat.length === 0) return null;
  return (
    <ul role="alert" className="mb-4 list-disc rounded border border-danger bg-red-50 p-3 text-sm text-danger">
      {flat.map((m) => (
        <li key={m}>{m}</li>
      ))}
    </ul>
  );
}
