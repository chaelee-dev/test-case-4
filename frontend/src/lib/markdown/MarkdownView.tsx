import ReactMarkdown from "react-markdown";
import rehypeSanitize from "rehype-sanitize";

export interface MarkdownViewProps {
  source: string;
}

export function MarkdownView({ source }: MarkdownViewProps) {
  return (
    <div className="prose max-w-none">
      <ReactMarkdown rehypePlugins={[rehypeSanitize]}>{source}</ReactMarkdown>
    </div>
  );
}
