import * as SecureStore from 'expo-secure-store';
import { Platform } from 'react-native';

import { apiClient } from '@/services/api-client';
import type { AuthTokens, User } from '@/types/api';

const TOKEN_KEY = 'auth_token';

async function storeToken(token: string) {
  if (Platform.OS === 'web') {
    localStorage.setItem(TOKEN_KEY, token);
  } else {
    await SecureStore.setItemAsync(TOKEN_KEY, token);
  }
}

async function clearToken() {
  if (Platform.OS === 'web') {
    localStorage.removeItem(TOKEN_KEY);
  } else {
    await SecureStore.deleteItemAsync(TOKEN_KEY);
  }
}

export async function getStoredToken(): Promise<string | null> {
  if (Platform.OS === 'web') {
    return localStorage.getItem(TOKEN_KEY);
  }
  return SecureStore.getItemAsync(TOKEN_KEY);
}

export async function login(email: string, password: string): Promise<User> {
  const { data: tokens } = await apiClient.post<AuthTokens>('/auth/login', {
    email,
    password,
  });
  await storeToken(tokens.access_token);
  const { data: user } = await apiClient.get<User>('/auth/me');
  return user;
}

export async function logout(): Promise<void> {
  await clearToken();
}

export async function getMe(): Promise<User> {
  const { data } = await apiClient.get<User>('/auth/me');
  return data;
}
