import { Redirect, useLocalSearchParams } from 'expo-router';
import { useEffect, useState } from 'react';
import { Loading } from '@/components/ui';
import { supabase } from '@/lib/supabase';

/** Landing point for magic links and OAuth (PKCE code exchange). */
export default function AuthCallback() {
  const { code } = useLocalSearchParams<{ code?: string }>();
  const [done, setDone] = useState(false);
  useEffect(() => {
    (async () => {
      if (code && supabase) {
        const { data } = await supabase.auth.getSession();
        if (!data.session) await supabase.auth.exchangeCodeForSession(code).catch(() => {});
      }
      setDone(true);
    })();
  }, [code]);
  if (!done) return <Loading label="Anmeldung wird abgeschlossen …" />;
  return <Redirect href="/" />;
}
