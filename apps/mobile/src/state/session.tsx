import AsyncStorage from '@react-native-async-storage/async-storage';
import type { Session } from '@supabase/supabase-js';
import { Redirect } from 'expo-router';
import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { Loading } from '@/components/ui';
import { localRepo } from '@/data/localRepo';
import type { Repo } from '@/data/repo';
import { createSupabaseRepo } from '@/data/supabaseRepo';
import { hasBackend, supabase } from '@/lib/supabase';

const GUEST_KEY = 'mm.guest.active';

type Status = 'loading' | 'signedOut' | 'ready';

interface SessionValue {
  status: Status;
  repo: Repo | null;
  email: string | null;
  /** stable id for query keys */
  scope: string;
  startGuest(): Promise<void>;
  signOut(): Promise<void>;
}

const Ctx = createContext<SessionValue | null>(null);

export function SessionProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [guest, setGuest] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let alive = true;
    (async () => {
      const g = (await AsyncStorage.getItem(GUEST_KEY).catch(() => null)) === '1';
      const s = supabase ? (await supabase.auth.getSession()).data.session : null;
      if (!alive) return;
      setGuest(g || !hasBackend);
      setSession(s);
      setLoading(false);
    })();
    const sub = supabase?.auth.onAuthStateChange((_e, s) => setSession(s));
    return () => {
      alive = false;
      sub?.data.subscription.unsubscribe();
    };
  }, []);

  const startGuest = useCallback(async () => {
    await AsyncStorage.setItem(GUEST_KEY, '1');
    setGuest(true);
  }, []);

  const signOut = useCallback(async () => {
    await AsyncStorage.removeItem(GUEST_KEY);
    setGuest(false);
    await supabase?.auth.signOut();
  }, []);

  const value = useMemo<SessionValue>(() => {
    if (loading) return { status: 'loading', repo: null, email: null, scope: 'none', startGuest, signOut };
    if (session && supabase)
      return {
        status: 'ready',
        repo: createSupabaseRepo(supabase, session.user.id),
        email: session.user.email ?? null,
        scope: session.user.id,
        startGuest,
        signOut,
      };
    if (guest) return { status: 'ready', repo: localRepo, email: null, scope: 'guest', startGuest, signOut };
    return { status: 'signedOut', repo: null, email: null, scope: 'none', startGuest, signOut };
  }, [loading, session, guest, startGuest, signOut]);

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useSession(): SessionValue {
  const v = useContext(Ctx);
  if (!v) throw new Error('SessionProvider fehlt');
  return v;
}

/** Gate for routes outside the (tabs) layout: waits for the session, sends signed-out users to sign-in. */
export function RequireSession({ children }: { children: ReactNode }) {
  const { status } = useSession();
  if (status === 'loading') return <Loading />;
  if (status === 'signedOut') return <Redirect href="/sign-in" />;
  return <>{children}</>;
}

/** Repo for screens that are only reachable when signed in or in guest mode. */
export function useRepo(): Repo {
  const { repo } = useSession();
  if (!repo) throw new Error('Kein Datenzugriff ohne Anmeldung');
  return repo;
}
