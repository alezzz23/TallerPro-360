import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

import { useAuthStore } from '@/stores/auth-store';
import { Fonts, Radius, RoleColors, Semantic, Shadows, Spacing, TypeScale } from '@/constants/theme';

const ROLE_LABELS: Record<string, string> = {
  TECNICO: 'Técnico',
  ASESOR: 'Asesor',
  JEFE_TALLER: 'Jefe de Taller',
  ADMIN: 'Administrador',
};

export default function ProfileScreen() {
  const router = useRouter();
  const user = useAuthStore((s) => s.user);
  const logout = useAuthStore((s) => s.logout);

  const handleLogout = async () => {
    await logout();
    router.replace('/login');
  };

  const roleColor = user ? RoleColors[user.rol] : Semantic.secondary;
  const roleLabel = user ? ROLE_LABELS[user.rol] ?? user.rol : '';
  const initial = user?.nombre?.charAt(0)?.toUpperCase() ?? '?';

  return (
    <View style={styles.container}>
      <View style={styles.card}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>{initial}</Text>
        </View>

        <Text style={styles.screenTitle}>Perfil</Text>
        <Text style={styles.name}>{user?.nombre ?? '—'}</Text>
        <Text style={styles.email}>{user?.email ?? '—'}</Text>

        <View style={[styles.roleBadge, { backgroundColor: roleColor }]}>
          <Text style={styles.roleBadgeText}>{roleLabel}</Text>
        </View>
      </View>

      <View style={styles.infoSection}>
        <View style={styles.infoRow}>
          <View style={styles.infoLabelRow}>
            <Ionicons name="finger-print-outline" size={16} color={Semantic.secondary} />
            <Text style={styles.infoLabel}>ID</Text>
          </View>
          <Text style={styles.infoValue}>{user?.id?.slice(0, 8) ?? '—'}...</Text>
        </View>
        <View style={styles.infoRow}>
          <View style={styles.infoLabelRow}>
            <Ionicons name="pulse-outline" size={16} color={Semantic.secondary} />
            <Text style={styles.infoLabel}>Estado</Text>
          </View>
          <Text style={[styles.infoValue, { color: user?.activo ? Semantic.success : Semantic.danger }]}> 
            {user?.activo ? 'Activo' : 'Inactivo'}
          </Text>
        </View>
      </View>

      <Pressable
        style={({ pressed }) => [
          styles.logoutButton,
          pressed && styles.logoutButtonPressed,
        ]}
        onPress={handleLogout}
      >
        <Text style={styles.logoutText}>Cerrar sesión</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: Spacing.lg,
    paddingTop: 60,
    backgroundColor: Semantic.background,
  },
  card: {
    alignItems: 'center',
    backgroundColor: Semantic.surface,
    borderRadius: Radius.xl,
    padding: Spacing.lg,
    ...Shadows.elevated,
    borderWidth: 1,
    borderColor: Semantic.borderLight,
  },
  avatar: {
    width: 72,
    height: 72,
    borderRadius: 36,
    backgroundColor: Semantic.primary,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: Spacing.md,
    ...Shadows.glow,
  },
  avatarText: {
    color: Semantic.onPrimary,
    fontSize: TypeScale.title,
    fontFamily: Fonts.display,
  },
  screenTitle: {
    fontSize: TypeScale.caption,
    fontFamily: Fonts.bold,
    color: Semantic.primary,
    textTransform: 'uppercase',
    letterSpacing: 0.8,
    marginBottom: Spacing.xs,
  },
  name: {
    fontSize: TypeScale.subtitle,
    fontFamily: Fonts.bold,
    color: Semantic.onSurface,
  },
  email: {
    fontSize: TypeScale.body,
    color: Semantic.secondary,
    fontFamily: Fonts.medium,
    marginTop: Spacing.xs,
    marginBottom: Spacing.md,
  },
  roleBadge: {
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.xs,
    borderRadius: Radius.pill,
  },
  roleBadgeText: {
    color: Semantic.onSurface,
    fontSize: TypeScale.label,
    fontFamily: Fonts.bold,
  },
  infoSection: {
    backgroundColor: Semantic.surface,
    borderRadius: Radius.xl,
    padding: Spacing.md,
    marginTop: Spacing.md,
    ...Shadows.elevated,
    borderWidth: 1,
    borderColor: Semantic.borderLight,
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
  },
  infoLabelRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.xs,
  },
  infoLabel: {
    fontSize: TypeScale.body,
    color: Semantic.secondary,
    fontFamily: Fonts.medium,
  },
  infoValue: {
    fontSize: TypeScale.body,
    color: Semantic.onSurface,
    fontFamily: Fonts.bold,
  },
  logoutButton: {
    height: 48,
    backgroundColor: Semantic.danger,
    borderRadius: Radius.pill,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: Spacing.xl,
    ...Shadows.elevated,
  },
  logoutButtonPressed: {
    ...Shadows.none,
    backgroundColor: '#A34444',
    transform: [{ scale: 0.985 }],
  },
  logoutText: {
    color: Semantic.onPrimary,
    fontSize: TypeScale.body,
    fontFamily: Fonts.bold,
  },
});
