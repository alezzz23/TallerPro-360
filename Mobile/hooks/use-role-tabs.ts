import { useAuthStore } from '@/stores/auth-store';
import type { UserRole } from '@/types/api';

export type TabName = 'index' | 'orders' | 'assignments' | 'customers' | 'qc' | 'users' | 'profile';

const ROLE_TABS: Record<UserRole, TabName[]> = {
  TECNICO: ['index', 'assignments', 'qc', 'profile'],
  ASESOR: ['index', 'orders', 'customers', 'profile'],
  JEFE_TALLER: ['index', 'orders', 'qc', 'profile'],
  ADMIN: ['index', 'orders', 'qc', 'users', 'profile'],
};

export function useRoleTabs(): TabName[] {
  const role = useAuthStore((s) => s.user?.rol);
  return ROLE_TABS[role ?? 'ASESOR'];
}
