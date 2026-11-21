import { Redirect, router } from 'expo-router';
import { useEffect, useMemo, useRef, useState, type ComponentRef } from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Check } from 'lucide-react-native';
import {
  ALLERGEN_LABELS,
  DEFAULT_PREFERENCES,
  DIET_LABELS,
  autofillWeek,
  dayShort,
  type Allergen,
  type Diet,
  type PlanEntry,
  type Preferences,
} from '@mealmate/core';
import { Button, Chip, Dashed, Loading, Paper, Stepper, ToggleRow, Txt, useIsWide } from '@/components/ui';
import { useCatalog, usePrefs, useSavePrefs, useSetPlan } from '@/data/hooks';
import { useSession } from '@/state/session';
import { useUi } from '@/state/ui';
import { fonts, radius, space, type, usePalette } from '@/theme/tokens';

const STEPS = ['Haushalt', 'Ernährung', 'Lieblingszutaten', 'Deine Woche'] as const;
const FAVORITE_CANDIDATES = [
  'blattspinat', 'tomate', 'paprika', 'zucchini', 'kartoffel', 'suesskartoffel', 'brokkoli', 'champignons', 'kuerbis', 'avocado',
  'feta', 'mozzarella', 'halloumi', 'eier', 'tofu', 'haehnchenbrust', 'hackfleisch', 'lachs', 'garnelen', 'kichererbsen',
  'linsen_rot', 'nudeln', 'reis', 'gnocchi', 'kokosmilch',
];
const TIME_OPTIONS: { label: string; value: number | null }[] = [
  { label: 'Egal', value: null },
  { label: 'bis 20 Min', value: 20 },
  { label: 'bis 30 Min', value: 30 },
  { label: 'bis 45 Min', value: 45 },
];

export default function Onboarding() {
  const { status } = useSession();
  if (status === 'loading') return <Loading />;
  if (status === 'signedOut') return <Redirect href="/sign-in" />;
  return <Flow />;
}

