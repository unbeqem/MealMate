import { useColorScheme } from 'react-native';

/**
 * "Der Kassenbon" — design tokens.
 * Violet owns the frame (headers, brand), thermal paper carries the content,
 * highlighter yellow is reserved for leftover lines, mint for "verplant/erledigt".
 */
const light = {
  ground: '#EEEBFA', // app background, violet-tinted
  frame: '#6B4CF0', // brand violet, owns header regions (white text 5.4:1)
  frameInk: '#FFFFFF',
  frameInkMuted: '#EFEAFF', // 4.6:1 on frame
  paper: '#FBFBF8',
  paperSunk: '#F1F0EA',
  ink: '#1A1A1A',
  inkMuted: '#5B5A55',
  rule: '#D6D4CB',
  action: '#2B1A78', // primary button fill
  onAction: '#FFFFFF',
  accent: '#6A48F5', // links, selected states on paper
  accentSoft: '#E7E1FF',
  highlight: '#FFE45C',
  onHighlight: '#2A2400',
  done: '#1F9E73',
  doneSoft: '#D5F6EA',
  danger: '#B42332',
  dangerSoft: '#FBE3E5',
  focus: '#6A48F5',
  shadow: 'rgba(43, 26, 120, 0.16)',
};

export type Palette = typeof light;

const dark: Palette = {
  ground: '#120E24',
  frame: '#2A1F63',
  frameInk: '#F4F1FF',
  frameInkMuted: '#C9BFFF',
  paper: '#1E1A33',
  paperSunk: '#17142A',
  ink: '#F3F1FF',
  inkMuted: '#B4AED3',
  rule: '#3A3460',
  action: '#A895FF',
  onAction: '#120E24',
  accent: '#B7A6FF',
  accentSoft: '#2F2758',
  highlight: '#FFE45C',
  onHighlight: '#2A2400',
  done: '#5CE1B0',
  doneSoft: '#173B30',
  danger: '#FF8A94',
  dangerSoft: '#3D1A22',
  focus: '#B7A6FF',
  shadow: 'rgba(0, 0, 0, 0.45)',
};

export const fonts = {
  display: 'ArchivoNarrow_700Bold',
  displayMedium: 'ArchivoNarrow_600SemiBold',
  body: 'Archivo_400Regular',
  bodyMedium: 'Archivo_500Medium',
  bodyBold: 'Archivo_700Bold',
  heavy: 'Archivo_800ExtraBold',
  mono: 'MartianMono_400Regular',
  monoBold: 'MartianMono_600SemiBold',
} as const;

/** Type roles (sizes in dp/sp; RN scales with the system font setting). */
export const type = {
  display: { fontFamily: fonts.display, fontSize: 40, lineHeight: 42, letterSpacing: -0.6 },
  headline: { fontFamily: fonts.display, fontSize: 28, lineHeight: 32, letterSpacing: -0.3 },
  title: { fontFamily: fonts.bodyBold, fontSize: 18, lineHeight: 24 },
  body: { fontFamily: fonts.body, fontSize: 16, lineHeight: 23 },
  bodyStrong: { fontFamily: fonts.bodyBold, fontSize: 16, lineHeight: 23 },
  label: { fontFamily: fonts.bodyMedium, fontSize: 14, lineHeight: 19 },
  small: { fontFamily: fonts.body, fontSize: 13, lineHeight: 18 },
  mono: { fontFamily: fonts.mono, fontSize: 13, lineHeight: 19 },
  monoStrong: { fontFamily: fonts.monoBold, fontSize: 14, lineHeight: 20 },
} as const;

export type TypeRole = keyof typeof type;

export const space = { xxs: 2, xs: 4, sm: 8, md: 12, lg: 16, xl: 24, xxl: 32, xxxl: 48 } as const;
export const radius = { sm: 6, md: 10, lg: 16, pill: 999 } as const;

/** Motion grammar: print feed (stagger), highlighter swipe, fast close. */
export const motion = {
  press: 120,
  enter: 260,
  exit: 140,
  stagger: 40,
  swipe: 220,
} as const;

export const breakpoints = { wide: 900 } as const;

export function usePalette(): Palette {
  return useColorScheme() === 'dark' ? dark : light;
}

export const palettes = { light, dark };
