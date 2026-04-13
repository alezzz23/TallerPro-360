import { Stack } from 'expo-router';

import { Semantic, StatusColors } from '@/constants/theme';

export default function QCLayout() {
  return (
    <Stack
      screenOptions={{
        headerStyle: { backgroundColor: Semantic.surface },
        headerTintColor: StatusColors.QC,
        headerTitleStyle: { fontWeight: '700', color: Semantic.onSurface },
        headerBackTitle: 'Atrás',
        contentStyle: { backgroundColor: Semantic.background },
      }}
    >
      <Stack.Screen
        name="[orderId]"
        options={{ title: 'Control de Calidad' }}
      />
    </Stack>
  );
}
