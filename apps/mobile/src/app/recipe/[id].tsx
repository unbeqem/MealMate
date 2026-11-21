import { router, useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { ArrowLeft, CalendarPlus } from 'lucide-react-native';
import {
  ALLERGEN_LABELS,
  DIET_CLASS_LABELS,
  dayShort,
  entryAt,
  formatNumber,
  newId,
  recipeAllergens,
  recipeDietClass,
  scaleDisplay,
  unitLabel,
  weekDays,
  type Slot,
} from '@mealmate/core';
import { FrameHeader } from '@/components/Frame';
import { SLOT_LABEL } from '@/components/PlanSheets';
import { Sheet, useSnackbar } from '@/components/Sheet';
import { Button, Chip, Dashed, IconButton, Loading, Paper, Screen, Stepper, Txt, useIsWide } from '@/components/ui';
import { useCatalog, usePlan, usePrefs, useSetPlan } from '@/data/hooks';
import { RequireSession } from '@/state/session';
import { TODAY, useUi } from '@/state/ui';
import { space, type, usePalette } from '@/theme/tokens';

export default function RecipeDetailRoute() {
  return (
    <RequireSession>
      <RecipeDetail />
    </RequireSession>
  );
}

function RecipeDetail() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const p = usePalette();
  const wide = useIsWide();
  const catalog = useCatalog();
  const prefs = usePrefs();
  const [servings, setServings] = useState<number | null>(null);
  const [planOpen, setPlanOpen] = useState(false);

  if (catalog.isLoading || prefs.isLoading) return <Loading />;
  const r = catalog.data?.recipeById.get(id);
  const back = () => (router.canGoBack() ? router.back() : router.replace('/recipes'));
  if (!r)
    return (
      <Screen>
        <Txt variant="headline">Rezept nicht gefunden</Txt>
        <Button label="Zu den Rezepten" onPress={back} />
      </Screen>
    );

  const n = servings ?? prefs.data?.householdSize ?? r.servings;
  const factor = n / r.servings;
  const ings = catalog.data!.ings;
  const allergens = recipeAllergens(r, ings);

  return (
    <View style={{ flex: 1, backgroundColor: p.ground }}>
      <Screen contentStyle={{ paddingHorizontal: 0, maxWidth: '100%' }}>
        <FrameHeader
          title={r.title}
          subtitle={`${r.prepMinutes} Min · ${DIET_CLASS_LABELS[recipeDietClass(r, ings)]}${r.source === 'ai' ? ' · KI-Rezept' : ''}`}
          left={<IconButton icon={ArrowLeft} label="Zurück" color={p.frameInk} onPress={back} />}
          right={wide ? <Button label="Zum Plan hinzufügen" icon={CalendarPlus} variant="onFrame" onPress={() => setPlanOpen(true)} /> : undefined}
        />
        <View style={[styles.body, wide && styles.bodyWide]}>
          <View style={[{ gap: space.lg }, wide && { flex: 1 }]}>
            <Txt variant="body">{r.description}</Txt>
            {!wide ? <Button label="Zum Plan hinzufügen" icon={CalendarPlus} onPress={() => setPlanOpen(true)} /> : null}
            <Paper torn="bottom">
              <View style={styles.servRow}>
                <Txt variant="title" style={{ flex: 1 }} accessibilityRole="header">Zutaten</Txt>
                <Stepper label="Portionen" value={n} min={1} max={12} onChange={setServings} format={(x) => `${x} Port.`} />
              </View>
              <Dashed />
              {r.ingredients.map((ri) => {
                const ing = ings.get(ri.ingredientId);
                const amt = scaleDisplay(ri.displayAmount, ri.displayUnit, factor);
                return (
                  <View key={ri.ingredientId} style={styles.ingRow} accessible accessibilityLabel={`${formatNumber(amt)} ${unitLabel(ri.displayUnit, amt)} ${ing?.name ?? ri.ingredientId}${ri.optional ? ', optional' : ''}`}>
                    <Text style={[type.mono, { color: p.ink, flex: 1 }]}>
                      {ing?.name ?? ri.ingredientId}
                      {ri.optional ? <Text style={{ color: p.inkMuted }}> (optional)</Text> : null}
                    </Text>
                    <Text style={[type.monoStrong, { color: p.ink }]}>{formatNumber(amt)} {unitLabel(ri.displayUnit, amt)}</Text>
                  </View>
                );
              })}
              {allergens.length ? (
                <>
                  <Dashed />
                  <Text style={[type.mono, { color: p.inkMuted, fontSize: 11 }]}>ENTHÄLT: {allergens.map((a) => ALLERGEN_LABELS[a]).join(', ').toUpperCase()}</Text>
                </>
              ) : null}
            </Paper>
          </View>
          <View style={[{ gap: space.md }, wide && { flex: 1.2 }]}>
            <Txt variant="title" accessibilityRole="header">Zubereitung</Txt>
            {r.steps.map((s, i) => (
              <View key={i} style={styles.step}>
                <Text style={[type.monoStrong, { color: p.accent, width: 28 }]}>{i + 1}.</Text>
                <Txt variant="body" style={{ flex: 1 }}>{s}</Txt>
              </View>
            ))}
          </View>
        </View>
      </Screen>
      <AddToPlanSheet open={planOpen} recipeId={r.id} servings={n} category={r.category} onClose={() => setPlanOpen(false)} />
    </View>
  );
}

