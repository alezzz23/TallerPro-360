import { ActivityIndicator, StyleSheet, Text, View } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

import { useOrder } from '@/hooks/use-orders';
import { useOrderFindings } from '@/hooks/use-diagnosis';
import { useCreateQuotation } from '@/hooks/use-quotations';
import { QuotationBuilder } from '@/components/quotation/quotation-builder';
import { Semantic, Spacing, StatusColors, TypeScale } from '@/constants/theme';
import type { QuotationCreatePayload } from '@/services/quotations';

export default function CreateQuotationScreen() {
  const { orderId } = useLocalSearchParams<{ orderId: string }>();
  const router = useRouter();

  const { data: order } = useOrder(orderId);
  const { data: findings, isLoading } = useOrderFindings(orderId);
  const createMutation = useCreateQuotation();

  const handleSubmit = (data: QuotationCreatePayload) => {
    createMutation.mutate(
      { orderId, data },
      {
        onSuccess: (quotation) => {
          router.replace(`/(auth)/quotation/${quotation.id}`);
        },
      },
    );
  };

  if (isLoading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={Semantic.primary} />
      </View>
    );
  }

  if (!findings || findings.length === 0) {
    return (
      <View style={styles.center}>
        <Ionicons name="clipboard-outline" size={48} color={Semantic.textMuted} />
        <Text style={styles.emptyText}>Sin hallazgos</Text>
        <Text style={styles.emptyHint}>
          Primero registre hallazgos en el diagnóstico para crear una cotización.
        </Text>
      </View>
    );
  }

  return (
    <QuotationBuilder
      findings={findings}
      isSubmitting={createMutation.isPending}
      onSubmit={handleSubmit}
    />
  );
}

const styles = StyleSheet.create({
  center: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: Semantic.background,
    padding: Spacing.lg,
  },
  emptyText: {
    fontSize: TypeScale.body,
    fontWeight: '600',
    color: Semantic.textMuted,
    textAlign: 'center',
    marginTop: Spacing.md,
  },
  emptyHint: {
    fontSize: TypeScale.label,
    color: Semantic.textMuted,
    textAlign: 'center',
    marginTop: Spacing.xs,
  },
});
