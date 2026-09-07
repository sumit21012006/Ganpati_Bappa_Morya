'use client';

import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { UserRole, AuthUser } from '@/types';
import { authDb } from '@/lib/db';
import { loginToBackend, registerToBackend, getAuthMe } from '@/lib/api/auth';
import { clearAuthToken } from '@/lib/apiClient';


export type CitizenTab = 'FILE_COMPLAINT' | 'MY_COMPLAINTS';
export type ControllerTab = 'COMMAND_DASHBOARD' | 'COMPOUNDING_QUEUE' | 'SUPPLY_CHAIN' | 'JURISDICTION' | 'PANCHANAMA';

export interface AppNotification {
  id: string;
  title: string;
  message: string;
  timestamp: string;
  type: 'PANCHANAMA' | 'RAID' | 'SEIZURE' | 'WHISTLEBLOWER';
  unread: boolean;
  inspectorName?: string;
  badgeId?: string;
}

interface AppContextType {
  user: AuthUser | null;
  role: UserRole;
  setRole: (role: UserRole) => void;
  toggleRole: () => void;
  isLoggedIn: boolean;
  loginUser: (identifier: string, pass: string, role: UserRole, rememberMe?: boolean) => Promise<void>;
  registerUser: (
    data: {
      name: string;
      email: string;
      mobile?: string;
      badgeId?: string;
      password: string;
      role: UserRole;
      upiVpa?: string;
    },
    rememberMe?: boolean
  ) => Promise<void>;
  logout: () => void;
  citizenTab: CitizenTab;
  setCitizenTab: (tab: CitizenTab) => void;
  controllerTab: ControllerTab;
  setControllerTab: (tab: ControllerTab) => void;
  searchQuery: string;
  setSearchQuery: (query: string) => void;
  notificationCount: number;
  setNotificationCount: React.Dispatch<React.SetStateAction<number>>;
  notifications: AppNotification[];
  markNotificationAsRead: (id: string) => void;
  markAllNotificationsAsRead: () => void;
  addNotification: (notif: Omit<AppNotification, 'id' | 'timestamp' | 'unread'>) => void;
  activeAlert: string | null;
  setActiveAlert: (alert: string | null) => void;
  rewardPointsBalance: number;
  setRewardPointsBalance: React.Dispatch<React.SetStateAction<number>>;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export function AppProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [role, setRole] = useState<UserRole>('CITIZEN');
  const [isLoggedIn, setIsLoggedIn] = useState<boolean>(false);
  const [citizenTab, setCitizenTab] = useState<CitizenTab>('MY_COMPLAINTS');
  const [controllerTab, setControllerTab] = useState<ControllerTab>('COMMAND_DASHBOARD');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [activeAlert, setActiveAlert] = useState<string | null>(
    'Alert: Repeat violation detected for FastFoods Brand in Pune Baramati Sector — Automated Section 36(2)...'
  );
  const [rewardPointsBalance, setRewardPointsBalance] = useState<number>(2750);
  const [isAuthChecking, setIsAuthChecking] = useState<boolean>(true);


  const [notifications, setNotifications] = useState<AppNotification[]>([
    {
      id: 'notif_01',
      title: 'Inspector Field Stream Activated',
      message: 'Insp. S. Kadam (#MH-LM-412) initiated live video stream for Panchnama #MH-412 at Modern Supermarket.',
      timestamp: '3 mins ago',
      type: 'PANCHANAMA',
      unread: true,
      inspectorName: 'Insp. S. Kadam',
      badgeId: 'MH-LM-412',
    },
    {
      id: 'notif_02',
      title: 'Surprise Raid Squad Acknowledged',
      message: 'Raid mandate #TD-THN-0021 accepted by Insp. V. Patil for Bhoomi Agro Mills (Raigad Circle).',
      timestamp: '14 mins ago',
      type: 'RAID',
      unread: true,
      inspectorName: 'Insp. V. Patil',
      badgeId: 'MH-LM-809',
    },
    {
      id: 'notif_03',
      title: 'Seizure Memo Form V Signed',
      message: 'Insp. A. Deshmukh signed Seizure Memo for 48 underweight units at Mahalaxmi Provision Stores.',
      timestamp: '1 hour ago',
      type: 'SEIZURE',
      unread: true,
      inspectorName: 'Insp. A. Deshmukh',
      badgeId: 'MH-LM-102',
    },
    {
      id: 'notif_04',
      title: 'Citizen Whistleblower Payout Approved',
      message: '5,000 Reward Points credited to citizen Arjun Suresh Sharma for Case #LM-2024-MH-0842.',
      timestamp: '2 hours ago',
      type: 'WHISTLEBLOWER',
      unread: false,
    },
  ]);

  const [notificationCount, setNotificationCount] = useState<number>(3);

