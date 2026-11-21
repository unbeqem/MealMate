import { useEffect, useRef, useState, type ComponentType, type ReactNode } from 'react';
import {
  AccessibilityInfo,
  ActivityIndicator,
  Animated,
  Easing,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  View,
  useWindowDimensions,
  type PressableStateCallbackType,
  type StyleProp,
  type TextProps,
  type TextStyle,
  type ViewStyle,
} from 'react-native';
import Svg, { Path } from 'react-native-svg';
import { Minus, Plus } from 'lucide-react-native';
import { breakpoints, motion, radius, space, type, usePalette, type Palette, type TypeRole } from '@/theme/tokens';

export type IconType = ComponentType<{ size?: number; color?: string; strokeWidth?: number }>;

/* ───────────── reduced motion ───────────── */
export function useReducedMotion(): boolean {
  const [reduced, setReduced] = useState(false);
  useEffect(() => {
    AccessibilityInfo.isReduceMotionEnabled().then(setReduced).catch(() => {});
    const sub = AccessibilityInfo.addEventListener('reduceMotionChanged', setReduced);
    return () => sub.remove();
  }, []);
  return reduced;
}

export function useIsWide(): boolean {
  return useWindowDimensions().width >= breakpoints.wide;
}

/* ───────────── text ───────────── */
export function Txt({
  variant = 'body',
  color,
  style,
  ...rest
}: TextProps & { variant?: TypeRole; color?: keyof Palette | (string & {}) }) {
  const p = usePalette();
  const c = color ? ((p as Record<string, string>)[color] ?? color) : p.ink;
  return <Text {...rest} style={[type[variant] as TextStyle, { color: c }, style]} />;
}

/* ───────────── focus ring for web ───────────── */
export type PState = PressableStateCallbackType & { hovered?: boolean; focused?: boolean };
function ring(p: Palette, s: PState): ViewStyle {
  return s.focused && Platform.OS === 'web' ? ({ outlineColor: p.focus, outlineWidth: 2, outlineStyle: 'solid', outlineOffset: 2 } as ViewStyle) : {};
}

/* ───────────── buttons ───────────── */
type Variant = 'primary' | 'secondary' | 'ghost' | 'onFrame' | 'frameGhost';

export function Button({
  label,
  onPress,
  variant = 'primary',
  icon: Icon,
  loading,
  disabled,
  style,
  compact,
  accessibilityHint,
}: {
  label: string;
  onPress?: () => void;
  variant?: Variant;
  icon?: IconType;
  loading?: boolean;
  disabled?: boolean;
  style?: StyleProp<ViewStyle>;
  compact?: boolean;
  accessibilityHint?: string;
}) {
  const p = usePalette();
  const colors: Record<Variant, { bg: string; fg: string; border: string; hover: string }> = {
    primary: { bg: p.action, fg: p.onAction, border: p.action, hover: p.accent },
    secondary: { bg: 'transparent', fg: p.ink, border: p.ink, hover: p.paperSunk },
    ghost: { bg: 'transparent', fg: p.accent, border: 'transparent', hover: p.accentSoft },
    onFrame: { bg: p.frameInk, fg: p.frame, border: p.frameInk, hover: p.frameInkMuted },
    frameGhost: { bg: 'transparent', fg: p.frameInk, border: p.frameInkMuted, hover: 'rgba(255,255,255,0.12)' },
  };
  const c = colors[variant];
  const off = disabled || loading;
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      accessibilityHint={accessibilityHint}
      accessibilityState={{ disabled: !!off, busy: !!loading }}
      disabled={off}
      onPress={onPress}
      style={(s: PState) => [
        styles.btn,
        compact && styles.btnCompact,
        { backgroundColor: s.hovered && !off && variant !== 'primary' ? c.hover : c.bg, borderColor: c.border },
        variant === 'primary' && s.hovered && !off && { backgroundColor: c.hover, borderColor: c.hover },
        s.pressed && { transform: [{ scale: 0.98 }] },
        off && { opacity: 0.5 },
        ring(p, s),
        style,
      ]}
    >
      {loading ? <ActivityIndicator color={c.fg} /> : Icon ? <Icon size={18} color={c.fg} strokeWidth={2.25} /> : null}
      <Text style={[type.bodyStrong, { color: c.fg }]}>{label}</Text>
    </Pressable>
  );
}

export function IconButton({
  icon: Icon,
  label,
  onPress,
  color,
  size = 22,
  disabled,
}: {
  icon: IconType;
  label: string;
  onPress?: () => void;
  color?: string;
  size?: number;
  disabled?: boolean;
}) {
  const p = usePalette();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      disabled={disabled}
      onPress={onPress}
      hitSlop={4}
      style={(s: PState) => [
        styles.iconBtn,
        s.hovered && { backgroundColor: 'rgba(127,127,127,0.14)' },
        s.pressed && { backgroundColor: 'rgba(127,127,127,0.22)' },
        disabled && { opacity: 0.4 },
        ring(p, s),
      ]}
    >
      <Icon size={size} color={color ?? p.ink} strokeWidth={2.1} />
    </Pressable>
  );
}

