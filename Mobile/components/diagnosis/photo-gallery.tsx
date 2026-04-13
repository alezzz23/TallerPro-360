import { useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Dimensions,
  Image,
  Pressable,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import * as ImagePicker from 'expo-image-picker';

import { uploadMedia } from '@/services/reception';
import { Radius, Semantic, Shadows, Spacing, TypeScale } from '@/constants/theme';

const COLUMN_COUNT = 3;
const GAP = Spacing.sm;
const screenWidth = Dimensions.get('window').width;
const THUMB_SIZE = (screenWidth - Spacing.md * 2 - GAP * (COLUMN_COUNT - 1)) / COLUMN_COUNT;

interface Props {
  photos: string[];
  onPhotoAdded: (url: string) => void;
  maxPhotos?: number;
}

export function PhotoGallery({ photos, onPhotoAdded, maxPhotos = 10 }: Props) {
  const [uploading, setUploading] = useState(false);

  const pickAndUpload = async () => {
    if (photos.length >= maxPhotos) {
      Alert.alert('Límite alcanzado', `Máximo ${maxPhotos} fotos por hallazgo`);
      return;
    }

    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      quality: 0.8,
      allowsMultipleSelection: false,
    });

    if (result.canceled || !result.assets[0]) return;

    setUploading(true);
    try {
      const media = await uploadMedia(result.assets[0].uri, 'diagnosis');
      onPhotoAdded(media.url);
    } catch {
      Alert.alert('Error', 'No se pudo subir la foto');
    } finally {
      setUploading(false);
    }
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Fotos del Hallazgo</Text>
        <Text style={styles.counter}>
          {photos.length}/{maxPhotos}
        </Text>
      </View>

      <View style={styles.grid}>
        {photos.map((uri, i) => (
          <Image
            key={`${uri}-${i}`}
            source={{ uri }}
            style={styles.thumb}
          />
        ))}

        {photos.length < maxPhotos && (
          <Pressable
            style={({ pressed }) => [
              styles.thumb,
              styles.addBtn,
              pressed && { opacity: 0.8, transform: [{ scale: 0.97 }] },
            ]}
            onPress={pickAndUpload}
            disabled={uploading}
          >
            {uploading ? (
              <ActivityIndicator color={Semantic.primary} />
            ) : (
              <>
                <Text style={styles.addIcon}>+</Text>
                <Text style={styles.addLabel}>Agregar</Text>
              </>
            )}
          </Pressable>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginTop: Spacing.md,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Spacing.sm,
  },
  title: {
    fontSize: TypeScale.label,
    fontWeight: '700',
    color: Semantic.onSurface,
  },
  counter: {
    fontSize: TypeScale.label,
    color: Semantic.textMuted,
    fontWeight: '600',
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: GAP,
  },
  thumb: {
    width: THUMB_SIZE,
    height: THUMB_SIZE,
    borderRadius: Radius.md,
    backgroundColor: Semantic.surface,
  },
  addBtn: {
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: Semantic.primary,
    borderStyle: 'dashed',
    backgroundColor: Semantic.surfaceElevated,
  },
  addIcon: {
    fontSize: 28,
    color: Semantic.primary,
    fontWeight: '700',
    lineHeight: 30,
  },
  addLabel: {
    fontSize: TypeScale.caption,
    color: Semantic.primary,
    fontWeight: '600',
    marginTop: 2,
  },
});
