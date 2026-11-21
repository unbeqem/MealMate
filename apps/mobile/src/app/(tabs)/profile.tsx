import { useQueryClient } from '@tanstack/react-query';
import { router } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import { LogOut } from 'lucide-react-native';
import { ALLERGEN_LABELS, DIET_LABELS, type Allergen, type Diet } from '@mealmate/core';
import { FrameHeader } from '@/components/Frame';
import { useSnackbar } from '@/components/Sheet';
import { Button, Chip, Dashed, Loading, Paper, Screen, Stepper, ToggleRow, Txt, useIsWide } from '@/components/ui';
import { useCatalog, usePrefs, useSavePrefs } from '@/data/hooks';
import type { StoredPreferences } from '@/data/repo';
import { clearGuestData } from '@/data/localRepo';
import { useSession } from '@/state/session';
import { space } from '@/theme/tokens';

const TIMES: { label: string; value: number | null }[] = [
  { label: 'Egal', value: null },
  { label: 'bis 20 Min', value: 20 },
  { label: 'bis 30 Min', value: 30 },
  { label: 'bis 45 Min', value: 45 },
];

export default function Profile() {
  const wide = useIsWide();
  const prefs = usePrefs();
  const catalog = useCatalog();
  const save = useSavePrefs();
  const snack = useSnackbar();
  const qc = useQueryClient();
  const { repo, email, signOut } = useSession();

  if (prefs.isLoading || !prefs.data) return <Loading />;
  const p = prefs.data;
  const set = (patch: Partial<StoredPreferences>) => {
    save.mutate({ ...p, ...patch }, { onError: () => snack({ message: 'Speichern fehlgeschlagen. Prüf deine Verbindung.' }) });
  };
  const toggle = <T,>(list: T[], v: T) => (list.includes(v) ? list.filter((x) => x !== v) : [...list, v]);

  const leave = async () => {
    if (repo?.mode === 'guest') await clearGuestData();
    await signOut();
    qc.clear();
    router.replace('/sign-in');
  };

  return (
    <Screen contentStyle={{ paddingHorizontal: 0, maxWidth: '100%' }}>
      <FrameHeader title="Profil" subtitle={repo?.mode === 'guest' ? 'Gastmodus · Daten nur auf diesem Gerät' : email ?? 'Angemeldet'} />
      <View style={[styles.body, wide && styles.bodyWide]}>
        <View style={[{ gap: space.lg }, wide && { flex: 1 }]}>
          <Paper torn="none">
            <View style={{ gap: space.md }}>
              <Txt variant="title" accessibilityRole="header">Haushalt</Txt>
              <View style={styles.line}>
                <Txt variant="body" style={{ flex: 1 }}>Personen</Txt>
                <Stepper label="Personen" value={p.householdSize} min={1} max={8} onChange={(n) => set({ householdSize: n })} format={(n) => `${n} P.`} />
              </View>
              <Dashed style={{ marginVertical: 0 }} />
              <ToggleRow label="Frühstück mitplanen" value={p.includeBreakfast} onChange={(v) => set({ includeBreakfast: v })} />
              <ToggleRow label="Abends für den nächsten Mittag mitkochen" value={p.cookForLeftovers} onChange={(v) => set({ cookForLeftovers: v })} />
              <Dashed style={{ marginVertical: 0 }} />
              <Txt variant="bodyStrong">Kochzeit</Txt>
              <View style={styles.wrap}>
                {TIMES.map((t) => (
                  <Chip key={t.label} label={t.label} selected={p.maxCookMinutes === t.value} onPress={() => set({ maxCookMinutes: t.value })} />
                ))}
              </View>
            </View>
          </Paper>
          <Paper torn="none">
            <View style={{ gap: space.md }}>
              <Txt variant="title" accessibilityRole="header">Konto</Txt>
              {repo?.mode === 'guest' ? (
                <Txt variant="body" color="inkMuted">Im Gastmodus liegen Plan und Liste nur auf diesem Gerät. Mit einem Konto sind sie überall verfügbar, und du kannst KI-Rezepte erstellen.</Txt>
              ) : null}
              <Button label={repo?.mode === 'guest' ? 'Gastmodus beenden und Daten löschen' : 'Abmelden'} icon={LogOut} variant="secondary" onPress={leave} />
            </View>
          </Paper>
        </View>
        <View style={[{ gap: space.lg }, wide && { flex: 1 }]}>
          <Paper torn="none">
            <View style={{ gap: space.md }}>
              <Txt variant="title" accessibilityRole="header">Ernährung</Txt>
              <View style={styles.wrap}>
                {(Object.keys(DIET_LABELS) as Diet[]).map((d) => (
                  <Chip key={d} label={DIET_LABELS[d]} selected={p.diet === d} onPress={() => set({ diet: d })} />
                ))}
              </View>
              <Dashed style={{ marginVertical: 0 }} />
              <Txt variant="bodyStrong">Allergien und Unverträglichkeiten</Txt>
              <Txt variant="small" color="inkMuted">Werden immer hart gefiltert, auch bei KI-Rezepten.</Txt>
              <View style={styles.wrap}>
                {(Object.keys(ALLERGEN_LABELS) as Allergen[]).map((a) => (
                  <Chip key={a} label={ALLERGEN_LABELS[a]} selected={p.allergens.includes(a)} onPress={() => set({ allergens: toggle(p.allergens, a) })} />
                ))}
              </View>
              {p.dislikes.length ? (
                <>
                  <Dashed style={{ marginVertical: 0 }} />
                  <Txt variant="bodyStrong">Mag ich nicht</Txt>
                  <View style={styles.wrap}>
                    {p.dislikes.map((id) => (
                      <Chip key={id} label={`${catalog.data?.ings.get(id)?.name ?? id} (entfernen)`} selected onPress={() => set({ dislikes: p.dislikes.filter((x) => x !== id) })} />
                    ))}
                  </View>
                </>
              ) : null}
            </View>
          </Paper>
        </View>
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  body: { width: '100%', maxWidth: 1120, alignSelf: 'center', paddingHorizontal: space.lg, gap: space.lg, marginTop: space.lg },
  bodyWide: { flexDirection: 'row', alignItems: 'flex-start' },
  line: { flexDirection: 'row', alignItems: 'center', gap: space.md },
  wrap: { flexDirection: 'row', flexWrap: 'wrap', gap: space.sm },
});
