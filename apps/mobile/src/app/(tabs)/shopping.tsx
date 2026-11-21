import * as Haptics from 'expo-haptics';
import { router } from 'expo-router';
import { useMemo, useState } from 'react';
import { Platform, Pressable, StyleSheet, Text, View } from 'react-native';
import { Check, Plus, Trash2 } from 'lucide-react-native';
import {
  AISLE_LABELS,
  AISLE_ORDER,
  formatAmount,
  formatPicks,
  findFreeSlot,
  formatBase,
  isRelevantLeftover,
  isoWeek,
  manualItem,
  newId,
  setChecked,
  dayLong,
  type ShoppingItem,
  type ShoppingList,
} from '@mealmate/core';
import { Field, FrameHeader } from '@/components/Frame';
import { SLOT_LABEL } from '@/components/PlanSheets';
import { Sheet, useSnackbar } from '@/components/Sheet';
import { Button, Dashed, ErrorBox, Feed, Highlight, IconButton, Loading, Paper, Screen, Stepper, Txt, useIsWide, type PState } from '@/components/ui';
import { useCatalog, usePlan, usePrefs, useSaveList, useSetPlan, useShoppingList } from '@/data/hooks';
import { TODAY, useUi } from '@/state/ui';
import { radius, space, type, usePalette } from '@/theme/tokens';

export default function ShoppingScreen() {
  const p = usePalette();
  const wide = useIsWide();
  const week = useUi((s) => s.week);
  const { list, isLoading, error } = useShoppingList(week);
  const save = useSaveList(week);
  const plan = usePlan(week);
  const setPlan = useSetPlan(week);
  const catalog = useCatalog();
  const prefs = usePrefs();
  const snack = useSnackbar();
  const [newItem, setNewItem] = useState('');
  const [editing, setEditing] = useState<ShoppingItem | null>(null);

  const groups = useMemo(() => {
    if (!list) return [];
    const buy = list.items.filter((i) => !i.assumedStock);
    return AISLE_ORDER.map((a) => ({ aisle: a, items: buy.filter((i) => i.aisle === a) })).filter((g) => g.items.length);
  }, [list]);

  if (isLoading) return <Loading />;
  if (error || !list) return <Screen><ErrorBox message="Die Einkaufsliste konnte nicht berechnet werden." /></Screen>;

  const commit = (next: ShoppingList) => save.mutate(next);
  const toggle = (i: ShoppingItem) => {
    if (Platform.OS !== 'web') Haptics.selectionAsync().catch(() => {});
    commit(setChecked(list, i.key, !i.checked));
  };
  const addManual = () => {
    const label = newItem.trim();
    if (!label) return;
    const item = manualItem(label);
    if (list.items.some((i) => i.key === item.key)) return snack({ message: `${label} steht schon auf dem Bon.` });
    commit({ ...list, items: [...list.items, item] });
    setNewItem('');
  };
  const planSuggestion = (i: ShoppingItem, recipeId: string, title: string) => {
    if (!plan.data || !prefs.data) return;
    const from = TODAY > week ? TODAY : week;
    const slot = findFreeSlot(plan.data, week, from);
    if (!slot) return snack({ message: 'Diese Woche ist kein Platz mehr frei. Tausch ein Gericht im Plan.' });
    setPlan.mutate([...plan.data, { id: newId(), date: slot.date, slot: slot.slot, recipeId, servings: prefs.data.householdSize }]);
    snack({ message: `${title} am ${dayLong(slot.date)} (${SLOT_LABEL[slot.slot]}) eingeplant. Der ${i.label}-Rest ist verplant.` });
  };

  const buyItems = list.items.filter((i) => !i.assumedStock);
  const checked = buyItems.filter((i) => i.checked).length;
  const staples = list.items.filter((i) => i.assumedStock);
  const openLeftovers = buyItems.filter((i) => i.suggestions.length > 0).length;
  let feedIndex = 0;

  return (
    <View style={{ flex: 1, backgroundColor: p.ground }}>
      <Screen contentStyle={{ paddingHorizontal: 0, maxWidth: '100%' }}>
        <FrameHeader title="Der Bon" subtitle={`KW ${isoWeek(week)} · ${checked} von ${buyItems.length} im Korb`} />
        <View style={[styles.body, wide && { maxWidth: 640 }]}>
          {buyItems.length === 0 ? (
            <Paper torn="both">
              <View style={{ gap: space.md }}>
                <Txt variant="title">Noch nichts zu kaufen</Txt>
                <Txt variant="body" color="inkMuted">Plane ein paar Mahlzeiten, dann rechnet MealMate hier die Packungen aus.</Txt>
                <Button label="Zum Wochenplan" onPress={() => router.push('/plan')} />
              </View>
            </Paper>
          ) : (
            <Paper torn="both" style={{ marginTop: -space.sm }}>
              <Text style={[type.monoStrong, { color: p.ink, textAlign: 'center', letterSpacing: 2 }]}>MEALMATE</Text>
              <Text style={[type.mono, { color: p.inkMuted, textAlign: 'center' }]}>
                Woche {isoWeek(week)} · {prefs.data?.householdSize ?? 2} Personen
              </Text>
              {groups.map((g) => (
                <View key={g.aisle}>
                  <Dashed />
                  <Text accessibilityRole="header" style={[type.mono, styles.aisle, { color: p.inkMuted }]}>{AISLE_LABELS[g.aisle]}</Text>
                  {g.items.map((i) => (
                    <Feed key={i.key} index={feedIndex++}>
                      <Row item={i} onToggle={() => toggle(i)} onEdit={() => setEditing(i)} onPlan={planSuggestion} onDelete={() => commit({ ...list, items: list.items.filter((x) => x.key !== i.key) })} />
                    </Feed>
                  ))}
                </View>
              ))}
              <Dashed />
              <View style={styles.total}>
                <Text style={[type.monoStrong, { color: p.ink }]}>Offene Reste</Text>
                <Text style={[type.monoStrong, { color: openLeftovers ? p.ink : p.done }]}>{openLeftovers ? openLeftovers : '0 – alles verplant'}</Text>
              </View>
              <View accessible={false} style={styles.barcode}>
                {Array.from({ length: 48 }, (_, k) => (
                  <View key={k} style={{ width: (k * 7) % 3 === 0 ? 3 : 1.5, backgroundColor: p.ink, marginRight: (k * 5) % 4 === 0 ? 3 : 2 }} />
                ))}
              </View>
            </Paper>
          )}

          <Paper torn="none">
            <View style={{ gap: space.md }}>
              <Field label="Eigenen Eintrag hinzufügen" placeholder="z. B. Spülmittel" value={newItem} onChangeText={setNewItem} onSubmitEditing={addManual} returnKeyType="done" />
              <Button label="Hinzufügen" icon={Plus} variant="secondary" onPress={addManual} disabled={!newItem.trim()} />
            </View>
          </Paper>

          {staples.length > 0 ? (
            <View style={{ gap: space.xs, paddingHorizontal: space.xs }}>
              <Txt variant="label">Vorrat vorausgesetzt</Txt>
              <Txt variant="small" color="inkMuted">{staples.map((s) => s.label).join(', ')}</Txt>
            </View>
          ) : null}
        </View>
      </Screen>

      <AmountSheet item={editing} onClose={() => setEditing(null)} onSave={(override) => {
        if (!editing) return;
        commit({ ...list, items: list.items.map((x) => (x.key === editing.key ? { ...x, manualOverride: override } : x)) });
        setEditing(null);
      }} />
    </View>
  );
}

