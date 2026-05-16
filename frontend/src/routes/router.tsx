import { createBrowserRouter } from "react-router-dom";
import { App } from "@/App";
import { LoginPage } from "@/pages/login/LoginPage";
import { RegisterPage } from "@/pages/register/RegisterPage";
import { ProtectedRoute } from "@/routes/ProtectedRoute";

function Placeholder({ name }: { name: string }) {
  return <div className="container mx-auto max-w-4xl p-8">{name} page — coming soon</div>;
}

export const router = createBrowserRouter([
  {
    path: "/",
    element: <App />,
    children: [
      { index: true, element: <Placeholder name="Home" /> },
      { path: "login", element: <LoginPage /> },
      { path: "register", element: <RegisterPage /> },
      { path: "settings", element: <ProtectedRoute><Placeholder name="Settings" /></ProtectedRoute> },
      { path: "editor", element: <ProtectedRoute><Placeholder name="Editor (new)" /></ProtectedRoute> },
      { path: "editor/:slug", element: <ProtectedRoute><Placeholder name="Editor (edit)" /></ProtectedRoute> },
      { path: "article/:slug", element: <Placeholder name="Article" /> },
      { path: "profile/:username", element: <Placeholder name="Profile" /> },
      { path: "profile/:username/favorites", element: <Placeholder name="Profile Favorited" /> },
    ],
  },
]);
