/**
 * Midnight Atelier — rounded navy, graphite and copper design system.
 */

export const Colors = {
  light: {
    text: '#E8E0D4',
    background: '#0C1117',
    tint: '#B87942',
    icon: '#8A96A6',
    tabIconDefault: '#6F7A87',
    tabIconSelected: '#B87942',
  },
  dark: {
    text: '#E8E0D4',
    background: '#0C1117',
    tint: '#B87942',
    icon: '#8A96A6',
    tabIconDefault: '#6F7A87',
    tabIconSelected: '#B87942',
  },
};

/** Semantic palette — brand & feedback */
export const Semantic = {
  primary: '#B87942',
  primaryLight: '#D79760',
  primaryDark: '#8F592E',
  primaryMuted: '#263547',
  secondary: '#95A4B5',
  success: '#2F7E73',
  warning: '#D59A2F',
  danger: '#C65A5A',
  info: '#5E7B99',
  surface: '#18212C',
  surfaceElevated: '#202A36',
  surfacePress: '#293645',
  onSurface: '#E8E0D4',
  onPrimary: '#FFF8F0',
  background: '#0C1117',
  backgroundSoft: '#121A24',
  border: '#2B3948',
  borderStrong: '#46596D',
  borderLight: 'rgba(232,224,212,0.08)',
  textMuted: '#7F8A99',
  overlay: 'rgba(8,12,18,0.58)',
} as const;

/** Status colors — cool steel into copper workflow */
export const StatusColors = {
  RECEPCION: '#5D7288',
  DIAGNOSTICO: '#68819C',
  APROBACION: '#7B91AA',
  REPARACION: '#A56E3D',
  QC: '#B87942',
  ENTREGA: '#2F7E73',
  CERRADA: '#4A5562',
} as const;

/** Role badge colors */
export const RoleColors = {
  TECNICO: '#223244',
  ASESOR: '#35261D',
  JEFE_TALLER: '#2B313C',
  ADMIN: '#24303A',
} as const;

/** Shadow presets */
export const Shadows = {
  elevated: {
    shadowColor: '#04080F',
    shadowOpacity: 0.32,
    shadowRadius: 24,
    shadowOffset: { width: 0, height: 14 },
    elevation: 14,
  },
  extruded: {
    shadowColor: '#04080F',
    shadowOpacity: 0.32,
    shadowRadius: 24,
    shadowOffset: { width: 0, height: 14 },
    elevation: 14,
  },
  soft: {
    shadowColor: '#04080F',
    shadowOpacity: 0.18,
    shadowRadius: 16,
    shadowOffset: { width: 0, height: 8 },
    elevation: 6,
  },
  glow: {
    shadowColor: '#B87942',
    shadowOpacity: 0.18,
    shadowRadius: 22,
    shadowOffset: { width: 0, height: 0 },
    elevation: 10,
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
  sm: 12,
  md: 18,
  lg: 24,
  xl: 32,
  pill: 999,
} as const;

/** 4-pt / 8-dp spacing scale */
export const Spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 56,
} as const;

/** Typography sizes (minimum 16 body for mobile, see ui-ux skill §6) */
export const TypeScale = {
  caption: 12,
  label: 14,
  body: 16,
  subtitle: 20,
  title: 28,
  headline: 40,
} as const;

export const Fonts = {
  regular: 'Nunito_400Regular',
  medium: 'Nunito_600SemiBold',
  bold: 'Nunito_700Bold',
  display: 'Nunito_800ExtraBold',
} as const;
