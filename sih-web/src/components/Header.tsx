'use client';

import React from 'react';
import { useApp } from '@/context/AppContext';
import { 
  Scale, 
  Search, 
  Bell, 
  User, 
  ShieldAlert, 
  FileText, 
  Award, 
  LayoutDashboard, 
  LogOut,
  Activity,
  GitMerge,
  BookOpen,
  Package,
  MapPin
} from 'lucide-react';

export default function Header() {
  const { 
    user,
    role, 
    isLoggedIn, 
    logout, 
    citizenTab, 
    setCitizenTab, 
    controllerTab, 
    setControllerTab, 
    searchQuery, 
    setSearchQuery, 
    notificationCount, 
    notifications,
    markNotificationAsRead,
    markAllNotificationsAsRead,
    rewardPointsBalance 
  } = useApp();

  const [isNotifOpen, setIsNotifOpen] = React.useState<boolean>(false);
  const [isProfileOpen, setIsProfileOpen] = React.useState<boolean>(false);
  const isController = role === 'CONTROLLER';

  return (
    <header className="w-full bg-white text-slate-900 border-b border-slate-200 sticky top-0 z-50 shadow-sm font-sans">
      {/* Topmost Official Govt Banner (Lapis Blue) */}
      <div className="bg-[#0D1F3C] text-slate-300 text-xs px-4 py-1 flex items-center justify-between border-b border-slate-800">
        <div className="flex items-center space-x-3">
          <span className="font-bold text-slate-200">भारत सरकार | Government of India</span>
          <span className="hidden md:inline text-slate-400">• Ministry of Consumer Affairs, Food & Public Distribution</span>
        </div>
        <div className="flex items-center space-x-4 text-slate-300 text-[11px]">
          <span>National Helpline: <strong className="text-amber-400 font-mono">1915 / 1800-11-4000</strong></span>
          <span className="hidden sm:inline bg-slate-800 px-2 py-0.5 rounded text-[10px] text-slate-300 border border-slate-700">A- A A+</span>
          <span className="hidden sm:inline">English / हिंदी / मराठी</span>
        </div>
      </div>

      {/* Main Header Navigation Bar (White Background) */}
      <div className="px-4 py-2.5 flex flex-wrap items-center justify-between gap-3 bg-white">
        {/* Brand Logo & Title */}
        <div className="flex items-center space-x-3">
          <div className="w-9 h-9 rounded-lg bg-gradient-to-tr from-amber-500 to-amber-600 flex items-center justify-center text-slate-950 font-bold shadow-md shadow-amber-500/20 ring-1 ring-amber-400/50 shrink-0">
            <Scale className="w-5 h-5 stroke-[2.5] text-slate-950" />
          </div>
          <div>
            <div className="flex items-center space-x-2">
              <h1 className="text-base font-bold tracking-tight text-slate-900 flex items-center gap-1.5">
                Legal Metrology (Packaged Commodities) Enforcement & Redressal Portal
              </h1>
              {isController ? (
                <span className="bg-rose-100 text-rose-700 border border-rose-200 text-[9px] uppercase font-bold px-2 py-0.5 rounded-full tracking-wider">
                  ENFORCEMENT COMMAND
                </span>
              ) : (
                <span className="bg-emerald-100 text-emerald-700 border border-emerald-200 text-[9px] uppercase font-bold px-2 py-0.5 rounded-full tracking-wider">
                  CITIZEN PORTAL
                </span>
              )}
            </div>
            <p className="text-[10px] text-slate-500 hidden sm:block">
              Government of India • Ministry of Consumer Affairs, Food & Public Distribution
            </p>
          </div>
        </div>

        {/* Search Bar */}
        <div className="flex-1 max-w-md mx-2 hidden lg:block">
          <div className="relative">
            <Search className="w-3.5 h-3.5 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder={
                isController
                  ? 'Search Barcode, Notice No, DIN, PAN or Panchanama...'
                  : 'Search complaint status, merchant GSTIN or brand...'
              }
              className="w-full bg-slate-50 border border-slate-300 rounded-lg pl-9 pr-4 py-1.5 text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:border-amber-500 focus:bg-white transition-all"
            />
          </div>
        </div>

        {/* Right Section: Notification & User Profile */}
        <div className="flex items-center space-x-3 relative">
          {/* Notification Bell */}
          <div className="relative">
            <button 
              onClick={() => setIsNotifOpen(!isNotifOpen)}
              className={`p-2 rounded-lg transition-all relative cursor-pointer ${
                isNotifOpen ? 'bg-slate-100 text-slate-900 ring-2 ring-amber-500/40' : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
              }`}
              title="Field Inspector App Alerts"
            >
              <Bell className="w-4 h-4" />
              {notificationCount > 0 && (
                <span className="absolute top-0.5 right-0.5 w-4 h-4 bg-rose-500 text-white text-[9px] font-black rounded-full flex items-center justify-center border-2 border-white shadow-sm">
                  {notificationCount}
                </span>
              )}
            </button>

            {/* Notification Popover Dropdown (WORKABLE FOR INSPECTOR APP INTEGRATION) */}
            {isNotifOpen && (
              <div className="absolute right-0 top-full mt-2 w-80 sm:w-96 bg-white border border-slate-200 rounded-2xl shadow-2xl z-50 overflow-hidden font-sans animate-in fade-in zoom-in-95 duration-150">
                <div className="bg-[#0D1F3C] text-white p-3.5 flex items-center justify-between border-b border-slate-800">
                  <div className="flex items-center space-x-2">
                    <Bell className="w-4 h-4 text-amber-400" />
                    <span className="text-xs font-bold">Inspector Field App Live Alerts</span>
                    {notificationCount > 0 && (
                      <span className="bg-rose-600 text-white text-[10px] font-bold px-2 py-0.5 rounded-full">
                        {notificationCount} New
                      </span>
                    )}
                  </div>
                  {notificationCount > 0 && (
                    <button 
                      onClick={markAllNotificationsAsRead}
                      className="text-[10px] text-amber-400 hover:underline font-bold"
                    >
                      Mark all as read
                    </button>
                  )}
                </div>

                <div className="max-h-80 overflow-y-auto divide-y divide-slate-100">
                  {notifications.map((n) => (
                    <div 
                      key={n.id}
                      onClick={() => markNotificationAsRead(n.id)}
                      className={`p-3 text-xs transition-all cursor-pointer space-y-1 ${
                        n.unread ? 'bg-amber-50/60 hover:bg-amber-50' : 'bg-white hover:bg-slate-50'
                      }`}
                    >
                      <div className="flex items-center justify-between">
                        <span className={`font-bold flex items-center gap-1.5 ${
                          n.type === 'PANCHANAMA' ? 'text-blue-700' :
                          n.type === 'RAID' ? 'text-rose-700' :
                          n.type === 'SEIZURE' ? 'text-amber-800' : 'text-emerald-700'
                        }`}>
                          {n.type === 'PANCHANAMA' && <Activity className="w-3.5 h-3.5 text-blue-600" />}
                          {n.type === 'RAID' && <ShieldAlert className="w-3.5 h-3.5 text-rose-600" />}
                          {n.type === 'SEIZURE' && <FileText className="w-3.5 h-3.5 text-amber-600" />}
                          {n.type === 'WHISTLEBLOWER' && <Award className="w-3.5 h-3.5 text-emerald-600" />}
                          <span>{n.title}</span>
                        </span>
                        <div className="flex items-center space-x-1">
                          <span className="text-[10px] text-slate-400">{n.timestamp}</span>
                          {n.unread && <span className="w-2 h-2 rounded-full bg-rose-500"></span>}
                        </div>
                      </div>

                      <p className="text-slate-600 text-[11px] leading-relaxed">{n.message}</p>

                      {n.inspectorName && (
                        <div className="text-[10px] font-mono text-slate-500 font-semibold pt-0.5">
                          Officer: {n.inspectorName} ({n.badgeId})
                        </div>
                      )}
                    </div>
                  ))}
                </div>

                <div className="bg-slate-50 border-t border-slate-200 p-2.5 text-center text-[10px] text-slate-500 font-semibold flex items-center justify-center space-x-1.5">
                  <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                  <span>Connected to Inspectors App API v2.4 (Live WebSocket Sync)</span>
                </div>
              </div>
            )}
          </div>

          {/* Logged in User Profile Card & Interactive Dropdown Menu */}
          <div className="relative pl-2 border-l border-slate-200">
            <button
              onClick={() => setIsProfileOpen(!isProfileOpen)}
              className="flex items-center space-x-2 p-1 rounded-lg hover:bg-slate-100 transition-all cursor-pointer"
            >
              <div className="w-8 h-8 rounded-full bg-amber-500/20 border border-amber-500/40 text-amber-900 font-bold text-xs flex items-center justify-center">
                {user?.name ? (
                  user.name.split(' ').filter(Boolean).length >= 2
                    ? `${user.name.split(' ').filter(Boolean)[0][0]}${user.name.split(' ').filter(Boolean).slice(-1)[0][0]}`.toUpperCase()
                    : user.name.substring(0, 2).toUpperCase()
                ) : isController ? 'RK' : 'CU'}
              </div>
              <div className="hidden xl:block text-left">
                <div className="text-xs font-bold text-slate-900">
                  {user ? user.name : isController ? 'Shri R.K. Singh' : 'Authenticated Citizen'}
                </div>
                <div className="text-[10px] text-slate-500 font-semibold">
                  {isController ? 'Controller General (LM)' : `${rewardPointsBalance} Reward Points`}
                </div>
              </div>
            </button>

            {/* Citizen Profile Dropdown */}
            {isProfileOpen && (
              <div className="absolute right-0 top-full mt-2 w-64 bg-white border border-slate-200 rounded-xl shadow-2xl z-50 p-2 space-y-1 font-sans animate-in fade-in zoom-in-95 duration-150">
                <div className="p-2.5 border-b border-slate-100 bg-slate-50 rounded-lg">
                  <div className="text-xs font-bold text-slate-900">
                    {user ? user.name : isController ? 'Shri R.K. Singh' : 'Authenticated Citizen'}
                  </div>
                  <div className="text-[10px] text-emerald-600 font-semibold mt-0.5">
                    {isController ? 'Controller General (LM)' : `Authenticated Citizen (${rewardPointsBalance} Points)`}
                  </div>
                </div>

                {isLoggedIn && (
                  <div className="pt-1">
                    <button
                      onClick={() => {
                        logout();
                        setIsProfileOpen(false);
                      }}
                      className="w-full text-left px-3 py-2 rounded-lg text-xs font-bold text-rose-600 hover:bg-rose-50 flex items-center gap-2 transition-all cursor-pointer"
                    >
                      <LogOut className="w-4 h-4" />
                      <span>Sign Out / Switch Role</span>
                    </button>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Dynamic Role Navigation Tabs */}
      <nav className="bg-slate-50 border-t border-slate-200 px-4 py-2 flex items-center justify-between overflow-x-auto">
        {!isController ? (
          /* CITIZEN PORTAL TABS ONLY */
          <div className="flex items-center space-x-3">
            <button
              onClick={() => setCitizenTab('FILE_COMPLAINT')}
              className={`px-4 py-2 rounded-lg transition-all flex items-center gap-2 text-sm font-extrabold ${
                citizenTab === 'FILE_COMPLAINT'
                  ? 'bg-amber-500 text-slate-950 shadow-md ring-2 ring-amber-400/50'
                  : 'text-slate-700 hover:text-slate-900 hover:bg-slate-200/70'
              }`}
            >
              <FileText className="w-4 h-4" />
              <span>File Complaint (शिकायत दर्ज करें)</span>
            </button>

            <button
              onClick={() => setCitizenTab('MY_COMPLAINTS')}
              className={`px-4 py-2 rounded-lg transition-all flex items-center gap-2 text-sm font-extrabold ${
                citizenTab === 'MY_COMPLAINTS'
                  ? 'bg-amber-500 text-slate-950 shadow-md ring-2 ring-amber-400/50'
                  : 'text-slate-700 hover:text-slate-900 hover:bg-slate-200/70'
              }`}
            >
              <Award className="w-4 h-4" />
              <span>My Complaints & Rewards</span>
            </button>
          </div>
        ) : (
          /* CONTROLLER PORTAL TABS ONLY */
          <div className="flex items-center space-x-2">
            <button
              onClick={() => setControllerTab('COMMAND_DASHBOARD')}
              className={`px-4 py-2 rounded-lg transition-all flex items-center gap-2 text-xs font-bold ${
                controllerTab === 'COMMAND_DASHBOARD'
                  ? 'bg-[#0D1F3C] text-white shadow-sm'
                  : 'text-slate-600 hover:text-slate-900 hover:bg-slate-200/60'
              }`}
            >
              <LayoutDashboard className="w-4 h-4 text-amber-400" />
              <span>Command Dashboard</span>
            </button>

            <button
              onClick={() => setControllerTab('COMPOUNDING_QUEUE')}
              className={`px-4 py-2 rounded-lg transition-all flex items-center gap-2 text-xs font-bold ${
                controllerTab === 'COMPOUNDING_QUEUE'
                  ? 'bg-[#0D1F3C] text-white shadow-sm'
                  : 'text-slate-600 hover:text-slate-900 hover:bg-slate-200/60'
              }`}
            >
              <ShieldAlert className="w-4 h-4 text-rose-400" />
              <span>Case Queue & Compounding</span>
            </button>

            <button
              onClick={() => setControllerTab('SUPPLY_CHAIN')}
              className={`px-4 py-2 rounded-lg transition-all flex items-center gap-2 text-xs font-bold ${
                controllerTab === 'SUPPLY_CHAIN'
                  ? 'bg-[#0D1F3C] text-white shadow-sm'
                  : 'text-slate-600 hover:text-slate-900 hover:bg-slate-200/60'
              }`}
            >
              <GitMerge className="w-4 h-4 text-amber-400" />
              <span>Supply Chain Traceback</span>
            </button>

            <button
              onClick={() => setControllerTab('JURISDICTION')}
              className={`px-4 py-2 rounded-lg transition-all flex items-center gap-2 text-xs font-bold ${
                controllerTab === 'JURISDICTION'
                  ? 'bg-[#0D1F3C] text-white shadow-sm'
                  : 'text-slate-600 hover:text-slate-900 hover:bg-slate-200/60'
              }`}
            >
              <MapPin className="w-4 h-4 text-emerald-500" />
              <span>Jurisdiction Analytics</span>
            </button>
          </div>
        )}

        {/* SLA Status Clock */}
        <div className="hidden xl:flex items-center space-x-2 text-[11px] text-slate-500 pl-4 border-l border-slate-200">
          <Activity className="w-3.5 h-3.5 text-emerald-600" />
          <span>Legal Metrology Act 2011 Active Rules 2024</span>
          <span className="bg-white text-slate-700 px-2 py-0.5 rounded border border-slate-300 font-mono text-[10px]">
            SLA Clock: 14 Business Days Redressal
          </span>
        </div>
      </nav>
    </header>
  );
}
