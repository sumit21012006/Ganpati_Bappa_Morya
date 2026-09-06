'use client';

import React from 'react';
import { useApp } from '@/context/AppContext';
import { 
  LayoutDashboard, 
  ShieldAlert, 
  FileCheck, 
  GitMerge, 
  MapPin, 
  Package, 
  Gavel, 
  CheckCircle2
} from 'lucide-react';

export default function Sidebar() {
  const { controllerTab, setControllerTab } = useApp();

  const menuSections = [
    {
      title: 'ADJUDICATION DESK',
      items: [
        { label: 'Command Dashboard', tabKey: 'COMMAND_DASHBOARD', icon: LayoutDashboard },
        { label: 'Case Queue & Compounding', tabKey: 'COMPOUNDING_QUEUE', icon: ShieldAlert },
        { label: 'Panchanama & Seizures', tabKey: 'PANCHANAMA', icon: FileCheck },
      ],
    },
    {
      title: 'SURVEILLANCE & REGISTRY',
      items: [
        { label: 'Supply Chain Traceback', tabKey: 'SUPPLY_CHAIN', icon: GitMerge },
        { label: 'Jurisdiction Analytics', tabKey: 'JURISDICTION', icon: MapPin },
      ],
    },
  ];

  return (
    <aside className="w-64 bg-[#0D1F3C] border-r border-[#18345E] text-slate-200 flex flex-col justify-between hidden md:flex min-h-screen shrink-0 font-sans shadow-lg">
      <div className="p-4 space-y-6">
        {/* Live HQ Badge */}
        <div className="bg-[#081427] border border-blue-400/30 rounded-lg p-3 flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-ping"></span>
            <span className="text-xs font-bold text-white">Enforcement HQ (Delhi)</span>
          </div>
          <span className="text-[10px] font-mono text-emerald-300 bg-emerald-950/60 px-2 py-0.5 rounded border border-emerald-500/50">
            Live 24×7
          </span>
        </div>

        {/* Menu Items */}
        {menuSections.map((section, idx) => (
          <div key={idx} className="space-y-2">
            <h3 className="text-[10px] font-bold text-blue-200/80 uppercase tracking-widest px-2">
              {section.title}
            </h3>
            <div className="space-y-1">
              {section.items.map((item, itemIdx) => {
                const Icon = item.icon;
                const isActive = controllerTab === item.tabKey;
                return (
                  <button
                    key={itemIdx}
                    onClick={() => {
                      setControllerTab(item.tabKey as any);
                    }}
                    className={`w-full flex items-center space-x-2.5 px-3 py-2 rounded-lg text-xs font-semibold transition-all ${
                      isActive
                        ? 'bg-[#18345E] text-amber-300 border-l-4 border-amber-400 font-bold shadow-md'
                        : 'text-blue-100/90 hover:text-white hover:bg-[#18345E]/60'
                    }`}
                  >
                    <Icon className="w-4 h-4" />
                    <span>{item.label}</span>
                  </button>
                );
              })}
            </div>
          </div>
        ))}
      </div>

      {/* Controller Official Profile Footer */}
      <div className="p-4 border-t border-blue-400/30 bg-[#081427]">
        <div className="flex items-center space-x-3">
          <div className="w-9 h-9 rounded-full bg-[#0D1F3C] ring-2 ring-amber-400/60 flex items-center justify-center font-bold text-amber-300 text-xs shadow">
            RK
          </div>
          <div className="flex-1 min-w-0">
            <h4 className="text-xs font-bold text-white truncate">Shri R.K. Singh</h4>
            <p className="text-[10px] text-blue-200 truncate">Controller General (LM)</p>
          </div>
        </div>
        <div className="mt-3 flex items-center justify-between text-[10px] text-blue-200/90 pt-2 border-t border-blue-400/20">
          <span className="flex items-center gap-1 text-emerald-300 font-semibold">
            <CheckCircle2 className="w-3 h-3" /> DSC Certificate: Valid
          </span>
        </div>
      </div>
    </aside>
  );
}
