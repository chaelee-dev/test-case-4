import { createBrowserRouter } from "react-router-dom";
import { App } from "@/App";
import { ArticlePage } from "@/pages/article/ArticlePage";
import { EditorPage } from "@/pages/editor/EditorPage";
import { HomePage } from "@/pages/home/HomePage";
import { LoginPage } from "@/pages/login/LoginPage";
import { ProfilePage } from "@/pages/profile/ProfilePage";
import { RegisterPage } from "@/pages/register/RegisterPage";
import { SettingsPage } from "@/pages/settings/SettingsPage";
import { ProtectedRoute } from "@/routes/ProtectedRoute";

function Placeholder({ name }: { name: string }) {
  return <div className="container mx-auto max-w-4xl p-8">{name} page — coming soon</div>;
}

export const router = createBrowserRouter([
  {
    path: "/",
    element: <App />,
    children: [
      { index: true, element: <HomePage /> },
      { path: "login", element: <LoginPage /> },
      { path: "register", element: <RegisterPage /> },
      { path: "settings", element: <ProtectedRoute><SettingsPage /></ProtectedRoute> },
      { path: "editor", element: <ProtectedRoute><EditorPage /></ProtectedRoute> },
      { path: "editor/:slug", element: <ProtectedRoute><EditorPage /></ProtectedRoute> },
      { path: "article/:slug", element: <ArticlePage /> },
      { path: "profile/:username", element: <ProfilePage /> },
      { path: "profile/:username/favorites", element: <ProfilePage /> },
    ],
  },
]);
