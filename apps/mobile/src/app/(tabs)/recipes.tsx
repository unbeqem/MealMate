import { router } from 'expo-router';
import { useMemo, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { ChefHat, ChevronRight } from 'lucide-react-native';
import { DIET_CLASS_LABELS, recipeDietClass, searchRecipes, type MealCategory } from '@mealmate/core';
import { Field, FrameHeader } from '@/components/Frame';
import { Button, Chip, Loading, Paper, Screen, Txt, useIsWide, type PState } from '@/components/ui';
import { useAllowedRecipes, useCatalog, usePrefs } from '@/data/hooks';
import { radius, space, type, usePalette } from '@/theme/tokens';

type Filter = 'all' | 'breakfast' | 'main' | 'quick' | 'veggie' | 'mine';
const FILTERS: { id: Filter; label: string }[] = [
  { id: 'all', label: 'Alle' },
  { id: 'main', label: 'Mittag & Abend' },
  { id: 'breakfast', label: 'Frühstück' },
  { id: 'quick', label: 'Bis 20 Min' },
  { id: 'veggie', label: 'Vegetarisch' },
  { id: 'mine', label: 'Meine' },
];
const CAT: Record<MealCategory, string> = { breakfast: 'Frühstück', lunch: 'Mittag', dinner: 'Abend', snack: 'Snack' };

export default function RecipesScreen() {
  const p = usePalette();
  const wide = useIsWide();
  const catalog = useCatalog();
  const prefs = usePrefs();
  const { allowed, hidden } = useAllowedRecipes();
  const [q, setQ] = useState('');
  const [filter, setFilter] = useState<Filter>('all');

  const list = useMemo(() => {
    if (!catalog.data) return [];
    let l = allowed;
    if (filter === 'breakfast') l = l.filter((r) => r.category === 'breakfast');
    if (filter === 'main') l = l.filter((r) => r.category === 'lunch' || r.category === 'dinner');
    if (filter === 'quick') l = l.filter((r) => r.prepMinutes <= 20);
    if (filter === 'veggie') l = l.filter((r) => ['vegan', 'vegetarian'].includes(recipeDietClass(r, catalog.data!.ings)));
    if (filter === 'mine') l = l.filter((r) => r.source !== 'curated');
    return q.trim() ? searchRecipes(l, q, (id) => catalog.data!.ings.get(id)?.name ?? id) : [...l].sort((a, b) => a.title.localeCompare(b.title, 'de'));
  }, [allowed, filter, q, catalog.data]);

  if (catalog.isLoading || prefs.isLoading) return <Loading />;

  return (
    <Screen contentStyle={{ paddingHorizontal: 0, maxWidth: '100%' }}>
      <FrameHeader
        title="Rezepte"
        subtitle={`${allowed.length} passen zu dir${hidden ? ` · ${hidden} wegen deiner Filter ausgeblendet` : ''}`}
        right={wide ? <Button label="Mit KI erstellen" icon={ChefHat} variant="onFrame" onPress={() => router.push('/generate')} /> : undefined}
      />
      <View style={styles.body}>
        <Field label="Suchen" placeholder="Rezept oder Zutat, z. B. Kürbis" value={q} onChangeText={setQ} autoCorrect={false} returnKeyType="search" />
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: space.sm }}>
          {FILTERS.map((f) => (
            <Chip key={f.id} label={f.label} selected={filter === f.id} onPress={() => setFilter(f.id)} />
          ))}
        </ScrollView>
        {!wide ? (
          <Button label="Rezept mit KI erstellen" icon={ChefHat} variant="secondary" onPress={() => router.push('/generate')} />
        ) : null}

        {list.length === 0 ? (
          <Paper torn="none">
            <View style={{ gap: space.sm }}>
              <Txt variant="title">Nichts gefunden</Txt>
              <Txt variant="body" color="inkMuted">{filter === 'mine' ? 'Du hast noch keine eigenen Rezepte. Erstell eins mit der KI.' : 'Versuch einen anderen Begriff oder einen anderen Filter.'}</Txt>
            </View>
          </Paper>
        ) : (
          <View style={[styles.grid, wide && styles.gridWide]}>
            {list.map((r) => {
              const diet = catalog.data ? DIET_CLASS_LABELS[recipeDietClass(r, catalog.data.ings)] : '';
              const tooLong = prefs.data?.maxCookMinutes != null && r.prepMinutes > prefs.data.maxCookMinutes;
              return (
                <Pressable
                  key={r.id}
                  accessibilityRole="link"
                  accessibilityLabel={`${r.title}, ${r.prepMinutes} Minuten, ${diet}`}
                  onPress={() => router.push(`/recipe/${r.id}`)}
                  style={(s: PState) => [
                    styles.card,
                    wide && styles.cardWide,
                    { backgroundColor: p.paper, borderColor: s.hovered ? p.accent : p.rule },
                    s.pressed && { transform: [{ scale: 0.99 }] },
                  ]}
                >
                  <View style={{ flex: 1, gap: space.xs }}>
                    <Text style={[type.mono, { color: p.inkMuted, fontSize: 11 }]}>
                      {CAT[r.category].toUpperCase()} · {r.prepMinutes} MIN{tooLong ? ' · LÄNGER ALS DEIN LIMIT' : ''}
                    </Text>
                    <Txt variant="title">{r.title}</Txt>
                    <Txt variant="small" color="inkMuted" numberOfLines={2}>{r.description}</Txt>
                    <View style={{ flexDirection: 'row', gap: space.xs, flexWrap: 'wrap', marginTop: 2 }}>
                      <Text style={[type.label, styles.tag, { color: p.accent, backgroundColor: p.accentSoft }]}>{diet}</Text>
                      {r.source === 'ai' ? <Text style={[type.label, styles.tag, { color: p.ink, backgroundColor: p.highlight }]}>KI</Text> : null}
                    </View>
                  </View>
                  <ChevronRight size={20} color={p.inkMuted} />
                </Pressable>
              );
            })}
          </View>
        )}
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  body: { width: '100%', maxWidth: 1120, alignSelf: 'center', paddingHorizontal: space.lg, gap: space.lg, marginTop: space.lg },
  grid: { gap: space.sm },
  gridWide: { flexDirection: 'row', flexWrap: 'wrap', gap: space.md },
  card: { flexDirection: 'row', alignItems: 'center', gap: space.md, padding: space.lg, borderRadius: radius.md, borderWidth: 1.5 },
  cardWide: { flexBasis: 320, flexGrow: 1, maxWidth: 520 },
  tag: { paddingHorizontal: space.sm, paddingVertical: 2, borderRadius: radius.sm, overflow: 'hidden', fontSize: 12 },
});
