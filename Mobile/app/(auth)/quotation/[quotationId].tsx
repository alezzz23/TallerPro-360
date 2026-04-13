import { ActivityIndicator, StyleSheet, View } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useMemo } from 'react';

import { useQuotation } from '@/hooks/use-quotations';
import { useOrder } from '@/hooks/use-orders';
import { useOrderFindings } from '@/hooks/use-diagnosis';
import { QuotationPreview } from '@/components/quotation/quotation-preview';
import { Semantic, StatusColors } from '@/constants/theme';

export default function QuotationDetailScreen() {
  const { quotationId } = useLocalSearchParams<{ quotationId: string }>();
  const router = useRouter();

  const { data: quotation, isLoading } = useQuotation(quotationId);
  const { data: order } = useOrder(quotation?.order_id ?? '');
  const { data: findings } = useOrderFindings(quotation?.order_id ?? '');

  const criticalFindingIds = useMemo(() => {
    if (!findings) return new Set<string>();
    return new Set(findings.filter((f) => f.es_critico_seguridad).map((f) => f.id));
  }, [findings]);

  if (isLoading || !quotation) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={Semantic.primary} />
      </View>
    );
  }

  return (
    <QuotationPreview
      quotation={quotation}
      vehicleId={order?.vehicle_id ?? ''}
      criticalFindingIds={criticalFindingIds}
      onNavigateCreateNew={() =>
        router.replace(`/(auth)/quotation/create/${quotation.order_id}`)
      }
    />
  );
}

const styles = StyleSheet.create({
  center: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: Semantic.background,
  },
});
