import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import type { User } from "@/lib/api/schemas";
import { tokenStorage } from "@/lib/auth/storage";
import { setUnauthorizedHandler } from "@/lib/api/client";
import { usersApi } from "@/lib/api/endpoints/users";

interface AuthContextValue {
  user: User | null;
  loading: boolean;
  setUser: (user: User | null) => void;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    const token = tokenStorage.get();
    if (!token) {
      setLoading(false);
      return;
    }
    usersApi
      .getCurrent()
      .then((u) => setUser(u))
      .catch(() => {
        tokenStorage.clear();
        setUser(null);
      })
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    setUnauthorizedHandler(() => setUser(null));
    return () => setUnauthorizedHandler(null);
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      loading,
      setUser: (u) => {
        if (u?.token) tokenStorage.set(u.token);
        setUser(u);
      },
      logout: () => {
        tokenStorage.clear();
        setUser(null);
      },
    }),
    [user, loading]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
