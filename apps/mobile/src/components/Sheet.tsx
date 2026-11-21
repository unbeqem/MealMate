import { createContext, useCallback, useContext, useEffect, useRef, useState, type ReactNode } from 'react';
import { Animated, Easing, KeyboardAvoidingView, Modal, Platform, Pressable, ScrollView, StyleSheet, View, useWindowDimensions } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { X } from 'lucide-react-native';
import { breakpoints, motion, radius, space, usePalette } from '@/theme/tokens';
import { Button, IconButton, Txt, useReducedMotion } from './ui';

/**
 * Bottom sheet on phones, centered panel on wide screens.
 * Opens in 260 ms (ease-out), closes in 140 ms (ease-in) – fast close.
 */
export function Sheet({ open, onClose, title, children, footer }: { open: boolean; onClose: () => void; title: string; children: ReactNode; footer?: ReactNode }) {
  const p = usePalette();
  const insets = useSafeAreaInsets();
  const wide = useWindowDimensions().width >= breakpoints.wide;
  const reduced = useReducedMotion();
  const [mounted, setMounted] = useState(open);
  const v = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (open) {
      setMounted(true);
      Animated.timing(v, { toValue: 1, duration: reduced ? 0 : motion.enter, easing: Easing.out(Easing.exp), useNativeDriver: Platform.OS !== 'web' }).start();
    } else if (mounted) {
      Animated.timing(v, { toValue: 0, duration: reduced ? 0 : motion.exit, easing: Easing.in(Easing.cubic), useNativeDriver: Platform.OS !== 'web' }).start(() => setMounted(false));
    }
  }, [open, mounted, reduced, v]);

  if (!mounted) return null;
  const translateY = v.interpolate({ inputRange: [0, 1], outputRange: [wide ? 24 : 420, 0] });

  return (
    <Modal transparent visible animationType="none" onRequestClose={onClose} statusBarTranslucent>
      <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={{ flex: 1 }}>
        <Animated.View style={[StyleSheet.absoluteFill, { backgroundColor: 'rgba(18,14,36,0.55)', opacity: v }]}>
          <Pressable style={StyleSheet.absoluteFill} onPress={onClose} accessibilityLabel="Schließen" accessibilityRole="button" />
        </Animated.View>
        <View style={[styles.host, wide && styles.hostWide]} pointerEvents="box-none">
          <Animated.View
            accessibilityViewIsModal
            style={[
              styles.panel,
              { backgroundColor: p.paper, paddingBottom: Math.max(insets.bottom, space.lg), opacity: wide ? v : 1, transform: [{ translateY }] },
              wide && styles.panelWide,
            ]}
          >
            <View style={styles.head}>
              <Txt variant="headline" style={{ flex: 1 }} accessibilityRole="header">{title}</Txt>
              <IconButton icon={X} label="Schließen" onPress={onClose} />
            </View>
            <ScrollView style={{ flexGrow: 0 }} contentContainerStyle={{ paddingHorizontal: space.lg, gap: space.md, paddingBottom: space.md }} keyboardShouldPersistTaps="handled">
              {children}
            </ScrollView>
            {footer ? <View style={{ paddingHorizontal: space.lg, paddingTop: space.sm, gap: space.sm }}>{footer}</View> : null}
          </Animated.View>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
}

/* ───────────── Snackbar (transient feedback with optional action) ───────────── */
interface Snack {
  message: string;
  action?: { label: string; onPress: () => void };
}
const SnackCtx = createContext<(s: Snack) => void>(() => {});
export const useSnackbar = () => useContext(SnackCtx);

export function SnackbarProvider({ children }: { children: ReactNode }) {
  const p = usePalette();
  const insets = useSafeAreaInsets();
  const [snack, setSnack] = useState<Snack | null>(null);
  const v = useRef(new Animated.Value(0)).current;
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const hide = useCallback(() => {
    Animated.timing(v, { toValue: 0, duration: motion.exit, useNativeDriver: Platform.OS !== 'web' }).start(() => setSnack(null));
  }, [v]);

  const show = useCallback(
    (s: Snack) => {
      if (timer.current) clearTimeout(timer.current);
      setSnack(s);
      v.setValue(0);
      Animated.timing(v, { toValue: 1, duration: motion.enter, easing: Easing.out(Easing.exp), useNativeDriver: Platform.OS !== 'web' }).start();
      timer.current = setTimeout(hide, s.action ? 5000 : 3000);
    },
    [hide, v],
  );

  return (
    <SnackCtx.Provider value={show}>
      {children}
      {snack ? (
        <Animated.View
          accessibilityLiveRegion="polite"
          accessibilityRole="alert"
          style={[styles.snack, { backgroundColor: p.ink, bottom: insets.bottom + 88, opacity: v, transform: [{ translateY: v.interpolate({ inputRange: [0, 1], outputRange: [16, 0] }) }] }]}
        >
          <Txt variant="label" color={p.paper} style={{ flex: 1 }}>{snack.message}</Txt>
          {snack.action ? (
            <Button
              label={snack.action.label}
              variant="ghost"
              compact
              onPress={() => {
                snack.action!.onPress();
                hide();
              }}
              style={{ borderColor: 'transparent' }}
            />
          ) : null}
        </Animated.View>
      ) : null}
    </SnackCtx.Provider>
  );
}

const styles = StyleSheet.create({
  host: { flex: 1, justifyContent: 'flex-end' },
  hostWide: { justifyContent: 'center', alignItems: 'center', padding: space.xl },
  panel: { borderTopLeftRadius: radius.lg, borderTopRightRadius: radius.lg, maxHeight: '88%', paddingTop: space.sm },
  panelWide: { width: 560, borderRadius: radius.lg, maxHeight: '85%' },
  head: { flexDirection: 'row', alignItems: 'center', paddingLeft: space.lg, paddingRight: space.sm, paddingVertical: space.sm },
  snack: {
    position: 'absolute',
    left: space.lg,
    right: space.lg,
    maxWidth: 560,
    alignSelf: 'center',
    borderRadius: radius.md,
    paddingLeft: space.lg,
    paddingRight: space.xs,
    minHeight: 52,
    flexDirection: 'row',
    alignItems: 'center',
    gap: space.sm,
  },
});
