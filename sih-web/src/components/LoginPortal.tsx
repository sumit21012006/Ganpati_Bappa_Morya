'use client';

import React, { useState } from 'react';
import { useApp } from '@/context/AppContext';
import { UserRole } from '@/types';
import { Scale, ShieldAlert, UserCheck, ArrowRight, UserPlus, Lock, CheckCircle2, AlertCircle } from 'lucide-react';

export default function LoginPortal() {
  const { loginUser, registerUser } = useApp();
  
  // Auth Form mode: 'LOGIN' | 'REGISTER'
  const [authMode, setAuthMode] = useState<'LOGIN' | 'REGISTER'>('LOGIN');
  const [targetRole, setTargetRole] = useState<UserRole>('CITIZEN');

  // Input states
  const [identifier, setIdentifier] = useState<string>('');
  const [password, setPassword] = useState<string>('');
  const [rememberMe, setRememberMe] = useState<boolean>(true);

  // Registration fields
  const [name, setName] = useState<string>('');
  const [email, setEmail] = useState<string>('');
  const [mobile, setMobile] = useState<string>('');
  const [badgeId, setBadgeId] = useState<string>('');
  const [upiVpa, setUpiVpa] = useState<string>('');

  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const handleLoginSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);
    try {
      loginUser(identifier, password, targetRole, rememberMe);
    } catch (err: any) {
      setErrorMessage(err.message || 'Authentication failed.');
    }
  };

  const handleRegisterSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);
    try {
      registerUser(
        {
          name,
          email,
          mobile: targetRole === 'CITIZEN' ? mobile : undefined,
          badgeId: targetRole === 'CONTROLLER' ? badgeId : undefined,
          password,
          role: targetRole,
          upiVpa,
        },
        rememberMe
      );
    } catch (err: any) {
      setErrorMessage(err.message || 'Registration failed.');
    }
  };

  return (
    <div className="min-h-screen bg-[#EEF2F6] text-slate-900 flex flex-col justify-between font-sans relative overflow-hidden">
      {/* Top Header Banner */}
      <header className="p-5 flex items-center justify-between border-b border-slate-200 bg-white shadow-sm">
        <div className="flex items-center space-x-3">
          <div className="w-10 h-10 rounded-lg bg-gradient-to-tr from-amber-500 to-amber-600 text-slate-950 flex items-center justify-center font-bold shadow-md">
            <Scale className="w-6 h-6 stroke-[2.5]" />
          </div>
          <div>
            <h1 className="text-base font-bold text-slate-900">
              Legal Metrology (Packaged Commodities) Enforcement & Redressal Portal
            </h1>
            <p className="text-xs text-slate-500">Government of India • Ministry of Consumer Affairs, Food & Public Distribution</p>
          </div>
        </div>

        <span className="text-xs bg-slate-100 px-3 py-1 rounded-full text-slate-700 border border-slate-300 font-semibold">
          NIC & Keycloak Authenticated
        </span>
      </header>

      {/* Main Authentication Card */}
      <main className="max-w-4xl mx-auto px-4 py-12 flex-1 flex flex-col items-center justify-center space-y-6 z-10 w-full">
        <div className="text-center space-y-1">
          <span className="bg-amber-100 text-amber-800 text-[10px] font-bold px-3 py-1 rounded-full border border-amber-300 uppercase tracking-wider">
            SECURE PORTAL LOGIN & REGISTRATION
          </span>
          <h2 className="text-2xl md:text-3xl font-black text-slate-900">
            {authMode === 'LOGIN' ? 'Portal Account Sign In' : 'Register New User Account'}
          </h2>
          <p className="text-xs text-slate-600">
            Sign in to access your designated role portal (Citizen Redressal or Controller Enforcement Command)
          </p>
        </div>

        <div className="w-full max-w-xl bg-white border border-slate-200 p-6 rounded-2xl shadow-xl space-y-5">
          {/* Mode Toggle (Login vs Register) */}
          <div className="flex border-b border-slate-200 pb-3 justify-center space-x-6 text-xs font-bold">
            <button
              onClick={() => {
                setAuthMode('LOGIN');
                setErrorMessage(null);
              }}
              className={`pb-1 border-b-2 transition-all flex items-center gap-1.5 ${
                authMode === 'LOGIN'
                  ? 'border-amber-500 text-amber-700 font-bold'
                  : 'border-transparent text-slate-500 hover:text-slate-800'
              }`}
            >
              <Lock className="w-3.5 h-3.5" /> Sign In
            </button>

            <button
              onClick={() => {
                setAuthMode('REGISTER');
                setErrorMessage(null);
              }}
              className={`pb-1 border-b-2 transition-all flex items-center gap-1.5 ${
                authMode === 'REGISTER'
                  ? 'border-amber-500 text-amber-700 font-bold'
                  : 'border-transparent text-slate-500 hover:text-slate-800'
              }`}
            >
              <UserPlus className="w-3.5 h-3.5" /> Register New Account
            </button>
          </div>

          {/* Role Choice (Citizen vs Controller) */}
          <div className="grid grid-cols-2 gap-3">
            <button
              type="button"
              onClick={() => {
                setTargetRole('CITIZEN');
                setIdentifier('');
              }}
              className={`p-3 rounded-xl border text-xs font-bold flex flex-col items-center justify-center space-y-1 transition-all ${
                targetRole === 'CITIZEN'
                  ? 'bg-amber-50 border-amber-500 text-amber-800 shadow-sm ring-1 ring-amber-500/40'
                  : 'bg-slate-50 border-slate-200 text-slate-600 hover:bg-slate-100'
              }`}
            >
              <UserCheck className="w-5 h-5 text-amber-600" />
              <span>Citizen Portal Sign In</span>
            </button>

            <button
              type="button"
              onClick={() => {
                setTargetRole('CONTROLLER');
                setIdentifier('');
              }}
              className={`p-3 rounded-xl border text-xs font-bold flex flex-col items-center justify-center space-y-1 transition-all ${
                targetRole === 'CONTROLLER'
                  ? 'bg-slate-900 border-slate-900 text-white shadow-sm'
                  : 'bg-slate-50 border-slate-200 text-slate-600 hover:bg-slate-100'
              }`}
            >
              <ShieldAlert className="w-5 h-5 text-rose-500" />
              <span>Controller Command Login</span>
            </button>
          </div>

          {/* Error Alert */}
          {errorMessage && (
            <div className="bg-rose-50 border border-rose-200 text-rose-800 text-xs p-3 rounded-lg flex items-center space-x-2">
              <AlertCircle className="w-4 h-4 shrink-0 text-rose-600" />
              <span>{errorMessage}</span>
            </div>
          )}

          {/* LOGIN FORM */}
          {authMode === 'LOGIN' && (
            <form onSubmit={handleLoginSubmit} className="space-y-4 text-xs">
              <div>
                <label className="text-slate-700 font-bold block mb-1">
                  {targetRole === 'CITIZEN' ? 'Mobile Number / Email' : 'Officer Badge ID / Email'}
                </label>
                <input
                  type="text"
                  required
                  value={identifier}
                  onChange={(e) => setIdentifier(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-300 rounded-lg p-2.5 text-xs text-slate-900 font-mono focus:outline-none focus:border-amber-500 focus:bg-white"
                />
              </div>

              <div>
                <label className="text-slate-700 font-bold block mb-1">Password</label>
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-300 rounded-lg p-2.5 text-xs text-slate-900 font-mono focus:outline-none focus:border-amber-500 focus:bg-white"
                />
              </div>

              <div className="flex items-center space-x-2 pt-1 pb-1">
                <input
                  type="checkbox"
                  id="rememberMeLogin"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                  className="w-4 h-4 rounded border-slate-300 text-amber-600 focus:ring-amber-500 cursor-pointer accent-amber-600"
                />
                <label htmlFor="rememberMeLogin" className="text-xs text-slate-700 font-semibold cursor-pointer select-none">
                  Save login information on this device
                </label>
              </div>

              <button
                type="submit"
                className={`w-full font-black py-3 rounded-xl shadow-md flex items-center justify-center space-x-2 text-xs transition-all ${
                  targetRole === 'CITIZEN'
                    ? 'bg-amber-500 hover:bg-amber-400 text-slate-950 shadow-amber-500/20'
                    : 'bg-[#0D1F3C] hover:bg-[#081427] text-white shadow-blue-900/20'
                }`}
              >
                <span>Log In to {targetRole === 'CITIZEN' ? 'Citizen Portal' : 'Controller Command'}</span>
                <ArrowRight className="w-4 h-4" />
              </button>
            </form>
          )}

          {/* REGISTER FORM */}
          {authMode === 'REGISTER' && (
            <form onSubmit={handleRegisterSubmit} className="space-y-3 text-xs">
              <div>
                <label className="text-slate-700 font-bold block mb-1">Full Legal Name</label>
                <input
                  type="text"
                  required
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-300 rounded-lg p-2 text-xs text-slate-900"
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                <div>
                  <label className="text-slate-700 font-bold block mb-1">Email Address</label>
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full bg-slate-50 border border-slate-300 rounded-lg p-2 text-xs text-slate-900"
                  />
                </div>

                {targetRole === 'CITIZEN' ? (
                  <div>
                    <label className="text-slate-700 font-bold block mb-1">Mobile Number</label>
                    <input
                      type="text"
                      required
                      value={mobile}
                      onChange={(e) => setMobile(e.target.value)}
                      className="w-full bg-slate-50 border border-slate-300 rounded-lg p-2 text-xs text-slate-900 font-mono"
                    />
                  </div>
                ) : (
                  <div>
                    <label className="text-slate-700 font-bold block mb-1">Officer Badge ID</label>
                    <input
                      type="text"
                      required
                      value={badgeId}
                      onChange={(e) => setBadgeId(e.target.value)}
                      className="w-full bg-slate-50 border border-slate-300 rounded-lg p-2 text-xs text-slate-900 font-mono"
                    />
                  </div>
                )}
              </div>

              {targetRole === 'CITIZEN' && (
                <div>
                  <label className="text-slate-700 font-bold block mb-1">UPI VPA for Reward Point Credit (Optional)</label>
                  <input
                    type="text"
                    value={upiVpa}
                    onChange={(e) => setUpiVpa(e.target.value)}
                    className="w-full bg-slate-50 border border-slate-300 rounded-lg p-2 text-xs text-slate-900 font-mono"
                  />
                </div>
              )}

              <div>
                <label className="text-slate-700 font-bold block mb-1">Password</label>
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-300 rounded-lg p-2 text-xs text-slate-900 font-mono"
                />
              </div>

              <div className="flex items-center space-x-2 pt-1 pb-1">
                <input
                  type="checkbox"
                  id="rememberMeRegister"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                  className="w-4 h-4 rounded border-slate-300 text-emerald-600 focus:ring-emerald-500 cursor-pointer accent-emerald-600"
                />
                <label htmlFor="rememberMeRegister" className="text-xs text-slate-700 font-semibold cursor-pointer select-none">
                  Save login information on this device
                </label>
              </div>

              <button
                type="submit"
                className="w-full bg-emerald-600 hover:bg-emerald-500 text-white font-black py-3 rounded-xl shadow-md flex items-center justify-center space-x-2 text-xs transition-all mt-2"
              >
                <span>Register Account & Log In</span>
                <ArrowRight className="w-4 h-4" />
              </button>
            </form>
          )}
        </div>
      </main>

      <footer className="p-4 text-center text-xs text-slate-500 border-t border-slate-200 bg-white">
        Legal Metrology Act 2011 Compliance System • Ministry of Consumer Affairs, Food & Public Distribution
      </footer>
    </div>
  );
}
