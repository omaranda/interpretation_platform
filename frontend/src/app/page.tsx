'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/authStore';
import { UserRole } from '@/types';

export default function Home() {
  const router = useRouter();
  const { isAuthenticated, user, checkAuth } = useAuthStore();

  useEffect(() => {
    const initAuth = async () => {
      await checkAuth();
      if (isAuthenticated && user) {
        // Route based on user role
        if (user.role === UserRole.TRANSLATOR || user.role === UserRole.EMPLOYEE || user.role === UserRole.COMPANY_ADMIN) {
          router.push('/calendar');
        } else {
          router.push('/dashboard');
        }
      } else {
        router.push('/login');
      }
    };
    initAuth();
  }, []);

  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="text-xl">Loading...</div>
    </div>
  );
}