  // Revalidate session with backend GET /api/v1/auth/me on initial app load
  useEffect(() => {
    async function revalidateSession() {
      if (typeof window === 'undefined') {
        setIsAuthChecking(false);
        return;
      }

      const token = localStorage.getItem('sih_auth_token');
      if (!token) {
        setIsLoggedIn(false);
        setUser(null);
        setIsAuthChecking(false);
        return;
      }

      try {
        // Verify real active session against backend
        const verifiedUser = await getAuthMe();
        setUser(verifiedUser);
        setRole(verifiedUser.role);
        setIsLoggedIn(true);
        if (verifiedUser.rewardPoints) setRewardPointsBalance(verifiedUser.rewardPoints);
        localStorage.setItem('sih_saved_user_session', JSON.stringify(verifiedUser));
      } catch (err) {
        console.warn('[auth] Session revalidation failed against /api/v1/auth/me, resetting session:', err);
        clearAuthToken();
        localStorage.removeItem('sih_saved_user_session');
        setUser(null);
        setIsLoggedIn(false);
      } finally {
        setIsAuthChecking(false);
      }
    }

    revalidateSession();
  }, []);


  useEffect(() => {
    if (user) {
      setRole(user.role);
      if (user.rewardPoints) setRewardPointsBalance(user.rewardPoints);
    }
  }, [user]);

  useEffect(() => {
    const unread = notifications.filter((n) => n.unread).length;
    setNotificationCount(unread);
  }, [notifications]);

  const loginUser = async (identifier: string, pass: string, targetRole: UserRole, rememberMe: boolean = true): Promise<void> => {
    let loggedInUser: AuthUser;
    try {
      // Try NestJS backend first
      loggedInUser = await loginToBackend(identifier, pass, targetRole);
      console.info('[auth] Logged in via NestJS backend');
    } catch (backendErr) {
      console.warn('[auth] Backend login failed, falling back to local authDb:', backendErr);
      // Fall back to local users.json / localStorage
      loggedInUser = authDb.login(identifier, pass, targetRole);
    }
    setUser(loggedInUser);
    setRole(loggedInUser.role);
    setIsLoggedIn(true);
    if (loggedInUser.rewardPoints) setRewardPointsBalance(loggedInUser.rewardPoints);

    if (typeof window !== 'undefined') {
      if (rememberMe) {
        localStorage.setItem('sih_saved_user_session', JSON.stringify(loggedInUser));
      } else {
        localStorage.removeItem('sih_saved_user_session');
      }
    }
  };

  const registerUser = async (
    data: {
      name: string;
      email: string;
      mobile?: string;
      badgeId?: string;
      password: string;
      role: UserRole;
      upiVpa?: string;
    },
    rememberMe: boolean = true
  ): Promise<void> => {
    let createdUser: AuthUser;
    try {
      // Try NestJS backend first
      createdUser = await registerToBackend(data);
      // Also register locally so next local-fallback login works
      try { authDb.register(data); } catch { /* already exists locally */ }
      console.info('[auth] Registered via NestJS backend');
    } catch (backendErr) {
      console.warn('[auth] Backend register failed, falling back to local authDb:', backendErr);
      createdUser = authDb.register(data);
    }
    setUser(createdUser);
    setRole(createdUser.role);
    setIsLoggedIn(true);
    if (createdUser.rewardPoints) setRewardPointsBalance(createdUser.rewardPoints);

    if (typeof window !== 'undefined') {
      if (rememberMe) {
        localStorage.setItem('sih_saved_user_session', JSON.stringify(createdUser));
      } else {
        localStorage.removeItem('sih_saved_user_session');
      }
    }
  };

  const logout = () => {
    setUser(null);
    setIsLoggedIn(false);
    clearAuthToken();
    if (typeof window !== 'undefined') {
      localStorage.removeItem('sih_saved_user_session');
    }
  };

  const toggleRole = () => {
    setRole((prev) => (prev === 'CONTROLLER' ? 'CITIZEN' : 'CONTROLLER'));
  };

  const markNotificationAsRead = (id: string) => {
    setNotifications((prev) =>
      prev.map((n) => (n.id === id ? { ...n, unread: false } : n))
    );
  };

  const markAllNotificationsAsRead = () => {
    setNotifications((prev) => prev.map((n) => ({ ...n, unread: false })));
  };

  const addNotification = (notif: Omit<AppNotification, 'id' | 'timestamp' | 'unread'>) => {
    const newNotif: AppNotification = {
      ...notif,
      id: `notif_${Date.now()}`,
      timestamp: 'Just now',
      unread: true,
    };
    setNotifications((prev) => [newNotif, ...prev]);
  };

  if (isAuthChecking) {
    return (
      <div className="min-h-screen bg-[#EEF2F6] flex flex-col items-center justify-center font-sans">
        <div className="flex items-center space-x-3 text-slate-800 animate-pulse">
          <div className="w-8 h-8 rounded-lg bg-amber-500 flex items-center justify-center font-black text-slate-950 text-sm">LM</div>
          <span className="text-sm font-bold tracking-wide text-slate-700">Validating Sovereign Metrology Session...</span>
        </div>
      </div>
    );
  }

  return (
    <AppContext.Provider
      value={{
        user,
        role,
        setRole,
        toggleRole,
        isLoggedIn,
        loginUser,
        registerUser,
        logout,
        citizenTab,
        setCitizenTab,
        controllerTab,
        setControllerTab,
        searchQuery,
        setSearchQuery,
        notificationCount,
        setNotificationCount,
        notifications,
        markNotificationAsRead,
        markAllNotificationsAsRead,
        addNotification,
        activeAlert,
        setActiveAlert,
        rewardPointsBalance,
        setRewardPointsBalance,
      }}
    >
      {children}
    </AppContext.Provider>
  );
}

export function useApp() {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp must be used within an AppProvider');
  }
  return context;
}
