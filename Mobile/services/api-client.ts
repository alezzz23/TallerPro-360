import axios from 'axios';
import * as SecureStore from 'expo-secure-store';
import { Platform } from 'react-native';

import { API_BASE_URL, API_PREFIX } from '@/constants/api';

const TOKEN_KEY = 'auth_token';

export const apiClient = axios.create({
  baseURL: `${API_BASE_URL}${API_PREFIX}`,
  timeout: 15_000,
  headers: { 'Content-Type': 'application/json' },
});

// ── Request: attach JWT ────────────────────────────────────
apiClient.interceptors.request.use(async (config) => {
  const token =
    Platform.OS === 'web'
      ? localStorage.getItem(TOKEN_KEY)
      : await SecureStore.getItemAsync(TOKEN_KEY);

  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// ── Response: handle 401 ───────────────────────────────────
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      if (Platform.OS === 'web') {
        localStorage.removeItem(TOKEN_KEY);
      } else {
        await SecureStore.deleteItemAsync(TOKEN_KEY);
      }
      // Auth store will detect missing token on next check
    }
    return Promise.reject(error);
  },
);

// ── Typed helpers ──────────────────────────────────────────
export async function apiGet<T>(url: string) {
  const { data } = await apiClient.get<T>(url);
  return data;
}

export async function apiPost<T>(url: string, body?: unknown) {
  const { data } = await apiClient.post<T>(url, body);
  return data;
}

export async function apiPut<T>(url: string, body?: unknown) {
  const { data } = await apiClient.put<T>(url, body);
  return data;
}

export async function apiDelete<T>(url: string) {
  const { data } = await apiClient.delete<T>(url);
  return data;
}
