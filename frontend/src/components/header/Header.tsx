import { NavLink, Link } from "react-router-dom";
import { useAuth } from "@/lib/auth/AuthContext";

function activeClass({ isActive }: { isActive: boolean }) {
  return isActive ? "text-secondary font-semibold" : "text-neutral-muted hover:text-secondary";
}

export function Header() {
  const { user } = useAuth();
  return (
    <header className="border-b border-border bg-white">
      <nav className="container mx-auto flex max-w-5xl items-center justify-between px-4 py-3" aria-label="primary">
        <Link to="/" className="text-2xl font-bold text-primary">
          conduit
        </Link>
        <ul className="flex items-center gap-4 text-sm">
          <li>
            <NavLink to="/" end className={activeClass}>Home</NavLink>
          </li>
          {user ? (
            <>
              <li>
                <NavLink to="/editor" className={activeClass}>New Article</NavLink>
              </li>
              <li>
                <NavLink to="/settings" className={activeClass}>Settings</NavLink>
              </li>
              <li>
                <NavLink to={`/profile/${user.username}`} className={activeClass}>
                  {user.username}
                </NavLink>
              </li>
            </>
          ) : (
            <>
              <li>
                <NavLink to="/login" className={activeClass}>Sign in</NavLink>
              </li>
              <li>
                <NavLink to="/register" className={activeClass}>Sign up</NavLink>
              </li>
            </>
          )}
        </ul>
      </nav>
    </header>
  );
}
