import React, { useState } from 'react';
import {
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Ionicons } from '@expo/vector-icons';
import { Image } from 'expo-image';

import { useAuthStore } from '@/stores/auth-store';
import { EditorialImages } from '@/constants/visuals';
import { Fonts, Semantic, Spacing, TypeScale, Shadows, Radius } from '@/constants/theme';
import { loginSchema, type LoginFormData } from '@/schemas/auth';

export default function LoginScreen() {
  const router = useRouter();
  const login = useAuthStore((s) => s.login);

  const [serverError, setServerError] = useState('');
  const [loading, setLoading] = useState(false);

  const { control, handleSubmit, formState: { errors } } = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: '', password: '' },
  });

  const onSubmit = async (data: LoginFormData) => {
    setServerError('');
    setLoading(true);
    try {
      await login(data.email.trim(), data.password);
      router.replace('/(auth)/(tabs)');
    } catch (e: any) {
      setServerError(e?.response?.data?.detail ?? 'Error al iniciar sesión');
    } finally {
      setLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <View pointerEvents="none" style={styles.ambientTop} />
      <View pointerEvents="none" style={styles.ambientBottom} />
      <KeyboardAvoidingView
        style={styles.container}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          <View style={styles.heroCard}>
            <Image
              source={EditorialImages.login}
              style={styles.heroImage}
              contentFit="cover"
              transition={250}
            />
            <View style={styles.heroOverlay} />
            <View style={styles.heroCopy}>
              <View style={styles.heroBadge}>
                <Text style={styles.heroBadgeText}>Sistema Operativo del Taller</Text>
              </View>
              <Text style={styles.title}>TallerPro 360</Text>
              <Text style={styles.subtitle}>
                Recepción, diagnóstico y entrega con una interfaz más sobria, precisa y premium.
              </Text>
            </View>
            <View style={styles.heroTagsRow}>
              <View style={styles.heroTag}>
                <Text style={styles.heroTagText}>Recepción</Text>
              </View>
              <View style={styles.heroTag}>
                <Text style={styles.heroTagText}>Diagnóstico</Text>
              </View>
              <View style={styles.heroTag}>
                <Text style={styles.heroTagText}>Entrega</Text>
              </View>
            </View>
          </View>

          <View style={styles.card}>
            <Text style={styles.eyebrow}>Acceso</Text>
            <Text style={styles.cardTitle}>Inicia sesión</Text>
            <Text style={styles.cardSubtitle}>
              Mantén el flujo del taller claro, rápido y ordenado desde el primer toque.
            </Text>

            <Text style={styles.label}>Correo electrónico</Text>
            <Controller
              control={control}
              name="email"
              render={({ field: { onChange, onBlur, value } }) => (
                <View style={[styles.inputShell, errors.email && styles.inputShellError]}>
                  <View style={styles.inputIconWrap}>
                    <Ionicons name="mail-outline" size={18} color={Semantic.primary} />
                  </View>
                  <TextInput
                    style={styles.input}
                    placeholder="correo@ejemplo.com"
                    placeholderTextColor={Semantic.textMuted}
                    autoCapitalize="none"
                    keyboardType="email-address"
                    textContentType="emailAddress"
                    autoComplete="email"
                    selectionColor={Semantic.primary}
                    value={value}
                    onChangeText={onChange}
                    onBlur={onBlur}
                  />
                </View>
              )}
            />
            {errors.email && <Text style={styles.fieldError}>{errors.email.message}</Text>}

            <Text style={styles.label}>Contraseña</Text>
            <Controller
              control={control}
              name="password"
              render={({ field: { onChange, onBlur, value } }) => (
                <View style={[styles.inputShell, errors.password && styles.inputShellError]}>
                  <View style={styles.inputIconWrap}>
                    <Ionicons name="lock-closed-outline" size={18} color={Semantic.primary} />
                  </View>
                  <TextInput
                    style={styles.input}
                    placeholder="••••••••"
                    placeholderTextColor={Semantic.textMuted}
                    secureTextEntry
                    textContentType="password"
                    autoComplete="password"
                    selectionColor={Semantic.primary}
                    value={value}
                    onChangeText={onChange}
                    onBlur={onBlur}
                  />
                </View>
              )}
            />
            {errors.password && <Text style={styles.fieldError}>{errors.password.message}</Text>}

            {serverError ? <Text style={styles.error}>{serverError}</Text> : null}

            <Pressable
              style={({ pressed }) => [
                styles.button,
                loading && styles.buttonDisabled,
                pressed && !loading && styles.buttonPressed,
              ]}
              onPress={handleSubmit(onSubmit)}
              disabled={loading}
            >
              {loading ? (
                <ActivityIndicator color={Semantic.onPrimary} />
              ) : (
                <View style={styles.buttonContent}>
                  <Text style={styles.buttonText}>Entrar al panel</Text>
                  <Ionicons name="arrow-forward" size={18} color={Semantic.onPrimary} />
                </View>
              )}
            </Pressable>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: Semantic.background,
  },
  container: {
    flex: 1,
    backgroundColor: Semantic.background,
  },
  scrollContent: {
    paddingHorizontal: Spacing.lg,
    paddingTop: Spacing.md,
    paddingBottom: Spacing.xxl,
    gap: Spacing.lg,
  },
  ambientTop: {
    position: 'absolute',
    top: -120,
    right: -60,
    width: 280,
    height: 280,
    borderRadius: 280,
    backgroundColor: 'rgba(196,122,58,0.18)',
  },
  ambientBottom: {
    position: 'absolute',
    bottom: -150,
    left: -80,
    width: 320,
    height: 320,
    borderRadius: 320,
    backgroundColor: 'rgba(86,114,142,0.12)',
  },
  heroCard: {
    minHeight: 280,
    borderRadius: Radius.xl,
    overflow: 'hidden',
    justifyContent: 'space-between',
    padding: Spacing.lg,
    ...Shadows.glow,
  },
  heroImage: {
    ...StyleSheet.absoluteFillObject,
  },
  heroOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(14,19,26,0.5)',
  },
  heroCopy: {
    gap: Spacing.sm,
  },
  heroBadge: {
    alignSelf: 'flex-start',
    paddingHorizontal: Spacing.md,
    paddingVertical: 6,
    borderRadius: Radius.pill,
    backgroundColor: 'rgba(196,122,58,0.22)',
    borderWidth: 1,
    borderColor: 'rgba(224,154,91,0.34)',
  },
  heroBadgeText: {
    color: '#FFF8F0',
    fontSize: TypeScale.caption,
    fontFamily: Fonts.medium,
    letterSpacing: 0.4,
  },
  card: {
    width: '100%',
    backgroundColor: Semantic.surface,
    borderRadius: Radius.xl,
    padding: Spacing.lg,
    borderWidth: 1,
    borderColor: Semantic.borderLight,
    ...Shadows.elevated,
  },
  title: {
    fontSize: TypeScale.headline,
    fontFamily: Fonts.display,
    color: '#FFF8F0',
    maxWidth: 260,
    lineHeight: 46,
  },
  subtitle: {
    fontSize: TypeScale.body,
    color: 'rgba(255,248,240,0.84)',
    fontFamily: Fonts.medium,
    lineHeight: 24,
    maxWidth: 300,
  },
  heroTagsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.sm,
  },
  heroTag: {
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    borderRadius: Radius.pill,
    backgroundColor: 'rgba(14,19,26,0.64)',
    borderWidth: 1,
    borderColor: 'rgba(255,248,240,0.16)',
  },
  heroTagText: {
    color: '#FFF8F0',
    fontSize: TypeScale.label,
    fontFamily: Fonts.medium,
  },
  eyebrow: {
    fontSize: TypeScale.caption,
    fontFamily: Fonts.bold,
    color: Semantic.primary,
    textTransform: 'uppercase',
    letterSpacing: 0.8,
    marginBottom: Spacing.xs,
  },
  cardTitle: {
    fontSize: TypeScale.title,
    color: Semantic.onSurface,
    fontFamily: Fonts.display,
  },
  cardSubtitle: {
    fontSize: TypeScale.body,
    color: Semantic.secondary,
    fontFamily: Fonts.medium,
    lineHeight: 24,
    marginTop: Spacing.xs,
    marginBottom: Spacing.lg,
  },
  label: {
    fontSize: TypeScale.label,
    fontFamily: Fonts.bold,
    color: Semantic.onSurface,
    marginBottom: Spacing.sm,
  },
  inputShell: {
    minHeight: 58,
    borderWidth: 1,
    borderColor: Semantic.border,
    backgroundColor: Semantic.surfaceElevated,
    borderRadius: Radius.lg,
    paddingHorizontal: Spacing.sm,
    paddingVertical: Spacing.xs,
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
    marginBottom: Spacing.sm,
  },
  inputShellError: {
    borderColor: Semantic.danger,
  },
  inputIconWrap: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: Semantic.primaryMuted,
    alignItems: 'center',
    justifyContent: 'center',
  },
  input: {
    flex: 1,
    minHeight: 44,
    paddingRight: Spacing.md,
    fontSize: TypeScale.body,
    color: Semantic.onSurface,
    fontFamily: Fonts.medium,
  },
  button: {
    minHeight: 58,
    backgroundColor: Semantic.primary,
    borderRadius: Radius.pill,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: Spacing.sm,
    ...Shadows.glow,
  },
  buttonPressed: {
    ...Shadows.none,
    backgroundColor: Semantic.primaryDark,
    transform: [{ scale: 0.985 }],
  },
  buttonDisabled: {
    opacity: 0.6,
  },
  buttonContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
  },
  buttonText: {
    color: Semantic.onPrimary,
    fontSize: TypeScale.body,
    fontFamily: Fonts.bold,
  },
  error: {
    color: Semantic.danger,
    fontSize: TypeScale.label,
    fontFamily: Fonts.medium,
    marginBottom: Spacing.sm,
  },
  fieldError: {
    color: Semantic.danger,
    fontSize: TypeScale.caption,
    fontFamily: Fonts.medium,
    marginTop: -Spacing.xs,
    marginBottom: Spacing.md,
  },
});
