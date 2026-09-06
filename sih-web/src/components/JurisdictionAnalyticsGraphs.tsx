'use client';

import React, { useState } from 'react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  Legend,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  AreaChart,
  Area,
  CartesianGrid,
  Line
} from 'recharts';
import {
  BarChart3,
  CreditCard,
  PieChart as PieIcon,
  Activity,
  ChevronDown,
  ChevronUp,
  ShieldAlert,
  TrendingUp,
  Award,
  CheckCircle2
} from 'lucide-react';

export default function JurisdictionAnalyticsGraphs() {
  // Toggle states for viewing summary breakdown under each graph
  const [showCasesSummary, setShowCasesSummary] = useState<boolean>(false);
  const [showPaymentsSummary, setShowPaymentsSummary] = useState<boolean>(false);
  const [showCategorySummary, setShowCategorySummary] = useState<boolean>(false);
  const [showSpeedSummary, setShowSpeedSummary] = useState<boolean>(false);

  // Data 1: District Cases Bar Chart Data
  const districtCasesData = [
    { district: 'Mumbai', Compounded: 1420, Escalated_CJM: 420, Total: 1840 },
    { district: 'Pune', Compounded: 1100, Escalated_CJM: 320, Total: 1420 },
    { district: 'Thane', Compounded: 890, Escalated_CJM: 220, Total: 1110 },
    { district: 'Nashik', Compounded: 750, Escalated_CJM: 170, Total: 920 },
    { district: 'Nagpur', Compounded: 640, Escalated_CJM: 140, Total: 780 },
    { district: 'Sambhajinagar', Compounded: 580, Escalated_CJM: 110, Total: 690 },
  ];

  // Data 2: Region Payments Recovery Data (Lakhs)
  const regionPaymentsData = [
    { region: 'Western Region (Mumbai/Thane)', recoveryLakhs: 210, sharePct: 54.7, color: '#10b981' },
    { region: 'Pune Metro & Pimpri', recoveryLakhs: 160, sharePct: 30.4, color: '#3b82f6' },
    { region: 'Vidarbha Hub (Nagpur)', recoveryLakhs: 82, sharePct: 10.2, color: '#f59e0b' },
    { region: 'Nashik & Sambhajinagar', recoveryLakhs: 54.5, sharePct: 4.7, color: '#6366f1' },
  ];

  // Data 3: Product Category Donut Data
  const categoryData = [
    { name: 'Edible Oils & Ghee', value: 38, cases: '1,433 Cases', color: '#f43f5e' },
    { name: 'Cereals & Pulses (Rice/Wheat)', value: 26, cases: '955 Cases', color: '#f59e0b' },
    { name: 'E-Commerce Electronics', value: 18, cases: '614 Cases', color: '#3b82f6' },
    { name: 'Fuel Dispensers', value: 12, cases: '410 Cases', color: '#10b981' },
    { name: 'Packaged Dairy', value: 6, cases: '215 Cases', color: '#a855f7' },
  ];

  // Data 4: Adjudication SLA Speed Trend Data
  const speedTrendData = [
    { month: 'May', AvgDaysToCompound: 9.4, SlaLimit: 14, PanchanamaRatePct: 91.2 },
    { month: 'Jun', AvgDaysToCompound: 8.8, SlaLimit: 14, PanchanamaRatePct: 93.0 },
    { month: 'Jul', AvgDaysToCompound: 7.9, SlaLimit: 14, PanchanamaRatePct: 94.5 },
    { month: 'Aug', AvgDaysToCompound: 7.1, SlaLimit: 14, PanchanamaRatePct: 95.8 },
    { month: 'Sep', AvgDaysToCompound: 6.2, SlaLimit: 14, PanchanamaRatePct: 96.8 },
  ];

  return (
    <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 font-sans">
      
      {/* ========================================================================= */}
      {/* 1. CASES RELATED BAR CHART (DISTRICT ADJUDICATION STATUS) - Left 7 cols   */}
      {/* ========================================================================= */}
      <div className="lg:col-span-7 bg-white border border-slate-200 rounded-xl p-5 space-y-4 shadow-sm flex flex-col justify-between">
        <div className="space-y-3">
          <div className="flex items-center justify-between border-b border-slate-100 pb-3">
            <div>
              <h3 className="text-sm font-black text-slate-900 flex items-center gap-2">
                <BarChart3 className="w-4 h-4 text-blue-700" />
                <span>Cases Related Bar Chart (District Adjudication Status)</span>
              </h3>
              <p className="text-[11px] text-slate-500">Compounded Settlement vs Escalated CJM Prosecution Cases</p>
            </div>
            <span className="text-[10px] bg-blue-50 text-blue-800 font-bold px-2.5 py-1 rounded border border-blue-200">
              Interactive Bar Chart
            </span>
          </div>

          {/* Recharts Visual Bar Chart */}
          <div className="h-64 w-full pt-2">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={districtCasesData} margin={{ top: 10, right: 10, left: -15, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                <XAxis dataKey="district" tick={{ fontSize: 11, fill: '#475569', fontWeight: 600 }} />
                <YAxis tick={{ fontSize: 10, fill: '#64748b' }} />
                <Tooltip
                  contentStyle={{ backgroundColor: '#0D1F3C', borderRadius: '8px', color: '#fff', fontSize: '11px', border: 'none' }}
                  itemStyle={{ color: '#fff' }}
                />
                <Legend wrapperStyle={{ fontSize: '11px', paddingTop: '8px' }} />
                <Bar dataKey="Compounded" fill="#10b981" name="Compounded (Settled)" radius={[4, 4, 0, 0]} />
                <Bar dataKey="Escalated_CJM" fill="#f43f5e" name="Escalated (CJM Court)" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Option to View Detailed Data Summary */}
        <div className="pt-2 border-t border-slate-100">
          <button
            onClick={() => setShowCasesSummary(!showCasesSummary)}
            className="w-full bg-slate-50 hover:bg-slate-100 border border-slate-200 text-slate-700 text-xs font-bold py-2 px-3 rounded-lg flex items-center justify-between transition-all cursor-pointer"
          >
            <span className="flex items-center gap-1.5">
              <BarChart3 className="w-3.5 h-3.5 text-blue-600" />
              <span>{showCasesSummary ? 'Hide District Summary Breakdown' : 'View District Data Summary Breakdown'}</span>
            </span>
            {showCasesSummary ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
          </button>

          {/* Expandable Detailed Summary Breakdown */}
          {showCasesSummary && (
            <div className="mt-3 space-y-2.5 animate-in fade-in duration-200">
              {[
                { district: 'Mumbai Suburban', filed: 1840, compounded: 1420, escalated: 420, rate: '77.1%' },
                { district: 'Pune District', filed: 1420, compounded: 1100, escalated: 320, rate: '77.4%' },
                { district: 'Thane Circle', filed: 1110, compounded: 890, escalated: 220, rate: '80.1%' },
                { district: 'Nashik Region', filed: 920, compounded: 750, escalated: 170, rate: '81.5%' },
                { district: 'Nagpur East & West', filed: 780, compounded: 640, escalated: 140, rate: '82.0%' },
                { district: 'Chhatrapati Sambhajinagar', filed: 690, compounded: 580, escalated: 110, rate: '84.0%' },
              ].map((row, i) => (
                <div key={i} className="space-y-1.5 bg-slate-50 p-2.5 rounded-lg border border-slate-200 text-xs">
                  <div className="flex justify-between items-center font-bold">
                    <span className="text-slate-900">{row.district}</span>
                    <span className="font-mono text-slate-600">Total Cases: <strong className="text-slate-900">{row.filed}</strong></span>
                  </div>
                  <div className="grid grid-cols-3 gap-2 text-[10px] pt-1 font-mono">
                    <div className="bg-emerald-50 text-emerald-800 p-1 rounded border border-emerald-200">
                      <strong>Compounded:</strong> {row.compounded}
                    </div>
                    <div className="bg-rose-50 text-rose-800 p-1 rounded border border-rose-200">
                      <strong>Escalated CJM:</strong> {row.escalated}
                    </div>
                    <div className="bg-blue-50 text-blue-800 p-1 rounded border border-blue-200">
                      <strong>Resolution Rate:</strong> {row.rate}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 2. REGION-WISE PAYMENTS & FINE RECOVERY CHART - Right 5 cols              */}
      {/* ========================================================================= */}
      <div className="lg:col-span-5 bg-white border border-slate-200 rounded-xl p-5 space-y-4 shadow-sm flex flex-col justify-between">
        <div className="space-y-3">
          <div className="flex items-center justify-between border-b border-slate-100 pb-3">
            <div>
              <h3 className="text-sm font-black text-slate-900 flex items-center gap-2">
                <CreditCard className="w-4 h-4 text-emerald-600" />
                <span>Region-Wise Payments & Fine Recovery</span>
              </h3>
              <p className="text-[11px] text-slate-500">Bharatkosh CFR Portal Direct Settlement (₹ Lakhs)</p>
            </div>
            <span className="text-[10px] bg-emerald-50 text-emerald-800 font-bold px-2.5 py-1 rounded border border-emerald-200">
              Recovery Graph
            </span>
          </div>

          {/* Recharts Visual Horizontal Bar Chart */}
          <div className="h-64 w-full pt-2">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart layout="vertical" data={regionPaymentsData} margin={{ top: 10, right: 20, left: 10, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                <XAxis type="number" tick={{ fontSize: 10, fill: '#64748b' }} unit=" L" />
                <YAxis dataKey="region" type="category" tick={{ fontSize: 9, fill: '#334155', fontWeight: 700 }} width={120} />
                <Tooltip
                  contentStyle={{ backgroundColor: '#0D1F3C', borderRadius: '8px', color: '#fff', fontSize: '11px', border: 'none' }}
                  formatter={(val: any) => [`₹${val} Lakhs`, 'Fine Recovery']}
                />
                <Bar dataKey="recoveryLakhs" fill="#10b981" radius={[0, 4, 4, 0]} name="Recovery (₹ Lakhs)">
                  {regionPaymentsData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Option to View Detailed Payment Summary */}
        <div className="pt-2 border-t border-slate-100">
          <button
            onClick={() => setShowPaymentsSummary(!showPaymentsSummary)}
            className="w-full bg-slate-50 hover:bg-slate-100 border border-slate-200 text-slate-700 text-xs font-bold py-2 px-3 rounded-lg flex items-center justify-between transition-all cursor-pointer"
          >
            <span className="flex items-center gap-1.5">
              <CreditCard className="w-3.5 h-3.5 text-emerald-600" />
              <span>{showPaymentsSummary ? 'Hide Payment Breakdown' : 'View Region Payment Summary Breakdown'}</span>
            </span>
            {showPaymentsSummary ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
          </button>

          {/* Expandable Detailed Summary Breakdown */}
          {showPaymentsSummary && (
            <div className="mt-3 space-y-2 animate-in fade-in duration-200">
              {[
                { region: 'Western Region (Mumbai / Thane)', amount: '₹2.10 Crore', share: '54.7%', badge: 'bg-emerald-100 text-emerald-800' },
                { region: 'Pune Metro & Pimpri-Chinchwad', amount: '₹1.60 Crore', share: '30.4%', badge: 'bg-blue-100 text-blue-800' },
                { region: 'Vidarbha Hub (Nagpur)', amount: '₹82.0 Lakhs', share: '10.2%', badge: 'bg-amber-100 text-amber-800' },
                { region: 'Nashik & Sambhajinagar Belt', amount: '₹54.5 Lakhs', share: '4.7%', badge: 'bg-indigo-100 text-indigo-800' },
              ].map((reg, idx) => (
                <div key={idx} className="p-2.5 rounded-lg bg-slate-50 border border-slate-200 space-y-1 text-xs">
                  <div className="flex items-center justify-between font-bold">
                    <span className="text-slate-900">{reg.region}</span>
                    <span className="font-mono text-emerald-700">{reg.amount}</span>
                  </div>
                  <div className="flex items-center justify-between text-[10px]">
                    <span className="text-slate-500 font-mono">Bharatkosh Direct CFR Credit</span>
                    <span className={`font-black px-2 py-0.5 rounded font-mono ${reg.badge}`}>{reg.share} Share</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 3. PRODUCT CATEGORY WISE COMMODITY SEIZURES - Left 6 cols                 */}
      {/* ========================================================================= */}
      <div className="lg:col-span-6 bg-white border border-slate-200 rounded-xl p-5 space-y-4 shadow-sm flex flex-col justify-between">
        <div className="space-y-3">
          <div className="flex items-center justify-between border-b border-slate-100 pb-3">
            <div>
              <h3 className="text-sm font-black text-slate-900 flex items-center gap-2">
                <PieIcon className="w-4 h-4 text-amber-600" />
                <span>Product Category Wise Commodity Seizures</span>
              </h3>
              <p className="text-[11px] text-slate-500">Legal Metrology Rules 6 & 18 Non-Compliance Slices</p>
            </div>
            <span className="text-[10px] bg-amber-50 text-amber-800 font-bold px-2.5 py-1 rounded border border-amber-200">
              Donut Graph
            </span>
          </div>

          {/* Recharts Visual Donut Chart */}
          <div className="h-64 w-full pt-2 flex items-center justify-center">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={categoryData}
                  cx="50%"
                  cy="50%"
                  innerRadius={55}
                  outerRadius={90}
                  paddingAngle={4}
                  dataKey="value"
                  label={({ name, percent }: any) => `${name} (${(percent * 100).toFixed(0)}%)`}
                  labelLine={false}
                >
                  {categoryData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{ backgroundColor: '#0D1F3C', borderRadius: '8px', color: '#fff', fontSize: '11px', border: 'none' }}
                  formatter={(val: any, name: any, props: any) => [`${val}% (${props.payload.cases})`, name]}
                />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Option to View Detailed Category Summary */}
        <div className="pt-2 border-t border-slate-100">
          <button
            onClick={() => setShowCategorySummary(!showCategorySummary)}
            className="w-full bg-slate-50 hover:bg-slate-100 border border-slate-200 text-slate-700 text-xs font-bold py-2 px-3 rounded-lg flex items-center justify-between transition-all cursor-pointer"
          >
            <span className="flex items-center gap-1.5">
              <PieIcon className="w-3.5 h-3.5 text-amber-600" />
              <span>{showCategorySummary ? 'Hide Category Summary' : 'View Product Category Data Summary'}</span>
            </span>
            {showCategorySummary ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
          </button>

          {/* Expandable Detailed Summary Breakdown */}
          {showCategorySummary && (
            <div className="mt-3 space-y-2 animate-in fade-in duration-200">
              {[
                { label: 'Packaged Edible Oils & Ghee', pct: '38%', count: '1,433 Cases', badge: 'bg-rose-100 text-rose-800' },
                { label: 'Packaged Cereals & Pulses (Rice/Wheat)', pct: '26%', count: '955 Cases', badge: 'bg-amber-100 text-amber-800' },
                { label: 'E-Commerce Electronics & Appliances', pct: '18%', count: '614 Cases', badge: 'bg-blue-100 text-blue-800' },
                { label: 'High-Speed Diesel & Fuel Dispensers', pct: '12%', count: '410 Cases', badge: 'bg-emerald-100 text-emerald-800' },
                { label: 'Packaged Dairy & Milk Products', pct: '6%', count: '215 Cases', badge: 'bg-purple-100 text-purple-800' },
              ].map((cat, idx) => (
                <div key={idx} className="p-2.5 rounded-lg bg-slate-50 border border-slate-200 flex items-center justify-between text-xs">
                  <div>
                    <div className="font-bold text-slate-900">{cat.label}</div>
                    <div className="text-[10px] text-slate-500">{cat.count}</div>
                  </div>
                  <span className={`text-xs font-black px-2 py-0.5 rounded font-mono ${cat.badge}`}>
                    {cat.pct}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 4. CONTROLLER SPEED & RECIDIVISM RADAR - Right 6 cols                      */}
      {/* ========================================================================= */}
      <div className="lg:col-span-6 bg-white border border-slate-200 rounded-xl p-5 space-y-4 shadow-sm flex flex-col justify-between">
        <div className="space-y-3">
          <div className="flex items-center justify-between border-b border-slate-100 pb-3">
            <div>
              <h3 className="text-sm font-black text-slate-900 flex items-center gap-2">
                <Activity className="w-4 h-4 text-blue-700" />
                <span>Controller Speed & Recidivism Radar</span>
              </h3>
              <p className="text-[11px] text-slate-500">Adjudication SLA Velocity (Days) vs 14-Day Limit</p>
            </div>
            <span className="text-[10px] bg-slate-900 text-white font-bold px-2.5 py-1 rounded">
              SLA Area Graph
            </span>
          </div>

          {/* Recharts Visual Area & Line Chart */}
          <div className="h-64 w-full pt-2">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={speedTrendData} margin={{ top: 10, right: 10, left: -15, bottom: 0 }}>
                <defs>
                  <linearGradient id="colorSpeed" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.4}/>
                    <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                <XAxis dataKey="month" tick={{ fontSize: 11, fill: '#475569', fontWeight: 600 }} />
                <YAxis tick={{ fontSize: 10, fill: '#64748b' }} domain={[0, 16]} />
                <Tooltip
                  contentStyle={{ backgroundColor: '#0D1F3C', borderRadius: '8px', color: '#fff', fontSize: '11px', border: 'none' }}
                />
                <Legend wrapperStyle={{ fontSize: '11px', paddingTop: '8px' }} />
                <Area type="monotone" dataKey="AvgDaysToCompound" stroke="#2563eb" fillOpacity={1} fill="url(#colorSpeed)" name="Avg Days to Compound (SLA)" />
                <Line type="monotone" dataKey="SlaLimit" stroke="#ef4444" strokeDasharray="5 5" name="Statutory 14-Day Limit" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Option to View Detailed Speed & Recidivism Summary */}
        <div className="pt-2 border-t border-slate-100">
          <button
            onClick={() => setShowSpeedSummary(!showSpeedSummary)}
            className="w-full bg-slate-50 hover:bg-slate-100 border border-slate-200 text-slate-700 text-xs font-bold py-2 px-3 rounded-lg flex items-center justify-between transition-all cursor-pointer"
          >
            <span className="flex items-center gap-1.5">
              <Activity className="w-3.5 h-3.5 text-blue-600" />
              <span>{showSpeedSummary ? 'Hide Speed & Recidivism Radar Summary' : 'View Adjudication SLA Speed & Risk Summary'}</span>
            </span>
            {showSpeedSummary ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
          </button>

          {/* Expandable Detailed Summary Breakdown */}
          {showSpeedSummary && (
            <div className="mt-3 space-y-3 animate-in fade-in duration-200">
              <div className="grid grid-cols-2 gap-3 text-xs">
                <div className="bg-blue-50 border border-blue-200 p-3 rounded-lg space-y-1">
                  <div className="text-[10px] text-blue-700 font-bold uppercase">AVG ADJUDICATION SPEED</div>
                  <div className="text-xl font-black text-blue-900 font-mono">6.2 Days</div>
                  <div className="text-[9px] text-blue-700">SLA Statutory Limit: 14 Days</div>
                </div>

                <div className="bg-emerald-50 border border-emerald-200 p-3 rounded-lg space-y-1">
                  <div className="text-[10px] text-emerald-700 font-bold uppercase">48-HR PANCHANAMA RATE</div>
                  <div className="text-xl font-black text-emerald-900 font-mono">96.8%</div>
                  <div className="text-[9px] text-emerald-700">Digitally Verified on Handhelds</div>
                </div>
              </div>

              <div className="bg-rose-50 border border-rose-200 p-3 rounded-lg space-y-1 text-xs">
                <div className="flex items-center justify-between">
                  <span className="font-bold text-rose-800 flex items-center gap-1">
                    <ShieldAlert className="w-3.5 h-3.5" /> Section 36(2) Repeat Offender Risk Queue
                  </span>
                  <span className="bg-rose-700 text-white text-[9px] font-bold px-1.5 py-0.5 rounded">High Priority</span>
                </div>
                <p className="text-[11px] text-rose-900 leading-tight">
                  4 Multi-Offence Corporate Entities flagged for mandatory CJM Prosecution escalation. No compounding granted for second offences under Rule 48(2).
                </p>
              </div>
            </div>
          )}
        </div>
      </div>

    </div>
  );
}
