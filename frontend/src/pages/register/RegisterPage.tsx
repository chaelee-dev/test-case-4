import { FormEvent, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "@/lib/auth/AuthContext";
import { usersApi } from "@/lib/api/endpoints/users";
import { unwrapApiError } from "@/lib/api/client";
import { ErrorList } from "@/components/error-list/ErrorList";

export function RegisterPage() {
  const { setUser } = useAuth();
  const [username, setUsername] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [errors, setErrors] = useState<Record<string, string[]> | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const navigate = useNavigate();

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setSubmitting(true);
    setErrors(null);
    try {
      const user = await usersApi.register(username, email, password);
      setUser(user);
      navigate("/");
    } catch (e) {
      setErrors(await unwrapApiError(e));
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="container mx-auto max-w-lg p-8">
      <h1 className="mb-2 text-center text-3xl font-light">Sign up</h1>
      <p className="mb-4 text-center text-sm">
        <Link to="/login" className="text-primary">Have an account?</Link>
      </p>
      <ErrorList errors={errors} />
      <form onSubmit={onSubmit} className="space-y-3">
        <input className="input" placeholder="Username" required value={username} onChange={(e) => setUsername(e.target.value)} />
        <input className="input" type="email" placeholder="Email" required value={email} onChange={(e) => setEmail(e.target.value)} />
        <input className="input" type="password" placeholder="Password" minLength={8} required value={password} onChange={(e) => setPassword(e.target.value)} />
        <button className="btn-primary w-full" type="submit" disabled={submitting}>
          {submitting ? "Signing up..." : "Sign up"}
        </button>
      </form>
    </div>
  );
}
