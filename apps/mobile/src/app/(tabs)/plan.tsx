import { router } from 'expo-router';
import { useMemo, useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { CalendarCheck, ChevronLeft, ChevronRight, CornerDownRight, MoreHorizontal, Plus } from 'lucide-react-native';
import {
  SLOTS,
  autofillWeek,
  dayLong,
  dayShort,
  entryAt,
  isoWeek,
  leftoverSummary,
  parseISODate,
  weekDays,
  addDays,
  type PlanEntry,
  type Slot,
} from '@mealmate/core';
import { FrameHeader } from '@/components/Frame';
import { EntrySheet, PickerSheet, SLOT_LABEL } from '@/components/PlanSheets';
import { useSnackbar } from '@/components/Sheet';
import { Button, ErrorBox, IconButton, Loading, Paper, Screen, Txt, useIsWide, type PState } from '@/components/ui';
import { useCatalog, usePlan, usePrefs, useSetPlan, useShoppingList } from '@/data/hooks';
import { TODAY, useUi } from '@/state/ui';
import { radius, space, type, usePalette } from '@/theme/tokens';

const fmt = new Intl.DateTimeFormat('de-DE', { day: 'numeric', month: 'short' });

export default function PlanScreen() {
  const p = usePalette();
  const wide = useIsWide();
  const { week, day, shiftWeek, setDay } = useUi();
  const catalog = useCatalog();
  const prefs = usePrefs();
  const plan = usePlan(week);
  const setPlan = useSetPlan(week);
  const { list } = useShoppingList(week);
  const snack = useSnackbar();
  const [pickTarget, setPickTarget] = useState<{ date: string; slot: Slot } | null>(null);
  const [replaceId, setReplaceId] = useState<string | null>(null);
  const [openEntry, setOpenEntry] = useState<PlanEntry | null>(null);

  const days = weekDays(week);
  const range = `${fmt.format(parseISODate(days[0]!))} – ${fmt.format(parseISODate(days[6]!))}`;

  if (catalog.isLoading || prefs.isLoading || plan.isLoading) return <Loading />;
  if (catalog.error || plan.error) return <Screen><ErrorBox message="Der Plan konnte nicht geladen werden. Prüf deine Verbindung." onRetry={() => plan.refetch()} /></Screen>;

  const entries = plan.data ?? [];
  const slots: Slot[] = prefs.data?.includeBreakfast || entries.some((e) => e.slot === 'breakfast') ? [...SLOTS] : ['lunch', 'dinner'];
  const filled = entries.length;
  const totalSlots = slots.length * 7;

  const fill = () => {
    if (!catalog.data || !prefs.data) return;
    const before = entries;
    const next = autofillWeek({ week, entries, recipes: catalog.data.recipes, ingredients: catalog.data.ings, prefs: prefs.data });
    setPlan.mutate(next);
    const added = next.length - before.length;
    snack({
      message: added > 0 ? `${added} Mahlzeiten eingeplant, mit Blick auf volle Packungen.` : 'Die Woche ist schon voll.',
      action: added > 0 ? { label: 'Rückgängig', onPress: () => setPlan.mutate(before) } : undefined,
    });
  };

  const summary = list ? leftoverSummary(list) : null;
  const packages = list?.items.filter((i) => !i.assumedStock && i.source === 'auto').length ?? 0;

  return (
    <View style={{ flex: 1, backgroundColor: p.ground }}>
      <Screen contentStyle={{ paddingHorizontal: 0, maxWidth: '100%' }}>
        <FrameHeader
          title={`Woche ${isoWeek(week)}`}
          subtitle={`${range} · ${filled} von ${totalSlots} Mahlzeiten geplant`}
          left={<IconButton icon={ChevronLeft} label="Vorherige Woche" color={p.frameInk} onPress={() => shiftWeek(-1)} />}
          right={
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: space.sm }}>
              {wide ? <Button label="Woche füllen" icon={CalendarCheck} variant="onFrame" onPress={fill} /> : null}
              <IconButton icon={ChevronRight} label="Nächste Woche" color={p.frameInk} onPress={() => shiftWeek(1)} />
            </View>
          }
        >
          {!wide ? (
            <View style={styles.dayStrip} accessibilityRole="tablist">
              {days.map((d) => {
                const sel = d === day;
                const count = entries.filter((e) => e.date === d).length;
                return (
                  <Pressable
                    key={d}
                    accessibilityRole="tab"
                    accessibilityState={{ selected: sel }}
                    accessibilityLabel={`${dayLong(d)}${d === TODAY ? ', heute' : ''}, ${count} Mahlzeiten`}
                    onPress={() => setDay(d)}
                    style={[styles.dayChip, { backgroundColor: sel ? p.frameInk : 'transparent', borderColor: d === TODAY ? p.frameInk : 'rgba(255,255,255,0.35)' }]}
                  >
                    <Text style={[type.label, { color: sel ? p.frame : p.frameInk }]}>{dayShort(d)}</Text>
                    <Text style={[type.monoStrong, { color: sel ? p.frame : p.frameInk }]}>{parseISODate(d).getDate()}</Text>
                    <View style={[styles.dot, { backgroundColor: count ? (sel ? p.frame : p.frameInk) : 'transparent' }]} />
                  </Pressable>
                );
              })}
            </View>
          ) : null}
        </FrameHeader>

        <View style={styles.body}>
          {!wide && <Button label="Woche automatisch füllen" icon={CalendarCheck} onPress={fill} />}

          <View style={[styles.days, wide && styles.daysWide]}>
            {(wide ? days : days.includes(day) ? [day] : [days[0]!]).map((d) => (
              <DayCard
                key={d}
                date={d}
                slots={slots}
                entries={entries}
                wide={wide}
                onAdd={(slot) => { setReplaceId(null); setPickTarget({ date: d, slot }); }}
                onOpen={setOpenEntry}
              />
            ))}
          </View>

          {list && list.items.length > 0 ? (
            <Pressable accessibilityRole="button" accessibilityLabel="Zur Einkaufsliste" onPress={() => router.push('/shopping')}>
              <Paper torn="top">
                <View style={{ gap: space.sm }}>
                  <Text style={[type.monoStrong, { color: p.ink }]}>EINKAUF KW {isoWeek(week)}</Text>
                  <Text style={[type.mono, { color: p.inkMuted }]}>
                    {packages} Positionen · {summary?.open ? `${summary.open} Rest${summary.open > 1 ? 'e' : ''} mit Rezeptvorschlag` : 'kein Rest, der verdirbt'}
                  </Text>
                  <View style={styles.receiptLink}>
                    <Txt variant="bodyStrong" color="accent">Zum Bon</Txt>
                    <ChevronRight size={20} color={p.accent} />
                  </View>
                </View>
              </Paper>
            </Pressable>
          ) : null}
        </View>
      </Screen>

      <PickerSheet week={week} target={pickTarget} replaceId={replaceId} onClose={() => { setPickTarget(null); setReplaceId(null); }} />
      <EntrySheet
        week={week}
        entry={openEntry}
        onClose={() => setOpenEntry(null)}
        onSwap={(e) => {
          setOpenEntry(null);
          setReplaceId(e.id);
          setPickTarget({ date: e.date, slot: e.slot });
        }}
      />
    </View>
  );
}

