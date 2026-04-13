import { StyleSheet } from 'react-native';

import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { Spacing } from '@/constants/theme';

export default function CustomersScreen() {
  return (
    <ThemedView style={styles.container}>
      <ThemedText type="title">Clientes</ThemedText>
      <ThemedView style={styles.placeholder}>
        <ThemedText>Directorio de clientes próximamente</ThemedText>
      </ThemedView>
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: Spacing.lg,
    paddingTop: 60,
  },
  placeholder: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#CFD8DC',
    borderStyle: 'dashed',
    marginTop: Spacing.lg,
  },
});