export function Chip({ label, selected, onPress, icon: Icon }: { label: string; selected?: boolean; onPress?: () => void; icon?: IconType }) {
  const p = usePalette();
  return (
    <Pressable
      accessibilityRole="checkbox"
      accessibilityState={{ checked: !!selected }}
      accessibilityLabel={label}
      onPress={onPress}
      style={(s: PState) => [
        styles.chip,
        { borderColor: selected ? p.accent : p.rule, backgroundColor: selected ? p.accentSoft : s.hovered ? p.paperSunk : 'transparent' },
        ring(p, s),
      ]}
    >
      {Icon ? <Icon size={16} color={selected ? p.accent : p.inkMuted} /> : null}
      <Text style={[type.label, { color: selected ? p.accent : p.ink }]}>{label}</Text>
    </Pressable>
  );
}

/* ───────────── receipt paper ───────────── */
function Zigzag({ color, flip }: { color: string; flip?: boolean }) {
  const [w, setW] = useState(0);
  const tooth = 12;
  const n = Math.ceil(w / tooth);
  let d = `M0 0 `;
  for (let i = 0; i < n; i++) d += `L${i * tooth + tooth / 2} 7 L${(i + 1) * tooth} 0 `;
  d += `L${n * tooth} 0 Z`;
  return (
    <View onLayout={(e) => setW(e.nativeEvent.layout.width)} style={{ height: 7, transform: flip ? [{ scaleY: -1 }] : undefined }} accessible={false}>
      {w > 0 && (
        <Svg width={w} height={7}>
          <Path d={d} fill={color} />
        </Svg>
      )}
    </View>
  );
}

export function Paper({
  children,
  style,
  torn = 'bottom',
  padded = true,
}: {
  children: ReactNode;
  style?: StyleProp<ViewStyle>;
  torn?: 'none' | 'top' | 'bottom' | 'both';
  padded?: boolean;
}) {
  const p = usePalette();
  return (
    <View style={[styles.paperWrap, { shadowColor: p.shadow }, style]}>
      {(torn === 'top' || torn === 'both') && <Zigzag color={p.paper} flip />}
      <View
        style={[
          { backgroundColor: p.paper },
          padded && styles.paperPad,
          torn === 'none' && { borderRadius: radius.sm },
          torn === 'bottom' && { borderTopLeftRadius: radius.sm, borderTopRightRadius: radius.sm },
          torn === 'top' && { borderBottomLeftRadius: radius.sm, borderBottomRightRadius: radius.sm },
        ]}
      >
        {children}
      </View>
      {(torn === 'bottom' || torn === 'both') && <Zigzag color={p.paper} />}
    </View>
  );
}

export function Dashed({ style }: { style?: StyleProp<ViewStyle> }) {
  const p = usePalette();
  return <View accessible={false} style={[{ borderTopWidth: 1.5, borderStyle: 'dashed', borderColor: p.rule, marginVertical: space.md }, style]} />;
}

/** Highlighter swipe (left → right) for leftover lines. */
export function Highlight({ children, style, active = true }: { children: ReactNode; style?: StyleProp<ViewStyle>; active?: boolean }) {
  const p = usePalette();
  const reduced = useReducedMotion();
  const progress = useRef(new Animated.Value(active ? (reduced ? 1 : 0) : 0)).current;
  useEffect(() => {
    if (!active) return progress.setValue(0);
    if (reduced) return progress.setValue(1);
    Animated.timing(progress, { toValue: 1, duration: motion.swipe, delay: 120, easing: Easing.out(Easing.exp), useNativeDriver: false }).start();
  }, [active, reduced, progress]);
  const width = progress.interpolate({ inputRange: [0, 1], outputRange: ['0%', '100%'] });
  return (
    <View style={[styles.hiWrap, style]}>
      <Animated.View accessible={false} style={[StyleSheet.absoluteFill, { width, backgroundColor: p.highlight, borderRadius: 3 }]} />
      {children}
    </View>
  );
}

/** Print-feed entrance: content is visible by default; the feed only runs once, without reduced motion. */
export function Feed({ index, children }: { index: number; children: ReactNode }) {
  const reduced = useReducedMotion();
  const v = useRef(new Animated.Value(reduced ? 1 : 0)).current;
  useEffect(() => {
    if (reduced) return v.setValue(1);
    Animated.timing(v, {
      toValue: 1,
      duration: motion.enter,
      delay: Math.min(index, 8) * motion.stagger,
      easing: Easing.out(Easing.exp),
      useNativeDriver: Platform.OS !== 'web',
    }).start();
  }, [reduced, index, v]);
  return (
    <Animated.View style={{ opacity: v.interpolate({ inputRange: [0, 1], outputRange: [0.001, 1] }), transform: [{ translateY: v.interpolate({ inputRange: [0, 1], outputRange: [-6, 0] }) }] }}>
      {children}
    </Animated.View>
  );
}