function DayCard({
  date,
  slots,
  entries,
  wide,
  onAdd,
  onOpen,
}: {
  date: string;
  slots: Slot[];
  entries: PlanEntry[];
  wide: boolean;
  onAdd: (slot: Slot) => void;
  onOpen: (e: PlanEntry) => void;
}) {
  const p = usePalette();
  const catalog = useCatalog();
  const isToday = date === TODAY;
  return (
    <Paper torn="bottom" style={wide ? styles.dayWide : undefined}>
      <View style={styles.dayHead}>
        <Txt variant="title" accessibilityRole="header">{dayLong(date)}</Txt>
        <Text style={[type.mono, { color: isToday ? p.accent : p.inkMuted }]}>{isToday ? 'HEUTE' : fmt.format(parseISODate(date))}</Text>
      </View>
      <View style={{ gap: space.sm }}>
        {slots.map((slot) => {
          const e = entryAt(entries, date, slot);
          const r = e ? catalog.data?.recipeById.get(e.recipeId) : undefined;
          const cook = e?.leftoverOf ? entries.find((x) => x.id === e.leftoverOf) : undefined;
          if (!e || !r)
            return (
              <Pressable
                key={slot}
                accessibilityRole="button"
                accessibilityLabel={`${SLOT_LABEL[slot]} am ${dayLong(date)}: Rezept wählen`}
                onPress={() => onAdd(slot)}
                style={(s: PState) => [styles.empty, { borderColor: p.rule, backgroundColor: s.hovered ? p.paperSunk : 'transparent' }]}
              >
                <Text style={[type.label, { color: p.inkMuted, width: 72 }]}>{SLOT_LABEL[slot]}</Text>
                <Plus size={18} color={p.accent} />
                <Text style={[type.label, { color: p.accent }]}>Rezept wählen</Text>
              </Pressable>
            );
          return (
            <Pressable
              key={slot}
              accessibilityRole="button"
              accessibilityLabel={`${SLOT_LABEL[slot]}: ${r.title}, ${cook ? `Rest vom ${dayLong(cook.date)}` : `${e.servings} Portionen`}. Optionen öffnen`}
              onPress={() => onOpen(e)}
              style={(s: PState) => [styles.entry, { backgroundColor: s.hovered ? p.paperSunk : 'transparent' }]}
            >
              <Text style={[type.label, { color: p.inkMuted, width: 72 }]}>{SLOT_LABEL[slot]}</Text>
              <View style={{ flex: 1, gap: 2 }}>
                <Txt variant="bodyStrong" numberOfLines={2}>{r.title}</Txt>
                {cook ? (
                  <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
                    <CornerDownRight size={14} color={p.done} />
                    <Text style={[type.mono, { color: p.done }]}>Rest vom {dayShort(cook.date)}</Text>
                  </View>
                ) : (
                  <Text style={[type.mono, { color: p.inkMuted }]}>
                    {e.servings} Port. · {r.prepMinutes} Min{entries.some((x) => x.leftoverOf === e.id) ? ` · Rest → ${dayShort(e.slot === 'dinner' ? addDays(date, 1) : date)}` : ''}
                  </Text>
                )}
              </View>
              <MoreHorizontal size={20} color={p.inkMuted} />
            </Pressable>
          );
        })}
      </View>
    </Paper>
  );
}

