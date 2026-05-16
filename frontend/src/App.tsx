import { Outlet } from "react-router-dom";

export function App() {
  return (
    <div className="min-h-screen flex flex-col">
      <main className="flex-1">
        <Outlet />
      </main>
      <footer className="border-t border-border py-4 text-center text-xs text-neutral-muted">
        <a href="/" className="text-primary">conduit</a>. An interactive learning project from{" "}
        <a href="https://thinkster.io" className="text-primary">Thinkster</a>. Code &amp; design licensed under MIT.
      </footer>
    </div>
  );
}
