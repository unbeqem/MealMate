import { useState, type ReactNode } from 'react';
import { Platform, StyleSheet, Text, TextInput, View, type TextInputProps } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { fonts, radius, space, type, usePalette } from '@/theme/tokens';
import { useIsWide } from './ui';

/** The violet band that owns the top of every screen. */
export function FrameHeader({ title, subtitle, left, right, children }: { title: string; subtitle?: string; left?: ReactNode; right?: ReactNode; children?: ReactNode }) {
  const p = usePalette();
  const insets = useSafeAreaInsets();
  const wide = useIsWide();
  return (
    <View style={{ backgroundColor: p.frame, paddingTop: (wide ? space.xl : insets.top + space.sm), paddingBottom: space.xl }}>
      <View style={styles.inner}>
        <View style={styles.row}>
          {left}
          <View style={{ flex: 1, gap: 2 }}>
            <Text accessibilityRole="header" style={{ fontFamily: fonts.display, fontSize: wide ? 44 : 36, lineHeight: wide ? 46 : 38, letterSpacing: -0.6, color: p.frameInk }}>
              {title}
            </Text>
            {subtitle ? <Text style={[type.label, { color: p.frameInkMuted }]}>{subtitle}</Text> : null}
          </View>
          {right}
        </View>
        {children}
      </View>
    </View>
  );
}

export function Field({ label, hint, error, mono, style, ...rest }: TextInputProps & { label: string; hint?: string; error?: string | null; mono?: boolean }) {
  const p = usePalette();
  const [focus, setFocus] = useState(false);
  return (
    <View style={{ gap: space.xs }}>
      <Text style={[type.label, { color: p.ink }]}>{label}</Text>
      <TextInput
        accessibilityLabel={label}
        placeholderTextColor={p.inkMuted}
        onFocus={(e) => {
          setFocus(true);
          rest.onFocus?.(e);
        }}
        onBlur={(e) => {
          setFocus(false);
          rest.onBlur?.(e);
        }}
        style={[
          mono ? type.monoStrong : type.body,
          styles.input,
          { color: p.ink, backgroundColor: p.paper, borderColor: error ? p.danger : focus ? p.accent : p.rule },
          Platform.OS === 'web' && ({ outlineStyle: 'none' } as object),
          style,
        ]}
        {...rest}
      />
      {error ? (
        <Text accessibilityLiveRegion="polite" style={[type.small, { color: p.danger }]}>{error}</Text>
      ) : hint ? (
        <Text style={[type.small, { color: p.inkMuted }]}>{hint}</Text>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  inner: { width: '100%', maxWidth: 1120, alignSelf: 'center', paddingHorizontal: space.lg, gap: space.lg },
  row: { flexDirection: 'row', alignItems: 'center', gap: space.sm },
  input: { minHeight: 52, borderWidth: 2, borderRadius: radius.md, paddingHorizontal: space.lg },
});
