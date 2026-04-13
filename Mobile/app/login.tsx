import React, { useState } from 'react';
import {
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { useRouter } from 'expo-router';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';

import { useAuthStore } from '@/stores/auth-store';
import { Semantic, Spacing, TypeScale, Shadows, Radius } from '@/constants/theme';
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
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <View style={styles.card}>
        <Text style={styles.title}>TallerPro 360</Text>
        <Text style={styles.subtitle}>Iniciar sesión</Text>

        <Text style={styles.label}>Correo electrónico</Text>
        <Controller
          control={control}
          name="email"
          render={({ field: { onChange, onBlur, value } }) => (
            <TextInput
              style={[styles.input, errors.email && styles.inputError]}
              placeholder="correo@ejemplo.com"
              placeholderTextColor={Semantic.textMuted}
              autoCapitalize="none"
              keyboardType="email-address"
              textContentType="emailAddress"
              autoComplete="email"
              value={value}
              onChangeText={onChange}
              onBlur={onBlur}
            />
          )}
        />
        {errors.email && <Text style={styles.fieldError}>{errors.email.message}</Text>}

        <Text style={styles.label}>Contraseña</Text>
        <Controller
          control={control}
          name="password"
          render={({ field: { onChange, onBlur, value } }) => (
            <TextInput
              style={[styles.input, errors.password && styles.inputError]}
              placeholder="••••••••"
              placeholderTextColor={Semantic.textMuted}
              secureTextEntry
              textContentType="password"
              autoComplete="password"
              value={value}
              onChangeText={onChange}
              onBlur={onBlur}
            />
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
            <Text style={styles.buttonText}>Entrar</Text>
          )}
        </Pressable>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: Semantic.background,
    padding: Spacing.lg,
  },
  card: {
    width: '100%',
    maxWidth: 400,
    backgroundColor: Semantic.surface,
    borderRadius: Radius.lg,
    padding: Spacing.lg,
    ...Shadows.extruded,
    borderTopWidth: 1,
    borderLeftWidth: 1,
    borderTopColor: Semantic.borderLight,
    borderLeftColor: Semantic.borderLight,
  },
  title: {
    fontSize: TypeScale.headline,
    fontWeight: '700',
    color: Semantic.primary,
    textAlign: 'center',
    marginBottom: Spacing.xs,
  },
  subtitle: {
    fontSize: TypeScale.subtitle,
    color: Semantic.secondary,
    textAlign: 'center',
    marginBottom: Spacing.lg,
  },
  label: {
    fontSize: TypeScale.label,
    fontWeight: '500',
    color: Semantic.onSurface,
    marginBottom: Spacing.xs,
  },
  input: {
    height: 48,
    borderWidth: 1,
    borderColor: Semantic.border,
    borderRadius: Radius.md,
    paddingHorizontal: Spacing.md,
    fontSize: TypeScale.body,
    marginBottom: Spacing.md,
    color: Semantic.onSurface,
    backgroundColor: Semantic.surfaceElevated,
  },
  error: {
    color: Semantic.danger,
    fontSize: TypeScale.label,
    marginBottom: Spacing.md,
  },
  fieldError: {
    color: Semantic.danger,
    fontSize: TypeScale.caption,
    marginTop: -Spacing.sm,
    marginBottom: Spacing.sm,
  },
  inputError: {
    borderColor: Semantic.danger,
  },
  button: {
    height: 48,
    backgroundColor: Semantic.primary,
    borderRadius: Radius.pill,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: Spacing.sm,
    ...Shadows.extruded,
  },
  buttonPressed: {
    ...Shadows.none,
    backgroundColor: Semantic.primaryDark,
    transform: [{ scale: 0.97 }],
  },
  buttonDisabled: {
    opacity: 0.6,
  },
  buttonText: {
    color: Semantic.onPrimary,
    fontSize: TypeScale.body,
    fontWeight: '700',
  },
});
