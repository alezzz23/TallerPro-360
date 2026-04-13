import { Stack } from 'expo-router';

import { Semantic, StatusColors } from '@/constants/theme';

export default function ReceptionLayout() {
  return (
    <Stack
      screenOptions={{
        headerStyle: { backgroundColor: Semantic.surface },
        headerTintColor: StatusColors.RECEPCION,
        headerTitleStyle: { fontWeight: '700', color: Semantic.onSurface },
        headerBackTitle: 'Atrás',
        contentStyle: { backgroundColor: Semantic.background },
      }}
    >
      <Stack.Screen
        name="vehicle-search"
        options={{ title: 'Nueva Recepción' }}
      />
      <Stack.Screen
        name="checklist"
        options={{ title: 'Checklist de Recepción' }}
      />
      <Stack.Screen
        name="damages"
        options={{ title: 'Daños Preexistentes' }}
      />
      <Stack.Screen
        name="photos"
        options={{ title: 'Fotos Perimetrales' }}
      />
      <Stack.Screen
        name="signature"
        options={{ title: 'Firma del Cliente' }}
      />
    </Stack>
  );
}