function Flow() {
  const p = usePalette();
  const insets = useSafeAreaInsets();
  const wide = useIsWide();
  const catalog = useCatalog();
  const stored = usePrefs();
  const savePrefs = useSavePrefs();
  const week = useUi((s) => s.week);
  const setPlan = useSetPlan(week);
  const [step, setStep] = useState(0);
  const [prefs, setPrefs] = useState<Preferences>(() => ({ ...DEFAULT_PREFERENCES }));
  const [preview, setPreview] = useState<PlanEntry[] | null>(null);
  const [finishing, setFinishing] = useState(false);
  const scroller = useRef<ComponentRef<typeof ScrollView>>(null);
  useEffect(() => scroller.current?.scrollTo({ y: 0, animated: false }), [step]);
  const set = (patch: Partial<Preferences>) => setPrefs((x) => ({ ...x, ...patch }));
  const toggle = <T,>(list: T[], v: T) => (list.includes(v) ? list.filter((x) => x !== v) : [...list, v]);

  const recipesFor = (pr: Preferences) =>
    catalog.data ? autofillWeek({ week, entries: [], recipes: catalog.data.recipes, ingredients: catalog.data.ings, prefs: pr }) : [];

  const next = () => {
    if (step === 2) setPreview(recipesFor(prefs));
    setStep((s) => Math.min(STEPS.length - 1, s + 1));
  };

  const finish = async () => {
    setFinishing(true);
    try {
      await savePrefs.mutateAsync({ ...prefs, onboarded: true });
      await setPlan.mutateAsync(preview ?? []);
      router.replace('/plan');
    } finally {
      setFinishing(false);
    }
  };

  if (catalog.isLoading || stored.isLoading) return <Loading />;
  if (stored.data?.onboarded) return <Redirect href="/plan" />;

  const favs = FAVORITE_CANDIDATES.map((id) => catalog.data?.ings.get(id)).filter(Boolean);

  return (
    <View style={{ flex: 1, backgroundColor: p.frame }}>
      <ScrollView ref={scroller} contentContainerStyle={[styles.page, { paddingTop: insets.top + space.xl, paddingBottom: space.xl }]} keyboardShouldPersistTaps="handled">
        <View style={{ gap: space.sm }}>
          <Text style={[type.label, { color: p.frameInkMuted }]} accessibilityLiveRegion="polite">
            Schritt {step + 1} von {STEPS.length}
          </Text>
          <View style={styles.progress} accessibilityElementsHidden importantForAccessibility="no-hide-descendants">
            {STEPS.map((s, i) => (
              <View key={s} style={[styles.progressSeg, { backgroundColor: i <= step ? p.frameInk : 'rgba(255,255,255,0.3)' }]} />
            ))}
          </View>
          <Text accessibilityRole="header" style={{ fontFamily: fonts.display, fontSize: wide ? 56 : 40, lineHeight: wide ? 56 : 42, color: p.frameInk, letterSpacing: -0.8 }}>
            {['Für wie viele kochst du?', 'Was isst du, was nicht?', 'Was magst du besonders?', 'Deine erste Woche steht.'][step]}
          </Text>
        </View>

        <Paper torn="both">
          {step === 0 && (
            <View style={{ gap: space.lg }}>
              <View style={styles.line}>
                <Txt variant="bodyStrong" style={{ flex: 1 }}>Personen im Haushalt</Txt>
                <Stepper label="Personen" value={prefs.householdSize} min={1} max={8} onChange={(n) => set({ householdSize: n })} format={(n) => `${n} P.`} />
              </View>
              <Dashed style={{ marginVertical: 0 }} />
              <ToggleRow label="Frühstück mitplanen" hint="Sonst plant MealMate Mittag und Abend." value={prefs.includeBreakfast} onChange={(v) => set({ includeBreakfast: v })} />
              <ToggleRow label="Abends für den nächsten Mittag mitkochen" hint="Spart Zeit und verbraucht Packungen besser." value={prefs.cookForLeftovers} onChange={(v) => set({ cookForLeftovers: v })} />
              <Dashed style={{ marginVertical: 0 }} />
              <Txt variant="bodyStrong">Wie lange darf Kochen dauern?</Txt>
              <View style={styles.wrap}>
                {TIME_OPTIONS.map((o) => (
                  <Chip key={o.label} label={o.label} selected={prefs.maxCookMinutes === o.value} onPress={() => set({ maxCookMinutes: o.value })} />
                ))}
              </View>
            </View>
          )}

          {step === 1 && (
            <View style={{ gap: space.lg }}>
              <Txt variant="bodyStrong">Ernährungsform</Txt>
              <View style={styles.wrap}>
                {(Object.keys(DIET_LABELS) as Diet[]).map((d) => (
                  <Chip key={d} label={DIET_LABELS[d]} selected={prefs.diet === d} onPress={() => set({ diet: d })} />
                ))}
              </View>
              <Dashed style={{ marginVertical: 0 }} />
              <Txt variant="bodyStrong">Allergien und Unverträglichkeiten</Txt>
              <Txt variant="small" color="inkMuted">Rezepte mit diesen Zutaten zeigt MealMate dir nie, auch keine KI-Rezepte.</Txt>
              <View style={styles.wrap}>
                {(Object.keys(ALLERGEN_LABELS) as Allergen[]).map((a) => (
                  <Chip key={a} label={ALLERGEN_LABELS[a]} selected={prefs.allergens.includes(a)} onPress={() => set({ allergens: toggle(prefs.allergens, a) })} />
                ))}
              </View>
            </View>
          )}

          {step === 2 && (
            <View style={{ gap: space.lg }}>
              <Txt variant="body" color="inkMuted">Antippen, was du gern isst: MealMate plant es öfter ein. Zweimal antippen heißt „mag ich nicht“.</Txt>
              <View style={styles.wrap}>
                {favs.map((ing) => {
                  const fav = prefs.favoriteIngredients.includes(ing!.id);
                  const dis = prefs.dislikes.includes(ing!.id);
                  return (
                    <Chip
                      key={ing!.id}
                      label={dis ? `${ing!.name} – nein danke` : ing!.name}
                      selected={fav}
                      icon={fav ? Check : undefined}
                      onPress={() => {
                        if (!fav && !dis) set({ favoriteIngredients: [...prefs.favoriteIngredients, ing!.id] });
                        else if (fav) set({ favoriteIngredients: prefs.favoriteIngredients.filter((x) => x !== ing!.id), dislikes: [...prefs.dislikes, ing!.id] });
                        else set({ dislikes: prefs.dislikes.filter((x) => x !== ing!.id) });
                      }}
                    />
                  );
                })}
              </View>
            </View>
          )}

          {step === 3 && <WeekPreview entries={preview ?? []} onShuffle={() => setPreview(recipesFor(prefs))} />}
        </Paper>

      </ScrollView>
      <View style={[styles.navBar, { paddingBottom: insets.bottom + space.md, backgroundColor: p.frame, borderTopColor: 'rgba(255,255,255,0.25)' }]}>
        <View style={[styles.nav, wide && { justifyContent: 'flex-end' }]}>
          {step > 0 ? <Button label="Zurück" variant="frameGhost" onPress={() => setStep((s) => s - 1)} style={wide ? undefined : { flex: 1 }} /> : null}
          {step < STEPS.length - 1 ? (
            <Button label="Weiter" variant="onFrame" onPress={next} style={wide ? undefined : { flex: 2 }} />
          ) : (
            <Button label="Übernehmen" variant="onFrame" onPress={finish} loading={finishing} accessibilityHint="Speichert die Woche und öffnet den Planer" style={wide ? undefined : { flex: 2 }} />
          )}
        </View>
      </View>
    </View>
  );
}

