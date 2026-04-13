/**
 * Midnight Workshop — monochromatic black + white + green design system.
 * Extruded elements with multi-shadow cards, pill buttons, Ionicons only.
 */

import { Platform } from 'react-native';

export const Colors = {
  light: {
    text: '#F5F5F5',
    background: '#0A0A0A',
    tint: '#22C55E',
    icon: '#A3A3A3',
    tabIconDefault: '#525252',
    tabIconSelected: '#22C55E',
  },
  dark: {
    text: '#F5F5F5',
    background: '#0A0A0A',
    tint: '#22C55E',
    icon: '#A3A3A3',
    tabIconDefault: '#525252',
    tabIconSelected: '#22C55E',
  },
};

/** Semantic palette — brand & feedback */
export const Semantic = {
  primary: '#22C55E',
  primaryLight: '#4ADE80',
  primaryDark: '#16A34A',
  primaryMuted: '#14532D',
  secondary: '#A3A3A3',
  success: '#22C55E',
  warning: '#EAB308',
  danger: '#EF4444',
  info: '#3B82F6',
  surface: '#161616',
  surfaceElevated: '#1E1E1E',
  surfacePress: '#111111',
  onSurface: '#F5F5F5',
  onPrimary: '#0A0A0A',
  background: '#0A0A0A',
  border: '#2A2A2A',
  borderLight: 'rgba(255,255,255,0.06)',
  textMuted: '#525252',
} as const;

/** Status colors — green pipeline gradient */
export const StatusColors = {
  RECEPCION: '#134E2B',
  DIAGNOSTICO: '#166534',
  APROBACION: '#15803D',
  REPARACION: '#16A34A',
  QC: '#22C55E',
  ENTREGA: '#4ADE80',
  CERRADA: '#404040',
} as const;

/** Role badge colors */
export const RoleColors = {
  TECNICO: '#22C55E',
  ASESOR: '#4ADE80',
  JEFE_TALLER: '#86EFAC',
  ADMIN: '#DCFCE7',
} as const;

/** Shadow presets */
export const Shadows = {
  extruded: {
    shadowColor: '#000',
    shadowOpacity: 0.7,
    shadowRadius: 10,
    shadowOffset: { width: 4, height: 4 },
    elevation: 8,
  },
  soft: {
    shadowColor: '#000',
    shadowOpacity: 0.4,
    shadowRadius: 6,
    shadowOffset: { width: 2, height: 2 },
    elevation: 4,
  },
  glow: {
    shadowColor: '#22C55E',
    shadowOpacity: 0.3,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 0 },
    elevation: 6,
  },
  none: {
    shadowColor: 'transparent',
    shadowOpacity: 0,
    shadowRadius: 0,
    shadowOffset: { width: 0, height: 0 },
    elevation: 0,
  },
} as const;

/** Border radius scale */
export const Radius = {
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  pill: 999,
} as const;

/** 4-pt / 8-dp spacing scale */
export const Spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
} as const;

/** Typography sizes (minimum 16 body for mobile, see ui-ux skill §6) */
export const TypeScale = {
  caption: 12,
  label: 14,
  body: 16,
  subtitle: 18,
  title: 24,
  headline: 32,
} as const;

export const Fonts = Platform.select({
  ios: {
    /** iOS `UIFontDescriptorSystemDesignDefault` */
    sans: 'system-ui',
    /** iOS `UIFontDescriptorSystemDesignSerif` */
    serif: 'ui-serif',
    /** iOS `UIFontDescriptorSystemDesignRounded` */
    rounded: 'ui-rounded',
    /** iOS `UIFontDescriptorSystemDesignMonospaced` */
    mono: 'ui-monospace',
  },
  default: {
    sans: 'normal',
    serif: 'serif',
    rounded: 'normal',
    mono: 'monospace',
  },
  web: {
    sans: "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif",
    serif: "Georgia, 'Times New Roman', serif",
    rounded: "'SF Pro Rounded', 'Hiragino Maru Gothic ProN', Meiryo, 'MS PGothic', sans-serif",
    mono: "SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New', monospace",
  },
});