function Row({
  item: i,
  onToggle,
  onEdit,
  onPlan,
  onDelete,
}: {
  item: ShoppingItem;
  onToggle: () => void;
  onEdit: () => void;
  onPlan: (i: ShoppingItem, recipeId: string, title: string) => void;
  onDelete: () => void;
}) {
  const p = usePalette();
  const catalog = useCatalog();
  const ing = i.ingredientId ? catalog.data?.ings.get(i.ingredientId) : undefined;
  const relevant = ing ? isRelevantLeftover(ing, i.leftoverBase, i.purchaseBase) : false;
  const fmtAmt = (n: number) => (ing ? formatAmount(ing, n) : formatBase(n, i.unit));
  const amount = i.source === 'manual' ? '' : i.packages.length && i.manualOverride == null && ing ? formatPicks(ing, i.packages) : fmtAmt(i.purchaseBase);
  const best = i.suggestions[0];

  return (
    <View style={{ paddingVertical: 2 }}>
      <View style={styles.row}>
        <Pressable
          accessibilityRole="checkbox"
          accessibilityState={{ checked: i.checked }}
          accessibilityLabel={`${i.label}${amount ? `, ${amount}` : ''}`}
          onPress={onToggle}
          hitSlop={4}
          style={styles.checkHit}
        >
          <View style={[styles.check, { borderColor: i.checked ? p.done : p.inkMuted, backgroundColor: i.checked ? p.done : 'transparent' }]}>
            {i.checked ? <Check size={16} color={p.paper} strokeWidth={3} /> : null}
          </View>
        </Pressable>
        <View style={styles.nameAmount}>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={i.source === 'manual' ? i.label : `${i.label}: Menge anpassen`}
            disabled={i.source === 'manual'}
            onPress={onEdit}
            style={{ flexGrow: 1, flexShrink: 1, flexBasis: '55%', minHeight: 48, justifyContent: 'center' }}
          >
            <Text style={[type.bodyStrong, { color: i.checked ? p.inkMuted : p.ink, textDecorationLine: i.checked ? 'line-through' : 'none' }]}>{i.label}</Text>
            {i.source === 'auto' ? (
              <Text style={[type.mono, { color: p.inkMuted, fontSize: 11 }]}>
                {i.orphaned ? 'nicht mehr im Plan' : `Bedarf ${fmtAmt(i.requiredBase)}${i.manualOverride != null ? ' · angepasst' : ''}`}
              </Text>
            ) : (
              <Text style={[type.mono, { color: p.inkMuted, fontSize: 11 }]}>eigener Eintrag</Text>
            )}
          </Pressable>
          {i.source === 'manual' ? (
            <IconButton icon={Trash2} label={`${i.label} entfernen`} onPress={onDelete} color={p.inkMuted} size={18} />
          ) : (
            <Text style={[type.monoStrong, { color: i.checked ? p.inkMuted : p.ink, textAlign: 'right', flexShrink: 0, marginLeft: 'auto', paddingBottom: 4 }]}>{amount}</Text>
          )}
        </View>
      </View>
      {relevant && best ? (
        <Highlight style={{ marginLeft: 48 - space.sm, marginTop: 2, marginBottom: space.xs }}>
          <View style={styles.restRow}>
            <View style={{ flex: 1 }}>
              <Text style={[type.monoStrong, { color: p.onHighlight }]}>REST {fmtAmt(i.leftoverBase)}</Text>
              <Text style={[type.mono, { color: p.onHighlight }]}>→ {best.title}</Text>
            </View>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={`${best.title} einplanen, verbraucht den Rest ${i.label}`}
              onPress={() => onPlan(i, best.recipeId, best.title)}
              style={(s: PState) => [styles.restBtn, { borderColor: p.onHighlight, backgroundColor: s.hovered || s.pressed ? 'rgba(0,0,0,0.08)' : 'transparent' }]}
            >
              <Text style={[type.label, { color: p.onHighlight }]}>Einplanen</Text>
            </Pressable>
          </View>
        </Highlight>
      ) : i.leftoverBase > 0 && !relevant && i.source === 'auto' ? (
        <Text style={[type.mono, { color: p.inkMuted, fontSize: 11, marginLeft: 48 }]}>+ {fmtAmt(i.leftoverBase)} übrig{(ing?.shelfLifeDays ?? 0) >= 21 ? ' · hält lange' : ''}</Text>
      ) : relevant ? (
        <Text style={[type.mono, { color: p.inkMuted, fontSize: 11, marginLeft: 48 }]}>Rest {fmtAmt(i.leftoverBase)} · kein passendes Rezept</Text>
      ) : null}
    </View>
  );
}