const styles = StyleSheet.create({
  body: { width: '100%', maxWidth: 1120, alignSelf: 'center', paddingHorizontal: space.lg, gap: space.lg, marginTop: space.lg },
  dayStrip: { flexDirection: 'row', gap: 6 },
  dayChip: { flex: 1, alignItems: 'center', paddingVertical: space.sm, borderRadius: radius.md, borderWidth: 1.5, gap: 2, minHeight: 64 },
  dot: { width: 5, height: 5, borderRadius: 3 },
  days: { gap: space.lg },
  daysWide: { flexDirection: 'row', flexWrap: 'wrap' },
  dayWide: { flexBasis: 300, flexGrow: 1, maxWidth: 420 },
  dayHead: { flexDirection: 'row', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: space.md },
  empty: { flexDirection: 'row', alignItems: 'center', gap: space.sm, minHeight: 52, borderWidth: 1.5, borderStyle: 'dashed', borderRadius: radius.md, paddingHorizontal: space.md },
  entry: { flexDirection: 'row', alignItems: 'center', gap: space.sm, minHeight: 56, paddingHorizontal: space.md, marginHorizontal: -space.xs, borderRadius: radius.md },
  receiptLink: { flexDirection: 'row', alignItems: 'center', justifyContent: 'flex-end', gap: space.xs, minHeight: 32 },
});
