import { create } from 'zustand';

import * as authService from '@/services/auth';
import { clearCache } from '@/services/offline-db';
import type { User } from '@/types/api';

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  restoreSession: () => Promise<void>;
  setUser: (user: User) => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  token: null,
  isAuthenticated: false,
  isLoading: true,

  login: async (email, password) => {
    const user = await authService.login(email, password);
    const token = await authService.getStoredToken();
    set({ user, token, isAuthenticated: true });
  },

  logout: async () => {
    await authService.logout();
    clearCache();
    set({ user: null, token: null, isAuthenticated: false });
  },

  restoreSession: async () => {
    try {
      const token = await authService.getStoredToken();
      if (!token) {
        set({ isLoading: false });
        return;
      }
      const user = await authService.getMe();
      set({ user, token, isAuthenticated: true, isLoading: false });
    } catch {
      await authService.logout();
      set({ user: null, token: null, isAuthenticated: false, isLoading: false });
    }
  },

  setUser: (user) => set({ user }),
}));
