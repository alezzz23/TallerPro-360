import { Stack } from 'expo-router';

import { Semantic, StatusColors } from '@/constants/theme';

export default function QuotationLayout() {
  return (
    <Stack
      screenOptions={{
        headerStyle: { backgroundColor: Semantic.surface },
        headerTintColor: StatusColors.APROBACION,
        headerTitleStyle: { fontWeight: '700', color: Semantic.onSurface },
        headerBackTitle: 'Atrás',
        contentStyle: { backgroundColor: Semantic.background },
      }}
    >
      <Stack.Screen
        name="create/[orderId]"
        options={{ title: 'Crear Cotización' }}
      />
      <Stack.Screen
        name="[quotationId]"
        options={{ title: 'Cotización' }}
      />
    </Stack>
  );
}
