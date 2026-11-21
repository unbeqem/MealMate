import { router } from 'expo-router';
import { useMemo, useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { Search } from 'lucide-react-native';
import {
  buildShoppingList,
  categoriesForSlot,
  dayLong,
  entryAt,
  formatAmount,
  isRelevantLeftover,
  newId,
  planLeftover,
  removeEntry,
  searchRecipes,
  addDays,
  type PlanEntry,
  type Recipe,
  type Slot,
} from '@mealmate/core';
import { Field } from './Frame';
import { Sheet, useSnackbar } from './Sheet';
import { Button, Chip, Dashed, Highlight, Stepper, Txt, type PState } from './ui';
import { useAllowedRecipes, useCatalog, usePlan, usePrefs, useSetPlan } from '@/data/hooks';
import { space, type, usePalette } from '@/theme/tokens';

export const SLOT_LABEL: Record<Slot, string> = { breakfast: 'Frühstück', lunch: 'Mittag', dinner: 'Abend' };

interface Synergy {
  recipe: Recipe;
  uses: { name: string; amount: string }[];
  score: number;
}

/** Ranks recipes by how much of the week's open leftovers they use up. */
function useSynergy(week: string, candidates: Recipe[]): Synergy[] {
  const catalog = useCatalog();
  const prefs = usePrefs();
  const plan = usePlan(week);
  return useMemo(() => {
    if (!catalog.data || !prefs.data || !plan.data) return candidates.map((recipe) => ({ recipe, uses: [], score: 0 }));
    const list = buildShoppingList({ entries: plan.data, recipes: catalog.data.recipes, ingredients: catalog.data.ings, prefs: prefs.data });
    // only leftovers that would actually spoil count (same rule as the receipt)
    const left = new Map(
      list.items
        .filter((i) => {
          const ing = i.ingredientId ? catalog.data!.ings.get(i.ingredientId) : undefined;
          return !!ing && !i.assumedStock && isRelevantLeftover(ing, i.leftoverBase, i.purchaseBase);
        })
        .map((i) => [i.ingredientId!, i]),
    );
    return candidates
      .map((recipe) => {
        const factor = prefs.data!.householdSize / recipe.servings;
        const uses: Synergy['uses'] = [];
        let score = 0;
        for (const ri of recipe.ingredients) {
          const l = left.get(ri.ingredientId);
          if (!l) continue;
          const used = Math.min(l.leftoverBase, ri.amountBase * factor);
          const ing = catalog.data!.ings.get(ri.ingredientId)!;
          uses.push({ name: l.label, amount: formatAmount(ing, used) });
          score += used / l.leftoverBase;
        }
        return { recipe, uses, score };
      })
      .sort((a, b) => b.score - a.score);
  }, [catalog.data, prefs.data, plan.data, candidates]);
}

export function PickerSheet({
  week,
  target,
  replaceId,
  onClose,
}: {
  week: string;
  target: { date: string; slot: Slot } | null;
  replaceId?: string | null;
  onClose: () => void;
}) {
  const p = usePalette();
  const catalog = useCatalog();
  const prefs = usePrefs();
  const plan = usePlan(week);
  const setPlan = useSetPlan(week);
  const snack = useSnackbar();
  const { allowed } = useAllowedRecipes();
  const [q, setQ] = useState('');
  const [quick, setQuick] = useState(false);

  const candidates = useMemo(() => {
    if (!target) return [];
    const cats = categoriesForSlot(target.slot);
    let list = allowed.filter((r) => cats.includes(r.category));
    if (quick) list = list.filter((r) => r.prepMinutes <= 20);
    if (q.trim()) {
      const hits = new Set(searchRecipes(list, q, (id) => catalog.data?.ings.get(id)?.name ?? id).map((r) => r.id));
      list = list.filter((r) => hits.has(r.id));
    }
    return list;
  }, [target, allowed, quick, q, catalog.data]);
  const ranked = useSynergy(week, candidates);

  const pick = (r: Recipe) => {
    if (!target || !plan.data || !prefs.data) return;
    let entries = plan.data;
    if (replaceId) entries = removeEntry(entries, replaceId);
    const existing = entryAt(entries, target.date, target.slot);
    if (existing) entries = removeEntry(entries, existing.id);
    entries = [...entries, { id: newId(), date: target.date, slot: target.slot, recipeId: r.id, servings: prefs.data.householdSize }];
    setPlan.mutate(entries);
    snack({ message: `${r.title} am ${dayLong(target.date)} eingeplant.` });
    setQ('');
    onClose();
  };

  return (
    <Sheet open={!!target} onClose={onClose} title={target ? `${dayLong(target.date)} · ${SLOT_LABEL[target.slot]}` : ''}>
      <Field label="Rezept suchen" placeholder="z. B. Spinat, Curry, Pasta" value={q} onChangeText={setQ} autoCorrect={false} />
      <View style={{ flexDirection: 'row', gap: space.sm }}>
        <Chip label="Schnell (≤ 20 Min)" selected={quick} onPress={() => setQuick((v) => !v)} />
      </View>
      {ranked.length === 0 ? (
        <View style={{ alignItems: 'center', gap: space.sm, paddingVertical: space.xl }}>
          <Search color={p.inkMuted} />
          <Txt variant="body" color="inkMuted" style={{ textAlign: 'center' }}>Kein passendes Rezept. Versuch einen anderen Begriff oder entferne den Filter.</Txt>
        </View>
      ) : (
        ranked.map(({ recipe, uses }) => (
          <Pressable
            key={recipe.id}
            accessibilityRole="button"
            accessibilityLabel={`${recipe.title}, ${recipe.prepMinutes} Minuten${uses.length ? `, verbraucht Reste: ${uses.map((u) => `${u.amount} ${u.name}`).join(', ')}` : ''}`}
            onPress={() => pick(recipe)}
            style={(s: PState) => [styles.pickRow, { borderColor: p.rule, backgroundColor: s.hovered || s.pressed ? p.paperSunk : 'transparent' }]}
          >
            <View style={{ flex: 1, gap: 4 }}>
              <Txt variant="bodyStrong">{recipe.title}</Txt>
              {uses.length > 0 ? (
                <Highlight style={{ alignSelf: 'flex-start' }}>
                  <Text style={[type.mono, { color: p.onHighlight }]}>verbraucht {uses.map((u) => `${u.amount} ${u.name}`).join(' + ')}</Text>
                </Highlight>
              ) : (
                <Txt variant="small" color="inkMuted" numberOfLines={1}>{recipe.description}</Txt>
              )}
            </View>
            <Text style={[type.mono, { color: p.inkMuted }]}>{recipe.prepMinutes} Min</Text>
          </Pressable>
        ))
      )}
    </Sheet>
  );
}

export function EntrySheet({ week, entry, onClose, onSwap }: { week: string; entry: PlanEntry | null; onClose: () => void; onSwap: (e: PlanEntry) => void }) {
  const p = usePalette();
  const catalog = useCatalog();
  const plan = usePlan(week);
  const prefs = usePrefs();
  const setPlan = useSetPlan(week);
  const snack = useSnackbar();
  const recipe = entry ? catalog.data?.recipeById.get(entry.recipeId) : undefined;
  const current = entry && plan.data?.find((e) => e.id === entry.id);
  if (!entry) return <Sheet open={false} onClose={onClose} title="">{null}</Sheet>;

  const entries = plan.data ?? [];
  const cookOf = current?.leftoverOf ? entries.find((e) => e.id === current.leftoverOf) : undefined;
  const hasLeftover = entries.some((e) => e.leftoverOf === entry.id);
  const nextLunchDate = entry.slot === 'dinner' ? addDays(entry.date, 1) : entry.date;
  const nextFree = entry.slot !== 'breakfast' && !entryAt(entries, nextLunchDate, entry.slot === 'dinner' ? 'lunch' : 'dinner');

  const update = (servings: number) => setPlan.mutate(entries.map((e) => (e.id === entry.id ? { ...e, servings } : e)));
  const remove = () => {
    const before = entries;
    setPlan.mutate(removeEntry(entries, entry.id));
    snack({ message: `${recipe?.title ?? 'Eintrag'} entfernt.`, action: { label: 'Rückgängig', onPress: () => setPlan.mutate(before) } });
    onClose();
  };
  const leftover = () => {
    setPlan.mutate(planLeftover(entries, entry.id, prefs.data?.householdSize ?? 2));
    snack({ message: entry.slot === 'dinner' ? 'Rest für morgen Mittag eingeplant.' : 'Rest für heute Abend eingeplant.' });
    onClose();
  };

  return (
    <Sheet open={!!entry} onClose={onClose} title={recipe?.title ?? 'Eintrag'}>
      <Txt variant="label" color="inkMuted">{dayLong(entry.date)} · {SLOT_LABEL[entry.slot]}</Txt>
      {cookOf ? (
        <Txt variant="body">Das ist der Rest vom {dayLong(cookOf.date)}. Dafür wird nichts extra eingekauft.</Txt>
      ) : (
        <View style={styles.line}>
          <Txt variant="bodyStrong" style={{ flex: 1 }}>Portionen</Txt>
          <Stepper label="Portionen" value={current?.servings ?? entry.servings} min={1} max={12} onChange={update} format={(n) => `${n} Port.`} />
        </View>
      )}
      <Dashed style={{ marginVertical: 0 }} />
      {!cookOf && !hasLeftover && nextFree ? (
        <Button label={entry.slot === 'dinner' ? 'Mehr kochen: Rest morgen Mittag' : 'Mehr kochen: Rest heute Abend'} variant="secondary" onPress={leftover} />
      ) : null}
      <Button label="Rezept ansehen" variant="secondary" onPress={() => { onClose(); router.push(`/recipe/${entry.recipeId}`); }} />
      {!cookOf ? <Button label="Anderes Rezept wählen" variant="secondary" onPress={() => onSwap(entry)} /> : null}
      <Button label="Aus dem Plan entfernen" variant="ghost" onPress={remove} style={{ borderColor: 'transparent' }} />
      <Text style={[type.small, { color: p.inkMuted, textAlign: 'center' }]}>{hasLeftover ? 'Entfernen löscht auch den eingeplanten Rest.' : ' '}</Text>
    </Sheet>
  );
}

const styles = StyleSheet.create({
  pickRow: { flexDirection: 'row', alignItems: 'center', gap: space.md, paddingVertical: space.md, paddingHorizontal: space.sm, borderBottomWidth: 1, minHeight: 56, borderRadius: 6 },
  line: { flexDirection: 'row', alignItems: 'center', gap: space.md },
});
