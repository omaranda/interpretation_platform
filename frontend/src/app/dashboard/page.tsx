'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/authStore';
import { useCallStore } from '@/store/callStore';
import { callAPI, queueAPI } from '@/lib/api';
import { wsClient } from '@/lib/websocket';
import JitsiCall from '@/components/JitsiCall';
import Navigation from '@/components/Navigation';
import { Call, CallStatus } from '@/types';

export default function DashboardPage() {
  const router = useRouter();
  const { user, isAuthenticated, checkAuth, logout } = useAuthStore();
  const { activeCalls, currentCall, metrics, setActiveCalls, setCurrentCall, setMetrics, updateCall } = useCallStore();
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const initAuth = async () => {
      await checkAuth();
      if (!isAuthenticated) {
        router.push('/login');
      } else {
        loadData();
      }
    };
    initAuth();
  }, []);

  useEffect(() => {
    if (isAuthenticated) {
      const token = localStorage.getItem('token');
      wsClient.connect(token || undefined);

      wsClient.on('call_update', (data) => {
        updateCall(data.callId, data.updates);
      });

      return () => {
        wsClient.disconnect();
      };
    }
  }, [isAuthenticated, updateCall]);

  const loadData = async () => {
    try {
      const [calls, metricsData] = await Promise.all([
        callAPI.getActiveCalls(),
        queueAPI.getMetrics(),
      ]);
      setActiveCalls(calls);
      setMetrics(metricsData);
    } catch (error) {
      console.error('Failed to load data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleStartCall = async () => {
    try {
      const roomName = `call-${Date.now()}`;
      const call = await callAPI.startCall(roomName, {
        customerName: 'Test Customer',
      });
      setCurrentCall(call);
    } catch (error) {
      console.error('Failed to start call:', error);
    }
  };

  const handleEndCall = async () => {
    if (!currentCall) return;

    try {
      await callAPI.endCall(currentCall.id);
      setCurrentCall(null);
      loadData();
    } catch (error) {
      console.error('Failed to end call:', error);
    }
  };

  const handleLogout = () => {
    logout();
    router.push('/login');
  };

  if (isLoading) {
    return (
      <>
        <Navigation />
        <div className="min-h-screen flex items-center justify-center">
          <div className="text-xl">Loading dashboard...</div>
        </div>
      </>
    );
  }

  return (
    <>
      <Navigation />
      <div className="min-h-screen bg-gray-100">

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 py-6 sm:px-6 lg:px-8">
        {/* Metrics */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <div className="bg-white p-6 rounded-lg shadow">
            <h3 className="text-sm font-medium text-gray-500">Total Calls</h3>
            <p className="text-3xl font-bold text-gray-900">{metrics?.totalCalls || 0}</p>
          </div>
          <div className="bg-white p-6 rounded-lg shadow">
            <h3 className="text-sm font-medium text-gray-500">Active Calls</h3>
            <p className="text-3xl font-bold text-green-600">{metrics?.activeCalls || 0}</p>
          </div>
          <div className="bg-white p-6 rounded-lg shadow">
            <h3 className="text-sm font-medium text-gray-500">Waiting</h3>
            <p className="text-3xl font-bold text-yellow-600">{metrics?.waitingCalls || 0}</p>
          </div>
          <div className="bg-white p-6 rounded-lg shadow">
            <h3 className="text-sm font-medium text-gray-500">Avg Duration</h3>
            <p className="text-3xl font-bold text-blue-600">
              {Math.round((metrics?.averageCallDuration || 0) / 60)}m
            </p>
          </div>
        </div>

        {/* Call Interface */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Call Window */}
          <div className="lg:col-span-2 bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold mb-4">
              {currentCall ? 'Active Call' : 'No Active Call'}
            </h2>

            {currentCall ? (
              <div className="space-y-4">
                <div className="h-96 bg-gray-900 rounded-lg overflow-hidden">
                  <JitsiCall
                    roomName={currentCall.roomName}
                    displayName={user?.name || 'Agent'}
                    onCallEnd={handleEndCall}
                  />
                </div>
                <button
                  onClick={handleEndCall}
                  className="w-full bg-red-600 text-white py-3 px-4 rounded-lg hover:bg-red-700"
                >
                  End Call
                </button>
              </div>
            ) : (
              <div className="text-center py-20">
                <p className="text-gray-500 mb-4">No active call</p>
                <button
                  onClick={handleStartCall}
                  className="bg-blue-600 text-white py-2 px-6 rounded-lg hover:bg-blue-700"
                >
                  Start Test Call
                </button>
              </div>
            )}
          </div>

          {/* Active Calls List */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold mb-4">Active Calls ({activeCalls.length})</h2>
            <div className="space-y-3">
              {activeCalls.length === 0 ? (
                <p className="text-gray-500 text-sm">No active calls</p>
              ) : (
                activeCalls.map((call) => (
                  <div
                    key={call.id}
                    className="border border-gray-200 rounded-lg p-3 hover:bg-gray-50"
                  >
                    <div className="flex justify-between items-start">
                      <div>
                        <p className="font-medium text-sm">
                          {call.customerName || 'Unknown Customer'}
                        </p>
                        <p className="text-xs text-gray-500">{call.roomName}</p>
                      </div>
                      <span
                        className={`text-xs px-2 py-1 rounded ${
                          call.status === CallStatus.ACTIVE
                            ? 'bg-green-100 text-green-800'
                            : call.status === CallStatus.WAITING
                            ? 'bg-yellow-100 text-yellow-800'
                            : 'bg-blue-100 text-blue-800'
                        }`}
                      >
                        {call.status}
                      </span>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      </main>
      </div>
    </>
  );
}
