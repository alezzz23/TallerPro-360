import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useRouter } from 'expo-router';

import { useAuthStore } from '@/stores/auth-store';
import { RoleColors, Semantic, Spacing, TypeScale, Shadows, Radius } from '@/constants/theme';

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

  return (
    <View style={styles.container}>
      <Text style={styles.screenTitle}>Perfil</Text>

      <View style={styles.card}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>
            {user?.nombre?.charAt(0)?.toUpperCase() ?? '?'}
          </Text>
        </View>

        <Text style={styles.name}>{user?.nombre ?? '—'}</Text>
        <Text style={styles.email}>{user?.email ?? '—'}</Text>

        <View style={[styles.roleBadge, { backgroundColor: roleColor }]}>
          <Text style={styles.roleBadgeText}>{roleLabel}</Text>
        </View>
      </View>

      <View style={styles.infoSection}>
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>ID</Text>
          <Text style={styles.infoValue}>{user?.id?.slice(0, 8) ?? '—'}...</Text>
        </View>
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Estado</Text>
          <Text style={[styles.infoValue, { color: user?.activo ? '#22C55E' : Semantic.danger }]}>
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
    backgroundColor: '#0A0A0A',
  },
  screenTitle: {
    fontSize: TypeScale.title,
    fontWeight: '700',
    color: '#F5F5F5',
  },
  card: {
    alignItems: 'center',
    backgroundColor: '#161616',
    borderRadius: Radius.lg,
    padding: Spacing.lg,
    marginTop: Spacing.lg,
    ...Shadows.extruded,
    borderTopWidth: 1,
    borderLeftWidth: 1,
    borderTopColor: 'rgba(255,255,255,0.06)',
    borderLeftColor: 'rgba(255,255,255,0.06)',
  },
  avatar: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: '#22C55E',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: Spacing.md,
    ...Shadows.glow,
  },
  avatarText: {
    color: '#0A0A0A',
    fontSize: TypeScale.title,
    fontWeight: '700',
  },
  name: {
    fontSize: TypeScale.subtitle,
    fontWeight: '600',
    color: '#F5F5F5',
  },
  email: {
    fontSize: TypeScale.body,
    color: '#A3A3A3',
    marginTop: Spacing.xs,
    marginBottom: Spacing.md,
  },
  roleBadge: {
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.xs,
    borderRadius: Radius.pill,
  },
  roleBadgeText: {
    color: '#0A0A0A',
    fontSize: TypeScale.label,
    fontWeight: '600',
  },
  infoSection: {
    backgroundColor: '#161616',
    borderRadius: Radius.lg,
    padding: Spacing.md,
    marginTop: Spacing.md,
    ...Shadows.extruded,
    borderTopWidth: 1,
    borderLeftWidth: 1,
    borderTopColor: 'rgba(255,255,255,0.06)',
    borderLeftColor: 'rgba(255,255,255,0.06)',
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: Spacing.sm,
  },
  infoLabel: {
    fontSize: TypeScale.body,
    color: '#A3A3A3',
  },
  infoValue: {
    fontSize: TypeScale.body,
    color: '#F5F5F5',
    fontWeight: '500',
  },
  logoutButton: {
    height: 48,
    backgroundColor: Semantic.danger,
    borderRadius: Radius.pill,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: Spacing.xl,
    ...Shadows.extruded,
  },
  logoutButtonPressed: {
    ...Shadows.none,
    backgroundColor: '#DC2626',
    transform: [{ scale: 0.97 }],
  },
  logoutText: {
    color: '#FFFFFF',
    fontSize: TypeScale.body,
    fontWeight: '600',
  },
});
