import { Redirect, Tabs } from 'expo-router';
import type { BottomTabBarProps } from 'expo-router/build/layouts/Tabs';
import { CalendarDays, BookOpen, ReceiptText, UserRound } from 'lucide-react-native';
import { Platform, Pressable, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Loading, useIsWide, type IconType, type PState } from '@/components/ui';
import { usePrefs } from '@/data/hooks';
import { useSession } from '@/state/session';
import { fonts, radius, space, type, usePalette } from '@/theme/tokens';

const ICONS: Record<string, { icon: IconType; label: string }> = {
  plan: { icon: CalendarDays, label: 'Planen' },
  recipes: { icon: BookOpen, label: 'Rezepte' },
  shopping: { icon: ReceiptText, label: 'Einkauf' },
  profile: { icon: UserRound, label: 'Profil' },
};

/** Bottom bar on phones, sidebar on wide screens (≥ 900 px). */
function NavBar({ state, navigateToTab }: BottomTabBarProps) {
  const p = usePalette();
  const wide = useIsWide();
  const insets = useSafeAreaInsets();
  const { repo } = useSession();

  const current = state.routes[state.index]?.name ?? '';
  const activeName = current === 'recipe/[id]' || current === 'generate' ? 'recipes' : current;
  const items = state.routes.map((route) => {
    const meta = ICONS[route.name];
    if (!meta) return null;
    const focused = route.name === activeName;
    const Icon = meta.icon;
    return (
      <Pressable
        key={route.key}
        accessibilityRole="tab"
        accessibilityState={{ selected: focused }}
        accessibilityLabel={meta.label}
        onPress={() => {
          if (route.name !== current) navigateToTab(route.key);
        }}
        style={(s: PState) => [
          wide ? styles.sideItem : styles.tabItem,
          wide && focused && { backgroundColor: p.accentSoft },
          wide && s.hovered && !focused && { backgroundColor: p.paperSunk },
          s.focused && Platform.OS === 'web' && ({ outlineColor: p.focus, outlineWidth: 2, outlineStyle: 'solid' } as object),
        ]}
      >
        <View style={[!wide && styles.pill, !wide && focused && { backgroundColor: p.accentSoft }]}>
          <Icon size={22} color={focused ? p.accent : p.inkMuted} strokeWidth={focused ? 2.4 : 2} />
        </View>
        <Text style={[wide ? type.bodyStrong : type.label, { color: focused ? p.accent : p.inkMuted, fontSize: wide ? 16 : 12 }]}>{meta.label}</Text>
      </Pressable>
    );
  });

  if (wide)
    return (
      <View style={[styles.sidebar, { backgroundColor: p.paper, borderRightColor: p.rule }]}>
        <View style={[styles.brand, { backgroundColor: p.frame }]}>
          <Text style={{ fontFamily: fonts.display, fontSize: 28, color: p.frameInk, letterSpacing: -0.4 }}>MealMate</Text>
          <Text style={[type.small, { color: p.frameInkMuted }]}>{repo?.mode === 'guest' ? 'Gastmodus · Daten nur auf diesem Gerät' : 'Plane in Packungen.'}</Text>
        </View>
        <View style={{ gap: space.xs, padding: space.md }}>{items}</View>
      </View>
    );

  return (
    <View style={[styles.tabbar, { backgroundColor: p.paper, borderTopColor: p.rule, paddingBottom: Math.max(insets.bottom, space.sm) }]}>
      {items}
    </View>
  );
}

export default function TabsLayout() {
  const { status } = useSession();
  const wide = useIsWide();
  if (status === 'loading') return <Loading />;
  if (status === 'signedOut') return <Redirect href="/sign-in" />;
  return <OnboardedTabs wide={wide} />;
}

function OnboardingGuard() {
  const prefs = usePrefs();
  if (prefs.data && !prefs.data.onboarded) return <Redirect href="/onboarding" />;
  return null;
}

function OnboardedTabs({ wide }: { wide: boolean }) {
  return (
    <>
    <OnboardingGuard />
    <Tabs
      tabBar={(props) => <NavBar {...props} />}
      backBehavior="history"
      screenOptions={{ headerShown: false, tabBarPosition: wide ? 'left' : 'bottom', animation: 'fade' }}
    >
      <Tabs.Screen name="plan" />
      <Tabs.Screen name="recipes" />
      <Tabs.Screen name="shopping" />
      <Tabs.Screen name="profile" />
      <Tabs.Screen name="recipe/[id]" />
      <Tabs.Screen name="generate" />
    </Tabs>
    </>
  );
}

const styles = StyleSheet.create({
  tabbar: { flexDirection: 'row', borderTopWidth: 1, paddingTop: space.xs },
  tabItem: { flex: 1, alignItems: 'center', gap: 2, minHeight: 56, justifyContent: 'center' },
  pill: { width: 56, height: 30, borderRadius: radius.pill, alignItems: 'center', justifyContent: 'center' },
  sidebar: { width: 248, borderRightWidth: 1 },
  brand: { padding: space.xl, paddingTop: space.xxl, gap: space.xs },
  sideItem: { flexDirection: 'row', alignItems: 'center', gap: space.md, minHeight: 48, paddingHorizontal: space.md, borderRadius: radius.md },
});