/* ───────────── controls ───────────── */
export function Stepper({
  value,
  min = 1,
  max = 12,
  onChange,
  label,
  format = (n) => String(n),
}: {
  value: number;
  min?: number;
  max?: number;
  onChange: (n: number) => void;
  label: string;
  format?: (n: number) => string;
}) {
  const p = usePalette();
  return (
    <View style={styles.stepper} accessibilityRole="adjustable" accessibilityLabel={label} accessibilityValue={{ text: format(value) }}
      accessibilityActions={[{ name: 'increment' }, { name: 'decrement' }]}
      onAccessibilityAction={(e) => {
        if (e.nativeEvent.actionName === 'increment' && value < max) onChange(value + 1);
        if (e.nativeEvent.actionName === 'decrement' && value > min) onChange(value - 1);
      }}
    >
      <IconButton icon={Minus} label={`${label} verringern`} onPress={() => onChange(Math.max(min, value - 1))} disabled={value <= min} />
      <Text style={[type.monoStrong, { color: p.ink, minWidth: 88, textAlign: 'center' }]}>{format(value)}</Text>
      <IconButton icon={Plus} label={`${label} erhöhen`} onPress={() => onChange(Math.min(max, value + 1))} disabled={value >= max} />
    </View>
  );
}

export function ToggleRow({ label, hint, value, onChange }: { label: string; hint?: string; value: boolean; onChange: (v: boolean) => void }) {
  const p = usePalette();
  return (
    <Pressable accessibilityRole="switch" accessibilityState={{ checked: value }} accessibilityLabel={label} onPress={() => onChange(!value)} style={styles.toggleRow}>
      <View style={{ flex: 1, gap: 2 }}>
        <Txt variant="bodyStrong">{label}</Txt>
        {hint ? <Txt variant="small" color="inkMuted">{hint}</Txt> : null}
      </View>
      <Switch value={value} onValueChange={onChange} trackColor={{ true: p.accent, false: p.rule }} thumbColor={p.paper} accessibilityElementsHidden importantForAccessibility="no" />
    </Pressable>
  );
}

/* ───────────── layout ───────────── */
export function Screen({ children, scroll = true, contentStyle }: { children: ReactNode; scroll?: boolean; contentStyle?: StyleProp<ViewStyle> }) {
  const p = usePalette();
  const inner = <View style={[styles.screenInner, contentStyle]}>{children}</View>;
  return (
    <View style={{ flex: 1, backgroundColor: p.ground }}>
      {scroll ? (
        <ScrollView contentContainerStyle={{ paddingBottom: space.xxxl }} keyboardShouldPersistTaps="handled">
          {inner}
        </ScrollView>
      ) : (
        inner
      )}
    </View>
  );
}

export function Center({ children }: { children: ReactNode }) {
  return <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', padding: space.xl, gap: space.md }}>{children}</View>;
}

export function Loading({ label = 'Lädt …' }: { label?: string }) {
  const p = usePalette();
  return (
    <View style={{ flex: 1, backgroundColor: p.ground }}>
      <Center>
        <ActivityIndicator color={p.accent} />
        <Txt variant="small" color="inkMuted">{label}</Txt>
      </Center>
    </View>
  );
}

export function ErrorBox({ message, onRetry }: { message: string; onRetry?: () => void }) {
  const p = usePalette();
  return (
    <View accessibilityRole="alert" style={[styles.errorBox, { backgroundColor: p.dangerSoft, borderColor: p.danger }]}>
      <Txt variant="bodyStrong" color="danger">{message}</Txt>
      {onRetry ? <Button label="Erneut versuchen" variant="ghost" compact onPress={onRetry} /> : null}
    </View>
  );
}

export const styles = StyleSheet.create({
  btn: {
    minHeight: 48,
    paddingHorizontal: space.xl,
    borderRadius: radius.md,
    borderWidth: 2,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: space.sm,
  },
  btnCompact: { minHeight: 40, paddingHorizontal: space.lg },
  iconBtn: { width: 48, height: 48, borderRadius: radius.pill, alignItems: 'center', justifyContent: 'center' },
  chip: {
    minHeight: 40,
    paddingHorizontal: space.md,
    borderRadius: radius.pill,
    borderWidth: 1.5,
    flexDirection: 'row',
    alignItems: 'center',
    gap: space.xs,
  },
  paperWrap: { shadowOffset: { width: 0, height: 6 }, shadowOpacity: 1, shadowRadius: 14, elevation: 3 },
  paperPad: { paddingHorizontal: space.lg, paddingVertical: space.lg },
  hiWrap: { position: 'relative', paddingHorizontal: space.sm, paddingVertical: space.xs, marginHorizontal: -space.sm, overflow: 'hidden', borderRadius: 3 },
  stepper: { flexDirection: 'row', alignItems: 'center' },
  toggleRow: { flexDirection: 'row', alignItems: 'center', gap: space.md, minHeight: 56 },
  screenInner: { width: '100%', maxWidth: 1120, alignSelf: 'center', paddingHorizontal: space.lg, gap: space.lg },
  errorBox: { borderWidth: 1.5, borderRadius: radius.md, padding: space.lg, gap: space.sm },
});