function WeekPreview({ entries, onShuffle }: { entries: PlanEntry[]; onShuffle: () => void }) {
  const p = usePalette();
  const catalog = useCatalog();
  const dinners = useMemo(() => entries.filter((e) => e.slot === 'dinner').sort((a, b) => a.date.localeCompare(b.date)), [entries]);
  if (!dinners.length) return <Txt variant="body">Mit diesen Einstellungen findet MealMate noch keine passenden Rezepte. Geh einen Schritt zurück und lockere einen Filter.</Txt>;
  return (
    <View style={{ gap: space.sm }}>
      <Txt variant="body" color="inkMuted">Abendessen für diese Woche. Reste vom Abend sind schon als Mittagessen am nächsten Tag eingeplant.</Txt>
      <Dashed style={{ marginVertical: space.xs }} />
      {dinners.map((e) => (
        <View key={e.id} style={styles.line}>
          <Text style={[type.monoStrong, { color: p.inkMuted, width: 36 }]}>{dayShort(e.date)}</Text>
          <Txt variant="bodyStrong" style={{ flex: 1 }}>{catalog.data?.recipeById.get(e.recipeId)?.title}</Txt>
          <Text style={[type.mono, { color: p.inkMuted }]}>{entries.some((x) => x.leftoverOf === e.id) ? `${e.servings / 2} P. + Rest` : `${e.servings} P.`}</Text>
        </View>
      ))}
      <Dashed style={{ marginVertical: space.xs }} />
      <Button label="Andere Vorschläge" variant="ghost" compact onPress={onShuffle} />
    </View>
  );
}

const styles = StyleSheet.create({
  page: { flexGrow: 1, paddingHorizontal: space.lg, gap: space.xl, width: '100%', maxWidth: 720, alignSelf: 'center' },
  progress: { flexDirection: 'row', gap: space.xs },
  progressSeg: { flex: 1, height: 4, borderRadius: radius.pill },
  wrap: { flexDirection: 'row', flexWrap: 'wrap', gap: space.sm },
  line: { flexDirection: 'row', alignItems: 'center', gap: space.md, minHeight: 40 },
  nav: { flexDirection: 'row', gap: space.md, width: '100%', maxWidth: 720, alignSelf: 'center', paddingHorizontal: space.lg },
  navBar: { paddingTop: space.md, borderTopWidth: 1 },
});
