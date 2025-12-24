import { create } from 'zustand';
import { Call, QueueItem, CallMetrics } from '@/types';

interface CallStore {
  activeCalls: Call[];
  queue: QueueItem[];
  metrics: CallMetrics | null;
  currentCall: Call | null;

  setActiveCalls: (calls: Call[]) => void;
  setQueue: (queue: QueueItem[]) => void;
  setMetrics: (metrics: CallMetrics) => void;
  setCurrentCall: (call: Call | null) => void;

  addCall: (call: Call) => void;
  updateCall: (callId: string, updates: Partial<Call>) => void;
  removeCall: (callId: string) => void;
}

export const useCallStore = create<CallStore>((set) => ({
  activeCalls: [],
  queue: [],
  metrics: null,
  currentCall: null,

  setActiveCalls: (calls) => set({ activeCalls: calls }),
  setQueue: (queue) => set({ queue }),
  setMetrics: (metrics) => set({ metrics }),
  setCurrentCall: (call) => set({ currentCall: call }),

  addCall: (call) => set((state) => ({
    activeCalls: [...state.activeCalls, call],
  })),

  updateCall: (callId, updates) => set((state) => ({
    activeCalls: state.activeCalls.map((call) =>
      call.id === callId ? { ...call, ...updates } : call
    ),
    currentCall: state.currentCall?.id === callId
      ? { ...state.currentCall, ...updates }
      : state.currentCall,
  })),

  removeCall: (callId) => set((state) => ({
    activeCalls: state.activeCalls.filter((call) => call.id !== callId),
    currentCall: state.currentCall?.id === callId ? null : state.currentCall,
  })),
}));
