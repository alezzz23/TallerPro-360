import Constants from 'expo-constants';

const devApiUrl = 'http://localhost:8000';

export const API_BASE_URL =
  Constants.expoConfig?.extra?.apiBaseUrl ?? devApiUrl;

export const API_PREFIX = '/api/v1';
