import { Stack } from 'expo-router';

import { Semantic, StatusColors } from '@/constants/theme';

export default function DeliveryLayout() {
  return (
    <Stack
      screenOptions={{
        headerStyle: { backgroundColor: Semantic.surface },
        headerTintColor: StatusColors.ENTREGA,
        headerTitleStyle: { fontWeight: '700', color: Semantic.onSurface },
        headerBackTitle: 'Atrás',
        contentStyle: { backgroundColor: Semantic.background },
      }}
    >
      <Stack.Screen
        name="[orderId]"
        options={{ title: 'Entrega y Cierre' }}
      />
    </Stack>
  );
}
