import { useQueryClient } from '@tanstack/react-query';
import { router } from 'expo-router';
import { useState } from 'react';
import { View } from 'react-native';
import { ArrowLeft, ChefHat } from 'lucide-react-native';
import { Field, FrameHeader } from '@/components/Frame';
import { Button, Chip, ErrorBox, IconButton, Paper, Screen, Stepper, Txt } from '@/components/ui';
import { queryKeys, usePrefs } from '@/data/hooks';
import { RequireSession, useRepo, useSession } from '@/state/session';
import { space, usePalette } from '@/theme/tokens';

const IDEAS = ['Etwas mit dem Rest Kokosmilch', 'Schnelles Abendessen mit Kichererbsen', 'Herbstliche Suppe', 'Proteinreiches Frühstück ohne Ei'];

export default function GenerateRoute() {
  return (
    <RequireSession>
      <Generate />
    </RequireSession>
  );
}

function Generate() {
  const p = usePalette();
  const repo = useRepo();
  const { scope } = useSession();
  const prefs = usePrefs();
  const qc = useQueryClient();
  const [prompt, setPrompt] = useState('');
  const [servings, setServings] = useState<number | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [unmapped, setUnmapped] = useState<string[]>([]);
  const n = servings ?? prefs.data?.householdSize ?? 2;
  const back = () => (router.canGoBack() ? router.back() : router.replace('/recipes'));

  const run = async () => {
    setError(null);
    setBusy(true);
    try {
      const res = await repo.generateRecipe(prompt.trim(), n);
      await qc.invalidateQueries({ queryKey: queryKeys.catalog(scope) });
      setUnmapped(res.unmapped);
      if (!res.unmapped.length) router.replace(`/recipe/${res.recipe.id}`);
      else setTimeout(() => router.replace(`/recipe/${res.recipe.id}`), 2500);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Das hat nicht geklappt.');
    } finally {
      setBusy(false);
    }
  };

  return (
    <Screen contentStyle={{ paddingHorizontal: 0, maxWidth: '100%' }}>
      <FrameHeader title="Rezept mit KI" subtitle="Beachtet deine Allergien und Vorlieben." left={<IconButton icon={ArrowLeft} label="Zurück" color={p.frameInk} onPress={back} />} />
      <View style={{ width: '100%', maxWidth: 640, alignSelf: 'center', paddingHorizontal: space.lg, gap: space.lg, marginTop: space.lg }}>
        {repo.mode !== 'supabase' ? (
          <ErrorBox message="KI-Rezepte laufen auf dem Server und brauchen ein Konto. Im Gastmodus ist diese Funktion aus." />
        ) : null}
        <Paper torn="bottom">
          <View style={{ gap: space.lg }}>
            <Field label="Was möchtest du kochen?" placeholder="z. B. etwas Schnelles mit Brokkoli und Feta" value={prompt} onChangeText={setPrompt} multiline style={{ minHeight: 96, paddingTop: 14, textAlignVertical: 'top' }} maxLength={500} />
            <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: space.sm }}>
              {IDEAS.map((i) => (
                <Chip key={i} label={i} onPress={() => setPrompt(i)} />
              ))}
            </View>
            <View style={{ flexDirection: 'row', alignItems: 'center' }}>
              <Txt variant="bodyStrong" style={{ flex: 1 }}>Portionen</Txt>
              <Stepper label="Portionen" value={n} min={1} max={8} onChange={setServings} format={(x) => `${x} Port.`} />
            </View>
            <Button label={busy ? 'Rezept wird geschrieben …' : 'Rezept erstellen'} icon={ChefHat} onPress={run} loading={busy} disabled={repo.mode !== 'supabase' || prompt.trim().length < 3} />
          </View>
        </Paper>
        {error ? <ErrorBox message={error} /> : null}
        {unmapped.length ? (
          <Paper torn="none">
            <Txt variant="bodyStrong">Gespeichert. Diese Zutaten kennt MealMate noch nicht, deshalb fehlen sie auf der Einkaufsliste:</Txt>
            <Txt variant="body" color="inkMuted">{unmapped.join(', ')}</Txt>
          </Paper>
        ) : null}
      </View>
    </Screen>
  );
}
