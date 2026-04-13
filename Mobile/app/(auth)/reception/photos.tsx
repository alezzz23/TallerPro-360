import { useState } from 'react';
import { Alert, Platform, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import * as ImagePicker from 'expo-image-picker';

import { ThemedView } from '@/components/themed-view';
import { StepIndicator } from '@/components/reception/step-indicator';
import { PhotoCaptureCard } from '@/components/reception/photo-capture-card';
import { Semantic, Shadows, Radius, Spacing, StatusColors, TypeScale } from '@/constants/theme';
import {
  usePerimeterPhotos,
  useUploadPerimeterPhoto,
  useUploadMedia,
} from '@/hooks/use-reception';
import type { AnguloFoto } from '@/types/api';

const ANGLES: AnguloFoto[] = ['FRONTAL', 'TRASERO', 'IZQUIERDO', 'DERECHO'];
const STEP_LABELS = ['Vehículo', 'Checklist', 'Daños', 'Fotos', 'Firma'];

export default function PhotosScreen() {
  const { orderId } = useLocalSearchParams<{ orderId: string }>();
  const router = useRouter();
  const { data: photos = [] } = usePerimeterPhotos(orderId ?? '');
  const uploadPhoto = useUploadPerimeterPhoto();
  const uploadMedia = useUploadMedia();
  const [localUris, setLocalUris] = useState<Record<AnguloFoto, string | null>>({
    FRONTAL: null,
    TRASERO: null,
    IZQUIERDO: null,
    DERECHO: null,
  });
  const [uploadingAngle, setUploadingAngle] = useState<AnguloFoto | null>(null);

  const getPhotoUri = (angulo: AnguloFoto) => {
    const remote = photos.find((p) => p.angulo === angulo);
    return localUris[angulo] || remote?.foto_url || null;
  };

  const capturedCount = ANGLES.filter((a) => getPhotoUri(a)).length;

  const handleCapture = async (angulo: AnguloFoto) => {
    if (!orderId) return;

    const { status } = await ImagePicker.requestCameraPermissionsAsync();
    if (status !== 'granted') {
      Alert.alert('Permiso requerido', 'Se necesita acceso a la cámara para tomar fotos.');
      return;
    }

    const result = await ImagePicker.launchCameraAsync({
      mediaTypes: ['images'],
      quality: 0.7,
      allowsEditing: false,
    });

    if (result.canceled || !result.assets[0]) return;

    const uri = result.assets[0].uri;
    setLocalUris((prev) => ({ ...prev, [angulo]: uri }));
    setUploadingAngle(angulo);

    try {
      const media = await uploadMedia.mutateAsync({ uri, category: 'reception' });
      await uploadPhoto.mutateAsync({
        orderId,
        angulo,
        fotoUrl: media.relative_url,
      });
    } catch (e: any) {
      Alert.alert('Error', e?.response?.data?.detail ?? 'No se pudo subir la foto');
      setLocalUris((prev) => ({ ...prev, [angulo]: null }));
    } finally {
      setUploadingAngle(null);
    }
  };

  const handleContinue = () => {
    if (capturedCount < 4) {
      Alert.alert(
        'Fotos incompletas',
        `Faltan ${4 - capturedCount} foto(s). Debe capturar las 4 fotos perimetrales.`,
      );
      return;
    }
    router.push({
      pathname: '/(auth)/reception/signature',
      params: { orderId },
    });
  };

  return (
    <ThemedView style={styles.container}>
      <ScrollView
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
      >
        <StepIndicator current={4} total={5} labels={STEP_LABELS} />

        <Text style={styles.title}>Fotos perimetrales</Text>
        <Text style={styles.hint}>
          Capture una foto de cada ángulo del vehículo ({capturedCount}/4)
        </Text>

        <View style={styles.grid}>
          {ANGLES.map((angulo) => (
            <PhotoCaptureCard
              key={angulo}
              angulo={angulo}
              photoUri={getPhotoUri(angulo)}
              onCapture={() => handleCapture(angulo)}
              isUploading={uploadingAngle === angulo}
            />
          ))}
        </View>

        <Pressable
          style={({ pressed }) => [
            styles.continueBtn,
            capturedCount < 4 && styles.continueBtnDisabled,
            pressed && styles.continueBtnPressed,
          ]}
          onPress={handleContinue}
        >
          <Text style={styles.continueText}>Continuar →</Text>
        </Pressable>
      </ScrollView>
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  content: {
    padding: Spacing.lg,
    paddingBottom: Spacing.xxl,
  },
  title: {
    fontSize: TypeScale.subtitle,
    fontWeight: '700',
    color: Semantic.onSurface,
  },
  hint: {
    fontSize: TypeScale.label,
    color: Semantic.secondary,
    marginTop: Spacing.xs,
    marginBottom: Spacing.lg,
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
  },
  continueBtn: {
    backgroundColor: Semantic.primary,
    paddingVertical: 16,
    borderRadius: Radius.pill,
    alignItems: 'center',
    marginTop: Spacing.lg,
    ...Shadows.extruded,
  },
  continueBtnPressed: { ...Shadows.none, backgroundColor: '#111111', transform: [{ scale: 0.97 }] },
  continueBtnDisabled: { opacity: 0.5 },
  continueText: {
    color: Semantic.onPrimary,
    fontSize: TypeScale.body,
    fontWeight: '700',
  },
});
