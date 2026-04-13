import { Redirect, Stack } from 'expo-router';

import { useAuthStore } from '@/stores/auth-store';
import { Semantic } from '@/constants/theme';

export default function AuthLayout() {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  const isLoading = useAuthStore((s) => s.isLoading);

  if (isLoading) {
    return null; // splash screen stays visible while restoring session
  }

  if (!isAuthenticated) {
    return <Redirect href="/login" />;
  }

  return (
    <Stack
      screenOptions={{
        headerShown: false,
        contentStyle: { backgroundColor: Semantic.background },
      }}
    />
  );
}
