import { createBrowserRouter } from "react-router-dom";
import { App } from "@/App";

function Placeholder({ name }: { name: string }) {
  return <div className="container mx-auto max-w-4xl p-8">{name} page — coming soon</div>;
}

export const router = createBrowserRouter([
  {
    path: "/",
    element: <App />,
    children: [
      { index: true, element: <Placeholder name="Home" /> },
      { path: "login", element: <Placeholder name="Login" /> },
      { path: "register", element: <Placeholder name="Register" /> },
      { path: "settings", element: <Placeholder name="Settings" /> },
      { path: "editor", element: <Placeholder name="Editor (new)" /> },
      { path: "editor/:slug", element: <Placeholder name="Editor (edit)" /> },
      { path: "article/:slug", element: <Placeholder name="Article" /> },
      { path: "profile/:username", element: <Placeholder name="Profile" /> },
      { path: "profile/:username/favorites", element: <Placeholder name="Profile Favorited" /> },
    ],
  },
]);
