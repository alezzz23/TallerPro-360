import { useCallback, useState } from 'react';
import {
  ActivityIndicator,
  FlatList,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';

import { Radius, Semantic, Shadows, Spacing, TypeScale } from '@/constants/theme';
import { useDebouncedSearch, useVehicleSearch } from '@/hooks/use-reception';
import type { Vehicle } from '@/types/api';

interface Props {
  onSelect: (vehicle: Vehicle) => void;
  selectedVehicle: Vehicle | null;
}

export function VehicleSearchInput({ onSelect, selectedVehicle }: Props) {
  const [inputText, setInputText] = useState('');
  const [showResults, setShowResults] = useState(false);
  const { debouncedQuery, setQuery } = useDebouncedSearch(350);
  const { data, isLoading } = useVehicleSearch(debouncedQuery);

  const handleChangeText = useCallback(
    (text: string) => {
      setInputText(text);
      setQuery(text);
      setShowResults(true);
    },
    [setQuery],
  );

  const handleSelect = useCallback(
    (vehicle: Vehicle) => {
      onSelect(vehicle);
      setInputText(`${vehicle.placa} — ${vehicle.marca} ${vehicle.modelo}`);
      setShowResults(false);
    },
    [onSelect],
  );

  const handleClear = useCallback(() => {
    setInputText('');
    setQuery('');
    setShowResults(false);
    onSelect(null as any);
  }, [setQuery, onSelect]);

  return (
    <View style={styles.container}>
      <Text style={styles.label}>Buscar vehículo (placa o VIN)</Text>
      <View style={styles.inputRow}>
        <TextInput
          style={styles.input}
          placeholder="Ej: ABC-123 o VIN..."
          placeholderTextColor="#9E9E9E"
          value={inputText}
          onChangeText={handleChangeText}
          autoCapitalize="characters"
        />
        {selectedVehicle && (
          <Pressable onPress={handleClear} style={styles.clearBtn}>
            <Ionicons name="close" size={18} color={Semantic.onSurface} />
          </Pressable>
        )}
      </View>

      {showResults && debouncedQuery.length >= 2 && (
        <View style={styles.dropdown}>
          {isLoading && (
            <View style={styles.loadingRow}>
              <ActivityIndicator size="small" color={Semantic.primary} />
              <Text style={styles.loadingText}>Buscando…</Text>
            </View>
          )}

          {!isLoading && data && data.items.length === 0 && (
            <Text style={styles.noResults}>
              No se encontraron vehículos
            </Text>
          )}

          {!isLoading && data && data.items.length > 0 && (
            <FlatList
              data={data.items}
              keyExtractor={(v) => v.id}
              style={styles.list}
              keyboardShouldPersistTaps="handled"
              renderItem={({ item }) => (
                <Pressable
                  style={({ pressed }) => [
                    styles.resultItem,
                    pressed && styles.resultItemPressed,
                  ]}
                  onPress={() => handleSelect(item)}
                >
                  <Text style={styles.resultPlaca}>{item.placa}</Text>
                  <Text style={styles.resultDetail}>
                    {item.marca} {item.modelo}
                    {item.color ? ` • ${item.color}` : ''}
                  </Text>
                </Pressable>
              )}
            />
          )}
        </View>
      )}

      {selectedVehicle && (
        <View style={styles.selectedCard}>
          <View style={styles.selectedBadge}>
            <Text style={styles.selectedBadgeText}>Seleccionado</Text>
          </View>
          <Text style={styles.selectedPlaca}>{selectedVehicle.placa}</Text>
          <Text style={styles.selectedInfo}>
            {selectedVehicle.marca} {selectedVehicle.modelo}
            {selectedVehicle.color ? ` • ${selectedVehicle.color}` : ''}
          </Text>
          {selectedVehicle.vin && (
            <Text style={styles.selectedVin}>VIN: {selectedVehicle.vin}</Text>
          )}
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { marginBottom: Spacing.md },
  label: {
    fontSize: TypeScale.label,
    fontWeight: '600',
    color: Semantic.onSurface,
    marginBottom: Spacing.sm,
  },
  inputRow: { flexDirection: 'row', alignItems: 'center' },
  input: {
    flex: 1,
    borderWidth: 1,
    borderColor: Semantic.border,
    borderRadius: Radius.md,
    paddingHorizontal: Spacing.md,
    paddingVertical: 14,
    fontSize: TypeScale.body,
    backgroundColor: Semantic.surfaceElevated,
    color: Semantic.onSurface,
  },
  clearBtn: {
    marginLeft: Spacing.sm,
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: Semantic.surfaceElevated,
    borderWidth: 1,
    borderColor: Semantic.border,
    alignItems: 'center',
    justifyContent: 'center',
  },
  clearText: { fontSize: 16, color: Semantic.secondary },
  dropdown: {
    backgroundColor: Semantic.surface,
    borderWidth: 1,
    borderColor: Semantic.border,
    borderRadius: Radius.md,
    marginTop: Spacing.xs,
    maxHeight: 220,
    overflow: 'hidden',
    ...Shadows.extruded,
  },
  loadingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: Spacing.md,
    gap: Spacing.sm,
  },
  loadingText: { fontSize: TypeScale.label, color: Semantic.secondary },
  noResults: {
    padding: Spacing.md,
    fontSize: TypeScale.body,
    color: Semantic.secondary,
    textAlign: 'center',
  },
  list: { maxHeight: 200 },
  resultItem: {
    paddingHorizontal: Spacing.md,
    paddingVertical: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: Semantic.border,
  },
  resultItemPressed: { backgroundColor: Semantic.surfacePress },
  resultPlaca: {
    fontSize: TypeScale.body,
    fontWeight: '700',
    color: Semantic.primary,
  },
  resultDetail: {
    fontSize: TypeScale.label,
    color: Semantic.secondary,
    marginTop: 2,
  },
  selectedCard: {
    backgroundColor: Semantic.primaryMuted,
    borderRadius: Radius.md,
    padding: Spacing.md,
    marginTop: Spacing.sm,
    borderLeftWidth: 4,
    borderLeftColor: Semantic.primary,
  },
  selectedBadge: {
    alignSelf: 'flex-start',
    backgroundColor: Semantic.primary,
    paddingHorizontal: Spacing.sm,
    paddingVertical: 2,
    borderRadius: Radius.pill,
    marginBottom: Spacing.xs,
  },
  selectedBadgeText: {
    color: Semantic.onPrimary,
    fontSize: TypeScale.caption,
    fontWeight: '700',
  },
  selectedPlaca: {
    fontSize: TypeScale.subtitle,
    fontWeight: '700',
    color: Semantic.onSurface,
  },
  selectedInfo: {
    fontSize: TypeScale.label,
    color: Semantic.secondary,
    marginTop: 2,
  },
  selectedVin: {
    fontSize: TypeScale.caption,
    color: Semantic.secondary,
    marginTop: 4,
    fontFamily: 'monospace',
  },
});
