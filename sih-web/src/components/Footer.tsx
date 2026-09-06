'use client';

import React from 'react';
import { Scale, Phone, ShieldCheck } from 'lucide-react';

export default function Footer() {
  return (
    <footer className="w-full bg-[#0D1F3C] text-slate-200 text-xs border-t border-blue-900">
      <div className="max-w-7xl mx-auto px-4 py-8 grid grid-cols-1 md:grid-cols-4 gap-6">
        {/* Brand Column */}
        <div className="space-y-3">
          <div className="flex items-center space-x-2">
            <div className="w-7 h-7 rounded bg-amber-500 flex items-center justify-center text-slate-950 font-bold">
              <Scale className="w-4 h-4" />
            </div>
            <span className="text-white font-bold text-xs tracking-tight">
              Legal Metrology (Packaged Commodities) Enforcement & Redressal Portal
            </span>
          </div>
          <p className="text-[11px] leading-relaxed text-blue-100/80">
            Statutory regulatory and enforcement framework automated under the Legal Metrology Act, 2009 & Legal Metrology (Packaged Commodities) Rules, 2011. A sovereign consumer protection initiative by Ministry of Consumer Affairs.
          </p>
          <div className="flex items-center space-x-2 text-[11px] text-emerald-400 pt-1">
            <ShieldCheck className="w-4 h-4" />
            <span>National Informatics Centre (NIC) Certified</span>
          </div>
        </div>

        {/* Column 2: Statutory Acts */}
        <div className="space-y-2">
          <h4 className="text-amber-400 font-bold text-xs uppercase tracking-wider border-b border-blue-800 pb-1">
            Statutory Acts & Rules
          </h4>
          <ul className="space-y-1.5 text-[11px] text-blue-100/80">
            <li>The Legal Metrology Act, 2009 (No. 1 of 2010)</li>
            <li>Packaged Commodities Rules (PCR) 2011 Amendments</li>
            <li>Mandatory Declarations on E-Commerce (Rule 6)</li>
            <li>Verification Fees & Stamp Specifications</li>
          </ul>
        </div>

        {/* Column 3: Citizen Grievances */}
        <div className="space-y-2">
          <h4 className="text-amber-400 font-bold text-xs uppercase tracking-wider border-b border-blue-800 pb-1">
            Citizen Grievance & Enforcement
          </h4>
          <ul className="space-y-1.5 text-[11px] text-blue-100/80">
            <li>File Underweight / Dual-MRP Complaint</li>
            <li>Track Redressal & Whistleblower Token</li>
            <li>Know Your Rights as a Consumer</li>
            <li>Appeals to Controller General (Sec. 50)</li>
          </ul>
        </div>

        {/* Column 4: Apex Redressal SLAs */}
        <div className="space-y-2">
          <h4 className="text-amber-400 font-bold text-xs uppercase tracking-wider border-b border-blue-800 pb-1">
            Apex Redressal SLAs
          </h4>
          <ul className="space-y-1 text-[11px] text-blue-100/80">
            <li><strong className="text-white">Field Inspection:</strong> Within 48 Hours</li>
            <li><strong className="text-white">Panchanama Upload:</strong> 24 Hours Post-Seizure</li>
            <li><strong className="text-white">Compounding Notice:</strong> Max 15 Business Days</li>
          </ul>
          <div className="bg-amber-500/10 border border-amber-500/30 rounded p-2 text-center mt-2">
            <span className="text-[10px] text-amber-300 font-bold block">Toll Free Consumer Helpline</span>
            <div className="flex items-center justify-center space-x-1 text-amber-400 font-bold text-sm">
              <Phone className="w-3.5 h-3.5" />
              <span>1915</span>
            </div>
          </div>
        </div>
      </div>

      {/* Copyright Bar */}
      <div className="bg-[#081427] border-t border-blue-800 py-3 text-center text-[10px] text-blue-200/90 px-4">
        © 2026 Ministry of Consumer Affairs, Food & Public Distribution, Govt. of India. Designed by National Informatics Centre (NIC).
      </div>
    </footer>
  );
}
