import { Stack } from 'expo-router';

import { Semantic, StatusColors } from '@/constants/theme';

export default function DiagnosisLayout() {
  return (
    <Stack
      screenOptions={{
        headerStyle: { backgroundColor: Semantic.surface },
        headerTintColor: StatusColors.DIAGNOSTICO,
        headerTitleStyle: { fontWeight: '700', color: Semantic.onSurface },
        headerBackTitle: 'Atrás',
        contentStyle: { backgroundColor: Semantic.background },
      }}
    >
      <Stack.Screen
        name="[orderId]"
        options={{ title: 'Diagnóstico' }}
      />
      <Stack.Screen
        name="finding/[findingId]"
        options={{ title: 'Detalle Hallazgo' }}
      />
      <Stack.Screen
        name="new-finding"
        options={{ title: 'Nuevo Hallazgo' }}
      />
    </Stack>
  );
}