function AmountSheet({ item, onClose, onSave }: { item: ShoppingItem | null; onClose: () => void; onSave: (override: number | null) => void }) {
  const catalog = useCatalog();
  const ing = item?.ingredientId ? catalog.data?.ings.get(item.ingredientId) : undefined;
  const size = ing?.packages[0]?.amount ?? 1;
  const initial = item ? Math.max(1, Math.round((item.manualOverride ?? item.purchaseBase) / size)) : 1;
  const [count, setCount] = useState(initial);
  const [lastKey, setLastKey] = useState<string | null>(null);
  if (item && item.key !== lastKey) {
    setLastKey(item.key);
    setCount(initial);
  }
  return (
    <Sheet
      open={!!item}
      onClose={onClose}
      title={item ? `${item.label} anpassen` : ''}
      footer={
        <>
          <Button label="Menge übernehmen" onPress={() => onSave(count * size)} />
          {item?.manualOverride != null ? <Button label="Zurück zur berechneten Menge" variant="ghost" onPress={() => onSave(null)} style={{ borderColor: 'transparent' }} /> : null}
        </>
      }
    >
      {item ? (
        <>
          <Txt variant="body" color="inkMuted">Berechnet: {ing ? formatAmount(ing, item.requiredBase) : formatBase(item.requiredBase, item.unit)} Bedarf. Deine Korrektur bleibt erhalten, auch wenn sich der Plan ändert.</Txt>
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: space.md }}>
            <Txt variant="bodyStrong" style={{ flex: 1 }}>{ing?.packages[0]?.label ?? 'Menge'}</Txt>
            <Stepper label="Anzahl Packungen" value={count} min={1} max={20} onChange={setCount} format={(n) => `${n} ×`} />
          </View>
        </>
      ) : null}
    </Sheet>
  );
}

const styles = StyleSheet.create({
  body: { width: '100%', maxWidth: 1120, alignSelf: 'center', paddingHorizontal: space.lg, gap: space.lg },
  aisle: { marginBottom: space.xs },
  row: { flexDirection: 'row', alignItems: 'center', gap: space.xs },
  nameAmount: { flex: 1, flexDirection: 'row', flexWrap: 'wrap', alignItems: 'center', columnGap: space.sm },
  checkHit: { width: 44, height: 48, alignItems: 'flex-start', justifyContent: 'center' },
  check: { width: 26, height: 26, borderRadius: 7, borderWidth: 2, alignItems: 'center', justifyContent: 'center' },
  restRow: { flexDirection: 'row', alignItems: 'center', gap: space.sm },
  restBtn: { minHeight: 40, paddingHorizontal: space.md, borderRadius: radius.sm, borderWidth: 1.5, justifyContent: 'center' },
  total: { flexDirection: 'row', justifyContent: 'space-between' },
  barcode: { flexDirection: 'row', height: 40, marginTop: space.lg, alignSelf: 'center', overflow: 'hidden' },
});
