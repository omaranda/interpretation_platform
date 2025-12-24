export enum UserRole {
  TRANSLATOR = 'TRANSLATOR',
  EMPLOYEE = 'EMPLOYEE',
  COMPANY_ADMIN = 'COMPANY_ADMIN',
  ADMIN = 'ADMIN'
}

export interface User {
  id: string;
  email: string;
  name: string;
  role: UserRole;
  languages?: string[];
  is_available?: boolean;
  hourly_rate?: string;
  company_id?: string;
}

export interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
}

export enum CallStatus {
  WAITING = 'waiting',
  RINGING = 'ringing',
  ACTIVE = 'active',
  ENDED = 'ended',
  MISSED = 'missed'
}

export interface Call {
  id: string;
  roomName: string;
  customerName?: string;
  customerPhone?: string;
  agentId?: string;
  status: CallStatus;
  startTime?: Date;
  endTime?: Date;
  duration?: number;
}

export interface QueueItem {
  id: string;
  callId: string;
  position: number;
  waitTime: number;
  priority: number;
}

export interface CallMetrics {
  totalCalls: number;
  activeCalls: number;
  waitingCalls: number;
  averageWaitTime: number;
  averageCallDuration: number;
}
