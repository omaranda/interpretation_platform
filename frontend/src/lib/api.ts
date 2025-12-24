import axios from 'axios';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add auth token to requests
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Handle auth errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export const authAPI = {
  login: async (email: string, password: string) => {
    const response = await api.post('/auth/login', { email, password });
    return response.data;
  },
  logout: async () => {
    const response = await api.post('/auth/logout');
    return response.data;
  },
  getCurrentUser: async () => {
    const response = await api.get('/auth/me');
    return response.data;
  },
};

export const callAPI = {
  getActiveCalls: async () => {
    const response = await api.get('/calls/active');
    return response.data;
  },
  startCall: async (roomName: string, customerInfo?: any) => {
    const response = await api.post('/calls/start', { roomName, customerInfo });
    return response.data;
  },
  endCall: async (callId: string) => {
    const response = await api.post('/calls/end', { callId });
    return response.data;
  },
  getCallHistory: async (limit = 50) => {
    const response = await api.get(`/calls/history?limit=${limit}`);
    return response.data;
  },
};

export const queueAPI = {
  getQueue: async () => {
    const response = await api.get('/queue');
    return response.data;
  },
  getMetrics: async () => {
    const response = await api.get('/queue/metrics');
    return response.data;
  },
};