function AddToPlanSheet({ open, recipeId, servings, category, onClose }: { open: boolean; recipeId: string; servings: number; category: string; onClose: () => void }) {
  const week = useUi((s) => s.week);
  const plan = usePlan(week);
  const setPlan = useSetPlan(week);
  const snack = useSnackbar();
  const days = weekDays(week).filter((d) => d >= TODAY || week > TODAY);
  const [date, setDate] = useState(days[0] ?? week);
  const [slot, setSlot] = useState<Slot>(category === 'breakfast' ? 'breakfast' : 'dinner');
  const taken = plan.data ? entryAt(plan.data, date, slot) : undefined;

  const add = () => {
    const entries = (plan.data ?? []).filter((e) => !(e.date === date && e.slot === slot) && e.leftoverOf !== taken?.id);
    setPlan.mutate([...entries, { id: newId(), date, slot, recipeId, servings }]);
    snack({ message: `Eingeplant: ${dayShort(date)}, ${SLOT_LABEL[slot]}.` });
    onClose();
  };

  return (
    <Sheet open={open} onClose={onClose} title="Zum Plan hinzufügen" footer={<Button label={taken ? 'Ersetzen und einplanen' : 'Einplanen'} onPress={add} />}>
      <Txt variant="label">Tag</Txt>
      <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: space.sm }}>
        {(days.length ? days : weekDays(week)).map((d) => (
          <Chip key={d} label={dayShort(d)} selected={d === date} onPress={() => setDate(d)} />
        ))}
      </View>
      <Txt variant="label">Mahlzeit</Txt>
      <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: space.sm }}>
        {(['breakfast', 'lunch', 'dinner'] as Slot[]).map((s) => (
          <Chip key={s} label={SLOT_LABEL[s]} selected={s === slot} onPress={() => setSlot(s)} />
        ))}
      </View>
      {taken ? <Txt variant="small" color="danger">Hier ist schon etwas geplant. Es wird ersetzt.</Txt> : null}
    </Sheet>
  );
}

const styles = StyleSheet.create({
  body: { width: '100%', maxWidth: 1120, alignSelf: 'center', paddingHorizontal: space.lg, gap: space.xl, marginTop: space.lg },
  bodyWide: { flexDirection: 'row', alignItems: 'flex-start', gap: space.xxl },
  servRow: { flexDirection: 'row', alignItems: 'center', gap: space.sm },
  ingRow: { flexDirection: 'row', alignItems: 'baseline', gap: space.md, paddingVertical: 5 },
  step: { flexDirection: 'row', gap: space.sm },
});
