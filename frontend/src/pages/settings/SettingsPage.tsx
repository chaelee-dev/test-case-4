import { FormEvent, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "@/lib/auth/AuthContext";
import { usersApi } from "@/lib/api/endpoints/users";
import { unwrapApiError } from "@/lib/api/client";
import { ErrorList } from "@/components/error-list/ErrorList";

export function SettingsPage() {
  const { user, setUser, logout } = useAuth();
  const navigate = useNavigate();
  const [image, setImage] = useState(user?.image ?? "");
  const [username, setUsername] = useState(user?.username ?? "");
  const [bio, setBio] = useState(user?.bio ?? "");
  const [email, setEmail] = useState(user?.email ?? "");
  const [password, setPassword] = useState("");
  const [errors, setErrors] = useState<Record<string, string[]> | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setSubmitting(true);
    setErrors(null);
    try {
      const payload: Record<string, string> = {};
      if (image !== (user?.image ?? "")) payload.image = image;
      if (username !== user?.username) payload.username = username;
      if (bio !== (user?.bio ?? "")) payload.bio = bio;
      if (email !== user?.email) payload.email = email;
      if (password.length > 0) payload.password = password;
      if (Object.keys(payload).length === 0) {
        setErrors({ user: ["nothing changed"] });
        return;
      }
      const updated = await usersApi.update(payload);
      setUser(updated);
    } catch (e) {
      setErrors(await unwrapApiError(e));
    } finally {
      setSubmitting(false);
    }
  }

  function onLogout() {
    logout();
    navigate("/");
  }

  return (
    <div className="container mx-auto max-w-lg p-8">
      <h1 className="mb-6 text-center text-3xl font-light">Your Settings</h1>
      <ErrorList errors={errors} />
      <form onSubmit={onSubmit} className="space-y-3">
        <input className="input" placeholder="URL of profile picture" value={image} onChange={(e) => setImage(e.target.value)} />
        <input className="input" placeholder="Username" value={username} onChange={(e) => setUsername(e.target.value)} />
        <textarea className="input min-h-32" placeholder="Short bio about you" value={bio} onChange={(e) => setBio(e.target.value)} />
        <input className="input" type="email" placeholder="Email" value={email} onChange={(e) => setEmail(e.target.value)} />
        <input className="input" type="password" placeholder="New password (leave blank to keep)" value={password} onChange={(e) => setPassword(e.target.value)} />
        <button className="btn-primary w-full" type="submit" disabled={submitting}>
          {submitting ? "Saving..." : "Update Settings"}
        </button>
      </form>
      <hr className="my-6 border-border" />
      <button className="btn-danger w-full" onClick={onLogout}>
        Or click here to logout.
      </button>
    </div>
  );
}
