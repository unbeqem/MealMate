import { Redirect } from 'expo-router';
import { Loading } from '@/components/ui';
import { usePrefs } from '@/data/hooks';
import { useSession } from '@/state/session';

function ReadyGate() {
  const prefs = usePrefs();
  if (prefs.isLoading) return <Loading />;
  if (!prefs.data?.onboarded) return <Redirect href="/onboarding" />;
  return <Redirect href="/plan" />;
}

export default function Index() {
  const { status } = useSession();
  if (status === 'loading') return <Loading />;
  if (status === 'signedOut') return <Redirect href="/sign-in" />;
  return <ReadyGate />;
}
