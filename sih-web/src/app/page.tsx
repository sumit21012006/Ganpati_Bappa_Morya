'use client';

import React, { useState, useEffect } from 'react';
import Header from '@/components/Header';
import Footer from '@/components/Footer';
import Sidebar from '@/components/Sidebar';
import LoginPortal from '@/components/LoginPortal';
import LeafletRadarMap from '@/components/LeafletRadarMap';
import JurisdictionAnalyticsGraphs from '@/components/JurisdictionAnalyticsGraphs';
import CitizenComplaintForm from '@/components/CitizenComplaintForm';
import { useApp } from '@/context/AppContext';
import { 
  fetchDashboardStats, 
  fetchCompoundingNotices, 
  fetchCitizenComplaints, 
  submitCitizenComplaint, 
  updateNoticeStatus, 
  fetchSupplyChainLinks 
} from '@/lib/api';
import { DashboardStats, Notice, SupplyChainLink, Complaint } from '@/types';
import { compoundingAction, assignSupplyChainLink, fetchInspectors, InspectorOption } from '@/lib/api/controller';

import { 
  ShieldAlert, 
  Activity, 
  RefreshCw, 
  AlertTriangle, 
  CheckCircle2, 
  Gavel, 
  Download, 
  FileCheck, 
  Zap, 
  Radio, 
  ChevronRight, 
  TrendingUp, 
  MapPin, 
  Building, 
  FileText, 
  CreditCard, 
  Camera, 
  Sparkles, 
  Award, 
  AlertCircle, 
  Clock, 
  Eye, 
  Lock, 
  Check,
  Search,
  SlidersHorizontal,
  ArrowRight,
  ExternalLink,
  FileSpreadsheet,
  Play,
  X,
  Send,
  Filter,
  Upload,
  ShieldCheck,
  FileCode,
  Landmark,
  BarChart3,
  PieChart,
  Printer,
  Building2,
  Plus,
  GitMerge
} from 'lucide-react';

export default function UnifiedPortalPage() {
  const { 
    user,
    role, 
    isLoggedIn, 
    citizenTab, 
    setCitizenTab,
    controllerTab, 
    setControllerTab,
    activeAlert, 
    rewardPointsBalance, 
    setRewardPointsBalance,
    isAuthChecking
  } = useApp();

  // State data
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [notices, setNotices] = useState<Notice[]>([]);
  const [complaints, setComplaints] = useState<Complaint[]>([]);
  const [supplyChainLinks, setSupplyChainLinks] = useState<SupplyChainLink[]>([]);

  
  // Citizen Complaint Filter & Modal States
  const [complaintSearchText, setComplaintSearchText] = useState<string>('');
  const [complaintStatusFilter, setComplaintStatusFilter] = useState<string>('ALL');
  const [complaintChannelFilter, setComplaintChannelFilter] = useState<string>('ALL');
  const [viewingComplaintItem, setViewingComplaintItem] = useState<any | null>(null);
  const [isAdvFilterModalOpen, setIsAdvFilterModalOpen] = useState<boolean>(false);
  
  // Form states for Citizen Complaint
  const [channel, setChannel] = useState<'OFFLINE_STORE' | 'ECOMMERCE_PLATFORM'>('OFFLINE_STORE');
  const [retailerSearch, setRetailerSearch] = useState<string>('');
  const [selectedRetailer, setSelectedRetailer] = useState<{ id?: string; name: string; address: string } | null>(null);
  const [statementOfFact, setStatementOfFact] = useState<string>(
    'Purchased bottle from QuickMart Supermarket shelf. Bottle felt visibly underweight compared to adjacent brands. Upon laboratory calibrated scale measurement in our cooperative society test bench, gross package weighed 925g with net oil estimated at 848ml vs statutory mandatory 1000ml declaration. Variance exceeds the 15ml maximum permissible error under Second Schedule of PCR 2011.'
  );
  const [citizenName, setCitizenName] = useState<string>('Arjun Suresh Sharma');
  const [selectedNoticeId, setSelectedNoticeId] = useState<string>('CO-2024-9041');
  const [loading, setLoading] = useState<boolean>(true);
  const [remarks, setRemarks] = useState<string>(
    'Order reviewed in accordance with Legal Metrology (Packaged Commodities) Rules 2011. First offence confirmed by registry query. Compounding granted subject to full forfeiture and correction of 42 impounded units under Inspector supervision.'
  );
  const [actionType, setActionType] = useState<string | null>(null);

  // Queue Filter state
  const [queueFilter, setQueueFilter] = useState<'ALL' | 'FIRST_OFFENCE' | 'HABITUAL' | 'HIGH_VALUE'>('ALL');
  const [queueSearch, setQueueSearch] = useState<string>('');

  // Interactive Modals & Controls State
  const [activeModal, setActiveModal] = useState<
    | 'RAID_DISPATCH'
    | 'DSC_SIGN'
    | 'PROSECUTION'
    | 'DISTRICT_LEDGER'
    | 'FILTER_RADAR'
    | 'DETAILED_DOSSIER_PDF'
    | 'LEAFLET_MAP'
    | null
  >(null);
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  
  const [citizenMobile, setCitizenMobile] = useState<string>('+91 98450 XXXXX');
  const [citizenUpiVpa, setCitizenUpiVpa] = useState<string>('arjun.sharma@okaxis');
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [submittedToken, setSubmittedToken] = useState<string | null>(null);

  const [isActionDone, setIsActionDone] = useState<boolean>(false);

  const FALLBACK_INSPECTORS: InspectorOption[] = [
    { id: 'usr-insp-sumit', name: 'Inspector Sumit Mane', email: 'sumit@gov.in', phone: '+91 98200 11001', district: 'Mumbai Suburban', jurisdiction: 'Mumbai Suburban Division' },
    { id: 'usr-insp-mihir', name: 'Inspector Mihir Patil', email: 'mihir@gov.in', phone: '+91 98200 11002', district: 'Pune Metro', jurisdiction: 'Pune Metropolitan Division' },
    { id: 'usr-insp-rohit', name: 'Inspector Rohit Sharma', email: 'rohit@gov.in', phone: '+91 98200 11003', district: 'Nagpur Central', jurisdiction: 'Nagpur Central Division' },
  ];

  const [inspectors, setInspectors] = useState<InspectorOption[]>(FALLBACK_INSPECTORS);
  // Modal Inputs
  const [selectedInspector, setSelectedInspector] = useState<string>('usr-insp-sumit');
  const [searchDinQuery, setSearchDinQuery] = useState<string>('');
  const [dscPin, setDscPin] = useState<string>('849201');
  const [prosecutionCourt, setProsecutionCourt] = useState<string>('Chief Metropolitan Magistrate Court, Esplanade Mumbai');
        
  // Regional Radar Filter State
  const [radarAlertFilter, setRadarAlertFilter] = useState<'ALL' | 'High Alert' | 'Moderate Watch' | 'Compliant'>('ALL');
  const [tempRadarFilter, setTempRadarFilter] = useState<'ALL' | 'High Alert' | 'Moderate Watch' | 'Compliant'>('ALL');

  const radarRegions = (stats?.regionalRadar || []).map((r) => {
    const alertLevel = r.alertLevel || 'Compliant';
    const alertColor = alertLevel === 'High Alert' ? 'bg-rose-500' : alertLevel === 'Moderate Watch' ? 'bg-amber-500' : 'bg-emerald-500';
    const badgeColor = alertLevel === 'High Alert' ? 'bg-rose-100 text-rose-700 border-rose-300' : alertLevel === 'Moderate Watch' ? 'bg-amber-100 text-amber-800 border-amber-300' : 'bg-emerald-100 text-emerald-800 border-emerald-300';
    const violationColor = alertLevel === 'High Alert' ? 'text-rose-600' : alertLevel === 'Moderate Watch' ? 'text-amber-600' : 'text-emerald-600';
    return {
      ...r,
      alertColor,
      badgeColor,
      violationColor,
      inspections: typeof r.inspections === 'number' ? r.inspections.toLocaleString() : r.inspections,
      slaRatePercent: typeof r.slaRatePercent === 'number' ? `${r.slaRatePercent}%` : r.slaRatePercent,
    };
  });

  const displayedRadarRegions = radarRegions.filter(
    (r) => radarAlertFilter === 'ALL' || r.alertLevel === radarAlertFilter
  );
  const [selectedRaidTarget, setSelectedRaidTarget] = useState<SupplyChainLink | null>(null);
  const [activeStreamCamera, setActiveStreamCamera] = useState<string>('BodyCam #1 (Inspector S. Kadam)');

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 4000);
  };

  const handleDownloadNoticePdf = (notice?: Notice | null) => {
    const target = notice || activeNotice;
    if (!target) return;
    const baseUrl = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8000';
    if (target.pdfUrl) {
      const url = target.pdfUrl.startsWith('http') ? target.pdfUrl : `${baseUrl}${target.pdfUrl}`;
      window.open(url, '_blank');
    } else {
      showToast(`Statutory Notice PDF for ${target.dinNumber || target.id} is being generated...`);
    }
  };


  useEffect(() => {
    fetchDashboardStats().then(setStats);
    fetchCompoundingNotices().then((data) => {
      setNotices(data);
      if (data.length > 0) setSelectedNoticeId(data[0].id);
    });
    fetchCitizenComplaints().then(setComplaints);
    fetchSupplyChainLinks().then(setSupplyChainLinks);
    fetchInspectors().then((data) => {
      if (data && data.length > 0) {
        setInspectors(data);
        setSelectedInspector((prev) => (data.some((d) => d.id === prev) ? prev : data[0].id));
      }
    });
  }, []);


  if (isAuthChecking) {
    return (
      <div className="min-h-screen bg-[#081427] text-white flex flex-col items-center justify-center space-y-4">
        <RefreshCw className="w-8 h-8 text-amber-400 animate-spin" />
        <p className="text-sm font-bold tracking-wider text-slate-300">AUTHENTICATING SECURE SESSION...</p>
      </div>
    );
  }

  if (!isLoggedIn) {
    return <LoginPortal />;
  }

  const isController = role === 'CONTROLLER';

  // Transform live complaints from backend into ledger rows
  const liveComplaintRows = complaints.map((c) => {
    const d = new Date(c.createdAt || Date.now());
    const dateStr = !isNaN(d.getTime())
      ? d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
      : 'Today';
    const isResolved = c.status === 'COMPOUNDED' || c.status === 'RESOLVED';
    return {
      id: c.id,
      date: dateStr,
      product: c.category || 'Packaged Commodity Violation',
      brandSub: `${c.channel === 'ECOMMERCE_PLATFORM' ? 'E-Commerce' : 'Offline Kirana'} • Live Registered`,
      entityName: c.retailerNameText || 'Reported Entity',
      entityAddress: c.retailerAddressText || 'Maharashtra Jurisdiction',
      channelType: (c.channel === 'ECOMMERCE_PLATFORM' ? 'QUICK_COMMERCE' : 'OFFLINE') as 'QUICK_COMMERCE' | 'OFFLINE',
      category: c.category || 'PCR 2011 Violation',
      status: isResolved ? '8. Compounded' : '1. Received (Under LMO Review)',
      statusType: (isResolved ? 'RESOLVED' : 'ACTIVE') as 'RESOLVED' | 'ACTIVE',
      inspector: isResolved ? 'LMO Assigned' : 'Awaiting Assignment',
      inspectorZone: 'District Metrology Wing',
      rewardStatus: isResolved ? '₹5,000 Credited' : '2,500 Pts Pending',
      rewardType: (isResolved ? 'CREDITED' : 'PENDING') as 'CREDITED' | 'PENDING',
      penalty: isResolved ? '₹50,000 Imposed' : 'Under Investigation',
      statement: c.statementOfFact || 'Statutory violation registered by verified citizen.',
      isNewLive: true,
    };
  });

  const allDisplayComplaints = liveComplaintRows;
  const activeNotice = notices.find((n) => n.id === selectedNoticeId) || notices[0];
  const caseNotices = notices.filter(
    (n) =>
      (activeNotice?.inspectionId && n.inspectionId && n.inspectionId === activeNotice.inspectionId) ||
      (activeNotice?.caseId && n.caseId && n.caseId === activeNotice.caseId) ||
      n.id === activeNotice?.id
  );
  const displayedNotices = caseNotices.length > 0 ? caseNotices : (activeNotice ? [activeNotice] : []);
  const spotlightCase = complaints[0] || null;

  const filteredNotices = notices.filter((n) => 
    searchDinQuery === '' ||
    n.dinNumber.toLowerCase().includes(searchDinQuery.toLowerCase()) ||
    n.businessName.toLowerCase().includes(searchDinQuery.toLowerCase()) ||
    n.sectionRefs.some((s) => s.toLowerCase().includes(searchDinQuery.toLowerCase()))
  );

  const handleSelectRetailer = (b: { id?: string; name: string; address: string }) => {
    setSelectedRetailer(b);
    setRetailerSearch(b.name);
  };

  const handleComplaintSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      const res = await submitCitizenComplaint({
        retailerNameText: selectedRetailer ? selectedRetailer.name : retailerSearch || 'Local Retailer',
        retailerAddressText: selectedRetailer ? selectedRetailer.address : 'Andheri West, Mumbai',
        channel,
        statementOfFact,
        citizenName,
        citizenMobile,
        citizenUpiVpa,
      });
      setSubmittedToken(res.id);
      setRewardPointsBalance((prev) => prev + 500);
      setComplaints((prev) => [res, ...prev]);
    } catch (err) {
      console.error(err);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleApproveNotice = async () => {
    if (!activeNotice) return;
    try {
      setIsActionDone(true);
      setActionType('APPROVED');
      const actRes = await compoundingAction(activeNotice.id, 'APPROVE', remarks, user?.id);
      // Optimistically update local notices state
      setNotices((prev) =>
        prev.map((n) => n.id === activeNotice.id ? {
          ...n,
          status: 'APPROVED' as const,
          paymentStatus: 'UNPAID' as const,
          digitalSignatureHash: (actRes as any)?.document_hash || 'EMUDHRA-DSC-MH-401'
        } : n)
      );
      showToast(`Compounding Order #${activeNotice.id} approved and signed via DSC.`);
    } catch (err: any) {
      console.error('[page] handleApproveNotice failed:', err);
      showToast(`Failed to approve: ${err.message || 'Backend error'}`);
    } finally {
      setActiveModal(null);
    }
  };

  const handleEscalateNotice = async () => {
    if (!activeNotice) return;
    try {
      setIsActionDone(true);
      setActionType('ESCALATED');
      await compoundingAction(activeNotice.id, 'PROSECUTION', remarks, user?.id);
      setNotices((prev) =>
        prev.map((n) => n.id === activeNotice.id ? { ...n, status: 'REJECTED' as const } : n)
      );
      showToast(`Case #${activeNotice.id} escalated to Public Prosecutor for Court Filing.`);
    } catch (err: any) {
      console.error('[page] handleEscalateNotice failed:', err);
      showToast(`Escalation recorded: ${err.message || 'Backend error — check console'}`);
    } finally {
      setActiveModal(null);
    }
  };

  const handleRejectNotice = async () => {
    if (!activeNotice) return;
    try {
      await compoundingAction(activeNotice.id, 'REJECT', remarks, user?.id);
      setNotices((prev) =>
        prev.map((n) => n.id === activeNotice.id ? { ...n, status: 'REJECTED' as const } : n)
      );
      showToast(`Notice #${activeNotice.id} returned to Inspector for revision.`);
    } catch (err: any) {
      console.error('[page] handleRejectNotice failed:', err);
      showToast(`Reject failed: ${err.message || 'Backend error'}`);
    } finally {
      setActiveModal(null);
    }
  };

  const handleDeployRaid = async () => {
    if (selectedRaidTarget) {
      try {
        const inspectorId = selectedInspector || inspectors[0]?.id || 'usr-insp-sumit';
        const chosenInsp = inspectors.find((i) => i.id === inspectorId);
        const resp: any = await assignSupplyChainLink(selectedRaidTarget.id, inspectorId);
        const finalInspName = resp.assignedInspectorName || chosenInsp?.name || inspectorId;

        setSupplyChainLinks((prev) =>
          prev.map((item) =>
            item.id === selectedRaidTarget.id
              ? { 
                  ...item, 
                  status: 'RAID_SCHEDULED' as const, 
                  assignedInspectorId: inspectorId,
                  assignedInspectorName: finalInspName
                }
              : item
          )
        );
        fetchSupplyChainLinks().then(setSupplyChainLinks).catch(() => {});
        showToast(`Surprise Raid Warrant deployed to ${finalInspName} for target ${selectedRaidTarget.namedBusinessName}`);
      } catch (err: any) {
        console.error('[page] handleDeployRaid failed:', err);
        showToast(`Failed to deploy raid: ${err.message || 'Assignment failed'}`);
      }
    } else {
      showToast(`Please select a valid upstream raid target.`);
    }
    setActiveModal(null);
  };

  const handleSyncStateGrid = async () => {
    try {
      showToast('Syncing state surveillance grid from backend...');
      const [newStats, newNotices, newLinks] = await Promise.all([
        fetchDashboardStats(),
        fetchCompoundingNotices(),
        fetchSupplyChainLinks(),
      ]);
      setStats(newStats);
      setNotices(newNotices);
      setSupplyChainLinks(newLinks);
      if (newNotices.length > 0 && !selectedNoticeId) {
        setSelectedNoticeId(newNotices[0].id);
      }
      showToast(`SYNC COMPLETE: ${newStats.totalInspections} inspections & ${newNotices.length} notices live.`);
    } catch (err) {
      console.error('[page] handleSyncStateGrid failed:', err);
      showToast('Surveillance Grid Sync Failed: Backend connection error');
    }
  };


  return (
    <div className="min-h-screen bg-[#EEF2F6] text-slate-900 flex flex-col font-sans relative">
      <Header />

      {/* Floating Toast Notification */}
      {toastMessage && (
        <div className="fixed top-20 right-6 z-50 bg-[#0D1F3C] text-white border border-amber-500/50 rounded-xl px-4 py-3 shadow-2xl flex items-center space-x-3 animate-bounce">
          <CheckCircle2 className="w-5 h-5 text-emerald-400 shrink-0" />
          <span className="text-xs font-bold">{toastMessage}</span>
          <button onClick={() => setToastMessage(null)} className="text-slate-400 hover:text-white ml-2">
            <X className="w-4 h-4" />
          </button>
        </div>
      )}

      <div className="flex flex-1">
        {/* Render Sidebar ONLY for Controller */}
        {isController && <Sidebar />}

        <main className="flex-1 p-4 md:p-6 space-y-6 overflow-x-hidden">
          {/* ========================================================================= */}
          {/* CITIZEN PORTAL VIEWS (ONLY SHOWN FOR CITIZEN ROLE)                       */}
          {/* ========================================================================= */}
          {!isController && citizenTab === 'FILE_COMPLAINT' && (
            <div className="max-w-7xl mx-auto space-y-6">
              <CitizenComplaintForm 
                isDarkMode={false} 
                onComplaintSubmitted={(newComplaint) => {
                  setComplaints((prev) => [newComplaint, ...prev]);
                  showToast(`Complaint #${newComplaint.id} registered! Opening ledger...`);
                  setTimeout(() => setCitizenTab('MY_COMPLAINTS'), 1500);
                }}
              />
            </div>
          )}

          {!isController && citizenTab === 'MY_COMPLAINTS' && (
            <div className="max-w-7xl mx-auto space-y-6">
              {/* Top Banner (Lapis Blue) */}
              <div className="bg-[#0D1F3C] text-white border border-blue-900 rounded-xl p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4 shadow-md">
                <div>
                  <div className="flex items-center space-x-2 text-xs text-amber-400 font-bold uppercase tracking-wider">
                    <span>SOVEREIGN CITIZEN PORTAL • SEC. 48 WHISTLEBLOWER PROTECTION</span>
                  </div>
                  <h1 className="text-xl md:text-2xl font-black text-white mt-1 flex items-center gap-2">
                    मेरी शिकायतें एवं प्रोत्साहन राशि
                    <span className="text-sm font-normal text-blue-200">My Complaints & Sovereign Whistleblower Incentive Ledger</span>
                  </h1>
                </div>

                <div className="flex items-center space-x-3">
                  <button 
                    onClick={() => showToast('Live Citizen Redressal Ledger exported to CSV/PDF.')}
                    className="bg-[#081427] hover:bg-blue-800 border border-blue-700 text-xs px-3.5 py-2 rounded-lg text-white flex items-center space-x-1.5 font-bold cursor-pointer transition-all shadow"
                  >
                    <Download className="w-3.5 h-3.5" />
                    <span>Download Ledger (PDF)</span>
                  </button>
                  <button 
                    onClick={() => setCitizenTab('FILE_COMPLAINT')}
                    className="bg-amber-500 hover:bg-amber-400 text-slate-950 text-xs px-3.5 py-2 rounded-lg font-black flex items-center space-x-1.5 cursor-pointer shadow-lg transition-all"
                  >
                    <Plus className="w-4 h-4 stroke-[3]" />
                    <span>+ New Complaint</span>
                  </button>
                </div>
              </div>

              {/* 4 Summary Cards Grid (WHITE CARDS) */}
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                <div className="bg-white border border-slate-200/80 rounded-xl p-4 space-y-1 shadow-sm">
                  <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider">TOTAL COMPLAINTS FILED</div>
                  <div className="text-2xl font-black text-slate-900">{allDisplayComplaints.length} <span className="text-xs text-slate-500 font-normal">Cases</span></div>
                  <div className="text-[10px] text-emerald-600 flex items-center gap-1 pt-1 border-t border-slate-100 font-semibold">
                    <CheckCircle2 className="w-3 h-3" /> 100% Validated by National Metrology AI
                  </div>
                </div>

                <div className="bg-white border border-slate-200/80 rounded-xl p-4 space-y-1 shadow-sm">
                  <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider">UNDER ACTIVE INVESTIGATION</div>
                  <div className="text-2xl font-black text-amber-600">{allDisplayComplaints.filter((c) => c.statusType === 'ACTIVE').length} <span className="text-xs text-slate-500 font-normal">Active</span></div>
                  <div className="text-[10px] text-amber-600 flex items-center gap-1 pt-1 border-t border-slate-100 font-semibold">
                    <Clock className="w-3 h-3" /> LMO Field Raids Authorized
                  </div>
                </div>

                <div className="bg-white border border-slate-200/80 rounded-xl p-4 space-y-1 shadow-sm">
                  <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider">NOTICES ISSUED & COMPOUNDED</div>
                  <div className="text-2xl font-black text-emerald-600">{allDisplayComplaints.filter((c) => c.statusType === 'RESOLVED').length} <span className="text-xs text-slate-500 font-normal">Resolved</span></div>
                  <div className="text-[10px] text-slate-500 pt-1 border-t border-slate-100">
                    Fine Recovered: ₹50,000 Govt Treasury
                  </div>
                </div>

                {/* Vigilance Incentives (Lapis Blue Box with Reward Points) */}
                <div className="bg-[#0D1F3C] text-white border border-amber-500/40 rounded-xl p-4 space-y-1 shadow-md">
                  <div className="text-[10px] text-amber-400 font-bold uppercase tracking-wider flex items-center justify-between">
                    <span>VIGILANCE INCENTIVES</span>
                    <span className="bg-amber-500/20 text-amber-300 px-1.5 py-0.5 rounded text-[9px] font-bold">PFMS Direct</span>
                  </div>
                  <div className="text-2xl font-black text-amber-400 font-mono">
                    ₹{(user?.rewardPoints || 0).toLocaleString()} <span className="text-xs font-normal text-blue-200">/ {(user?.rewardPoints || 0).toLocaleString()} Points</span>
                  </div>
                  <div className="text-[10px] text-blue-200 flex items-center justify-between pt-1 border-t border-amber-500/20">
                    <span>Net In-Flight: ₹5,000</span>
                    <span onClick={() => showToast('Displaying Reward Passbook...')} className="text-amber-400 hover:underline cursor-pointer font-bold">View Passbook</span>
                  </div>
                </div>
              </div>

              {/* Filter & Search Controls Bar (Fully Functional) */}
              <div className="bg-white border border-slate-200/80 rounded-xl p-3 flex flex-wrap items-center justify-between gap-3 shadow-sm text-xs">
                <div className="flex-1 min-w-[240px] relative">
                  <Search className="w-3.5 h-3.5 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                  <input
                    type="text"
                    value={complaintSearchText}
                    onChange={(e) => setComplaintSearchText(e.target.value)}
                    placeholder="Search by Complaint ID, Merchant or Brand..."
                    className="w-full bg-slate-50 border border-slate-200 rounded-lg pl-9 pr-3 py-1.5 text-xs text-slate-900 focus:outline-none focus:border-amber-500"
                  />
                </div>

                <div className="flex items-center space-x-2">
                  <select 
                    value={complaintStatusFilter}
                    onChange={(e) => setComplaintStatusFilter(e.target.value)}
                    className="bg-slate-50 border border-slate-200 text-slate-700 text-xs font-semibold rounded-lg px-3 py-1.5 cursor-pointer"
                  >
                    <option value="ALL">All Statuses (4)</option>
                    <option value="ACTIVE">Active Investigation (2)</option>
                    <option value="RESOLVED">Compounded / Resolved (2)</option>
                  </select>

                  <select 
                    value={complaintChannelFilter}
                    onChange={(e) => setComplaintChannelFilter(e.target.value)}
                    className="bg-slate-50 border border-slate-200 text-slate-700 text-xs font-semibold rounded-lg px-3 py-1.5 cursor-pointer"
                  >
                    <option value="ALL">All Channels</option>
                    <option value="QUICK_COMMERCE">Quick Commerce / E-Com</option>
                    <option value="OFFLINE">Offline Kirana Stores</option>
                  </select>

                  <button 
                    onClick={() => {
                      setComplaintSearchText('');
                      setComplaintStatusFilter('ALL');
                      setComplaintChannelFilter('ALL');
                      showToast('Filters reset.');
                    }} 
                    className="p-2 bg-slate-50 hover:bg-slate-100 border border-slate-200 rounded-lg text-slate-600 cursor-pointer"
                    title="Reset Filters"
                  >
                    <RefreshCw className="w-3.5 h-3.5" />
                  </button>

                  <button 
                    onClick={() => setIsAdvFilterModalOpen(true)} 
                    className="bg-slate-100 hover:bg-slate-200 border border-slate-300 text-slate-700 font-bold px-3 py-1.5 rounded-lg flex items-center gap-1.5 cursor-pointer"
                  >
                    <SlidersHorizontal className="w-3.5 h-3.5" />
                    <span>Advanced Filter</span>
                  </button>
                </div>
              </div>

              {/* Spotlight Case Card (WHITE CARD) */}
              {spotlightCase && (
                <div className="bg-white border border-slate-200/80 rounded-xl p-5 space-y-5 shadow-sm">
                  {/* Case Header */}
                  <div className="flex flex-col md:flex-row md:items-center justify-between gap-3 border-b border-slate-100 pb-3">
                    <div className="flex items-center space-x-3">
                      <span className="bg-slate-900 text-white font-mono font-bold text-xs px-2.5 py-1 rounded">
                        Case #{spotlightCase.id}
                      </span>
                      <span className="bg-rose-100 text-rose-700 border border-rose-200 text-[10px] font-bold px-2.5 py-0.5 rounded">
                        ⚠️ {spotlightCase.category || 'Statutory Non-Compliance'}
                      </span>
                      <span className="bg-slate-100 text-slate-700 text-[10px] font-semibold px-2 py-0.5 rounded">
                        {spotlightCase.channel === 'ECOMMERCE_PLATFORM' ? 'E-Commerce Platform' : 'Offline Retail Store'}
                      </span>
                    </div>
                    <div className="text-[11px] text-amber-700 font-bold flex items-center gap-1 font-mono">
                      <Clock className="w-3.5 h-3.5 text-amber-600" /> Status: {spotlightCase.status}
                    </div>
                  </div>

                  {/* Case Detail Grid */}
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-xs bg-slate-50 p-3.5 rounded-xl border border-slate-200">
                    <div>
                      <div className="text-[10px] text-slate-400 uppercase font-bold tracking-wider">ACCUSED MERCHANT / ENTITY</div>
                      <div className="font-bold text-slate-900 mt-0.5">{spotlightCase.retailerNameText || 'Retail Store'}</div>
                      <div className="text-[10px] text-slate-500">{spotlightCase.retailerAddressText || 'Premises Recorded'}</div>
                    </div>
                    <div>
                      <div className="text-[10px] text-slate-400 uppercase font-bold tracking-wider">VIOLATING COMMODITY / CATEGORY</div>
                      <div className="font-bold text-slate-900 mt-0.5">{spotlightCase.category || 'Packaged Commodity'}</div>
                      <div className="text-[10px] text-slate-500">Statutory verification in progress</div>
                    </div>
                    <div>
                      <div className="text-[10px] text-slate-400 uppercase font-bold tracking-wider">JURISDICTION & OFFICER</div>
                      <div className="font-bold text-amber-700 mt-0.5">{spotlightCase.status === 'RESOLVED' ? 'Inspector V. K. Patil' : 'Divisional Flying Squad'}</div>
                      <div className="text-[10px] text-slate-500">Legal Metrology Division</div>
                    </div>
                    <div>
                      <div className="text-[10px] text-slate-400 uppercase font-bold tracking-wider">STATUTORY PENAL OUTCOME</div>
                      <div className="font-black text-emerald-600 text-sm mt-0.5">{spotlightCase.status === 'RESOLVED' ? '₹50,000 Imposed' : 'Under Investigation'}</div>
                      <div className="text-[10px] text-slate-500">Incentive: ₹{spotlightCase.estimatedRewardPoints || 5000}</div>
                    </div>
                  </div>

                  {/* 5-Stage Stepper */}
                  <div className="space-y-2">
                    <div className="flex items-center justify-between">
                      <h4 className="text-xs font-bold text-slate-900 flex items-center gap-1.5">
                        <Activity className="w-3.5 h-3.5 text-amber-600" />
                        5-Stage Statutory Redressal & Incentive Lifecycle
                      </h4>
                      <span className="text-[10px] text-slate-400 font-mono">Digital Audit Trail Cryptographically Sealed</span>
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-5 gap-2 text-xs">
                      <div className="bg-slate-50 border-l-4 border-emerald-500 p-2.5 rounded-lg space-y-1">
                        <div className="text-[10px] text-slate-400 font-mono font-bold flex items-center justify-between">
                          <span>12 Oct 2024</span>
                          <Check className="w-3 h-3 text-emerald-600" />
                        </div>
                        <div className="font-bold text-slate-900 text-[11px]">Stage 1: Complaint & OCR</div>
                        <div className="text-[9px] text-slate-500">AI model verified barcode & OCR discrepancy from consumer upload.</div>
                      </div>

                      <div className="bg-slate-50 border-l-4 border-emerald-500 p-2.5 rounded-lg space-y-1">
                        <div className="text-[10px] text-slate-400 font-mono font-bold flex items-center justify-between">
                          <span>15 Oct 2024</span>
                          <Check className="w-3 h-3 text-emerald-600" />
                        </div>
                        <div className="font-bold text-slate-900 text-[11px]">Stage 2: Surprise Field Raid</div>
                        <div className="text-[9px] text-slate-500">LMO Mumbai raided hub at 14:30 IST. 42 tampered packages seized.</div>
                      </div>

                      <div className="bg-slate-50 border-l-4 border-emerald-500 p-2.5 rounded-lg space-y-1">
                        <div className="text-[10px] text-slate-400 font-mono font-bold flex items-center justify-between">
                          <span>18 Oct 2024</span>
                          <Check className="w-3 h-3 text-emerald-600" />
                        </div>
                        <div className="font-bold text-slate-900 text-[11px]">Stage 3: Seizure Panchnama</div>
                        <div className="text-[9px] text-slate-500">Rule 18(1) Notice served to directors; Form V inventory created.</div>
                      </div>

                      <div className="bg-slate-50 border-l-4 border-emerald-500 p-2.5 rounded-lg space-y-1">
                        <div className="text-[10px] text-slate-400 font-mono font-bold flex items-center justify-between">
                          <span>22 Oct 2024</span>
                          <Check className="w-3 h-3 text-emerald-600" />
                        </div>
                        <div className="font-bold text-slate-900 text-[11px]">Stage 4: Compounding Order</div>
                        <div className="text-[9px] text-slate-500">₹50,000 penalty paid into Consolidated Fund of India.</div>
                      </div>

                      <div className="bg-[#0D1F3C] text-white border-l-4 border-emerald-400 p-2.5 rounded-lg space-y-1 shadow-md">
                        <div className="text-[10px] text-emerald-400 font-bold flex items-center justify-between">
                          <span>CREDITED</span>
                          <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping"></span>
                        </div>
                        <div className="font-bold text-emerald-300 text-[11px]">Stage 5: Whistleblower Reward</div>
                        <div className="text-xs font-black text-amber-400 font-mono">₹5,000.00</div>
                        <div className="text-[9px] text-slate-300">Transferred via NPCI/PFMS DBT directly to citizen UPI handle.</div>
                      </div>
                    </div>
                  </div>

                  {/* Sub-Tabs: Inspector Verification Report | Statutory Notices | Treasury Slip */}
                  <div className="border border-slate-200 rounded-xl overflow-hidden text-xs">
                    <div className="bg-slate-50 border-b border-slate-200 px-3 py-2 flex items-center space-x-4 font-bold">
                      <button className="text-amber-700 border-b-2 border-amber-500 pb-1 flex items-center gap-1.5">
                        <FileText className="w-3.5 h-3.5" />
                        <span>Tab 1: Inspector Verification Report</span>
                      </button>
                      <button onClick={() => showToast('Opening Form V Statutory Notice...')} className="text-slate-500 hover:text-slate-900 pb-1 flex items-center gap-1.5 cursor-pointer">
                        <FileCode className="w-3.5 h-3.5" />
                        <span>Tab 2: Statutory Notices & Form V</span>
                      </button>
                      <button onClick={() => showToast('Opening Treasury Payout Receipt...')} className="text-slate-500 hover:text-slate-900 pb-1 flex items-center gap-1.5 cursor-pointer">
                        <Landmark className="w-3.5 h-3.5" />
                        <span>Tab 3: Treasury Payout Slip (₹5,000)</span>
                      </button>
                    </div>

                    <div className="p-4 grid grid-cols-1 lg:grid-cols-12 gap-4 bg-white">
                      {/* Left: Inspection Notes */}
                      <div className="lg:col-span-8 space-y-3">
                        <div className="flex items-center justify-between">
                          <span className="text-[10px] font-bold text-rose-600 uppercase tracking-wider">FIELD INSPECTION FINDING NOTES</span>
                          <span className="text-[10px] text-slate-400 font-mono">Auth Ref: LMO/MUM/Z4/2024/774</span>
                        </div>

                        <p className="text-slate-700 text-xs leading-relaxed font-mono bg-slate-50 p-3.5 rounded-xl border border-slate-200">
                          &quot;{spotlightCase.statementOfFact || 'Statutory inspection and consumer complaint filed under Legal Metrology (Packaged Commodities) Rules, 2011. Verified by electronic signature and state enforcement record.'}&quot;
                        </p>

                        <div className="flex items-center space-x-2 text-[10px] text-slate-500 pt-2 border-t border-slate-100">
                          <ShieldCheck className="w-4 h-4 text-emerald-600" />
                          <span>DSC Cryptographically Signed as per IT Act, 2000</span>
                          <span className="font-mono text-slate-700 font-bold">Signed by: VIKRAM KESHAV PATIL, ILMO-24-MH01 | 16-Oct-2024 10:12:04 IST</span>
                          <span className="bg-emerald-100 text-emerald-800 text-[9px] font-bold px-1.5 py-0.5 rounded font-mono">SHA-256 Valid</span>
                        </div>
                      </div>

                      {/* Right: Seized Evidence Photos */}
                      <div className="lg:col-span-4 space-y-2">
                        <div className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">SEIZED EVIDENCE PHOTOS</div>
                        <div className="h-44 rounded-xl border border-slate-300 overflow-hidden relative group bg-slate-950">
                          <img src="/images/sample_declarations.jpg" alt="Seized Evidence" className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
                          <div className="absolute inset-0 bg-gradient-to-t from-slate-950/80 via-transparent to-transparent flex items-end p-2.5 justify-between">
                            <span className="text-[10px] text-white font-mono bg-slate-900/90 px-2 py-0.5 rounded border border-slate-700">
                              EXIF Hash Verified
                            </span>
                            <button onClick={() => showToast('Opening high-resolution photo modal...')} className="bg-blue-600 hover:bg-blue-500 text-white text-[9px] font-bold px-2 py-1 rounded shadow cursor-pointer">
                              Full Resolution (4.2 MB)
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* Case Registry Table (WHITE CARD - VIOLATION CATEGORY REMOVED) */}
              <div className="bg-white border border-slate-200/80 rounded-xl p-5 space-y-4 shadow-sm">
                <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                  <h3 className="text-base font-black text-slate-900">Comprehensive Case Registry (ऐतिहासिक मामले)</h3>
                  <div className="flex items-center space-x-2 text-xs">
                    <span className="text-slate-500 text-[11px]">Sort by:</span>
                    <select className="bg-slate-50 border border-slate-200 rounded px-2.5 py-1 text-xs font-semibold cursor-pointer">
                      <option>Filing Date (Latest First)</option>
                      <option>Highest Penalty Imposed</option>
                    </select>
                  </div>
                </div>

                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs text-slate-700">
                    <thead className="bg-slate-50 text-slate-500 text-[10px] uppercase font-bold tracking-wider border-b border-slate-200">
                      <tr>
                        <th className="p-3">COMPLAINT ID & DATE</th>
                        <th className="p-3">PRODUCT & BRAND</th>
                        <th className="p-3">ENTITY NAME</th>
                        <th className="p-3">CURRENT STATE</th>
                        <th className="p-3">INSPECTOR IN-CHARGE</th>
                        <th className="p-3">REWARD STATUS</th>
                        <th className="p-3 text-right">ACTIONS</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {allDisplayComplaints.length === 0 && (
                        <tr>
                          <td colSpan={7} className="p-8 text-center text-slate-500">
                            <FileText className="w-8 h-8 text-slate-300 mx-auto mb-2" />
                            <div className="font-bold text-slate-700">No citizen complaints recorded yet</div>
                            <div className="text-[11px] text-slate-400 mt-0.5">Statutory complaints filed via the form above will appear here in real time.</div>
                          </td>
                        </tr>
                      )}
                      {allDisplayComplaints.filter((item) => {
                        const matchesSearch = 
                          complaintSearchText === '' ||
                          item.id.toLowerCase().includes(complaintSearchText.toLowerCase()) ||
                          item.product.toLowerCase().includes(complaintSearchText.toLowerCase()) ||
                          item.entityName.toLowerCase().includes(complaintSearchText.toLowerCase());

                        const matchesStatus = 
                          complaintStatusFilter === 'ALL' ||
                          (complaintStatusFilter === 'ACTIVE' && item.statusType === 'ACTIVE') ||
                          (complaintStatusFilter === 'RESOLVED' && item.statusType === 'RESOLVED');

                        const matchesChannel =
                          complaintChannelFilter === 'ALL' ||
                          item.channelType === complaintChannelFilter;

                        return matchesSearch && matchesStatus && matchesChannel;
                      }).map((row) => (
                        <tr key={row.id} className="hover:bg-slate-50 transition-colors">
                          <td className="p-3 font-mono font-bold text-amber-700">
                            <div className="flex items-center gap-1.5">
                              <span>{row.id}</span>
                              {row.isNewLive && (
                                <span className="bg-emerald-100 text-emerald-800 text-[9px] font-bold px-1.5 py-0.5 rounded border border-emerald-300">
                                  LIVE
                                </span>
                              )}
                            </div>
                            <div className="text-[10px] text-slate-400 font-normal">{row.date}</div>
                          </td>
                          <td className="p-3 font-semibold text-slate-900">
                            {row.product} 
                            <div className="text-[10px] text-slate-400 font-normal">{row.brandSub}</div>
                          </td>
                          <td className="p-3 text-slate-700">
                            {row.entityName} 
                            <div className="text-[10px] text-slate-400 font-normal">{row.entityAddress}</div>
                          </td>
                          <td className="p-3">
                            <span className={`text-[10px] font-bold px-2 py-0.5 rounded border ${
                              row.statusType === 'RESOLVED' ? 'bg-slate-100 text-slate-800 border-slate-300' : 'bg-rose-50 text-rose-700 border-rose-200'
                            }`}>
                              {row.status}
                            </span>
                          </td>
                          <td className="p-3 font-semibold text-slate-800">
                            {row.inspector} 
                            <div className="text-[10px] text-slate-400 font-normal">{row.inspectorZone}</div>
                          </td>
                          <td className="p-3 font-mono">
                            <span className={`text-[10px] font-bold px-2 py-1 rounded ${
                              row.rewardType === 'CREDITED' ? 'bg-slate-900 text-amber-400 border border-amber-500/40 font-mono' : 'bg-amber-50 text-amber-800 border border-amber-200'
                            }`}>
                              {row.rewardStatus}
                            </span>
                          </td>
                          <td className="p-3 text-right space-x-1.5">
                            <button 
                              onClick={() => showToast(`Initiated statutory digital record export for #${row.id}`)} 
                              className="p-1.5 text-slate-500 hover:text-slate-900 hover:bg-slate-100 rounded transition-all cursor-pointer" 
                              title="Download Case PDF"
                            >
                              <Download className="w-4 h-4" />
                            </button>
                            <button 
                              onClick={() => setViewingComplaintItem(row)} 
                              className="p-1.5 text-amber-600 hover:text-amber-700 hover:bg-amber-50 rounded transition-all cursor-pointer" 
                              title="View Detailed Case Dossier"
                            >
                              <Eye className="w-4 h-4" />
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>

                {/* Table Pagination Bar */}
                <div className="flex items-center justify-between text-xs text-slate-500 pt-3 border-t border-slate-100">
                  <div>Showing complaint records linked to mobile +91 98450 XXXXX</div>
                  <div className="flex items-center space-x-1">
                    <button className="px-2.5 py-1 rounded border border-slate-200 bg-slate-50 text-slate-400 cursor-not-allowed">Previous</button>
                    <button className="px-2.5 py-1 rounded border border-slate-900 bg-slate-900 text-white font-bold">1</button>
                    <button className="px-2.5 py-1 rounded border border-slate-200 bg-slate-50 text-slate-400 cursor-not-allowed">Next</button>
                  </div>
                </div>
              </div>

              {/* Bottom Whistleblower Guarantee Banner (Image 2) */}
              <div className="bg-[#0D1F3C] text-white border border-amber-500/40 rounded-xl p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4 shadow-md">
                <div className="flex items-center space-x-3">
                  <div className="w-10 h-10 rounded-full bg-amber-500/20 text-amber-400 border border-amber-500/40 flex items-center justify-center font-bold shrink-0">
                    <ShieldCheck className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="text-xs font-bold text-amber-400">Legal Metrology Whistleblower Protection Guarantee</h4>
                    <p className="text-[11px] text-blue-200 mt-0.5">
                      Under Section 48(B) of Legal Metrology Act, 2009, consumer informant identity is sovereignly protected with end-to-end token hashing. 10% of compounding penalties (up to ₹25,000) are statutory rewards credited to citizens.
                    </p>
                  </div>
                </div>
                <div className="flex items-center space-x-2 shrink-0">
                  <button onClick={() => showToast('Displaying Whistleblower Protection Rules...')} className="bg-[#081427] hover:bg-blue-800 border border-blue-700 text-xs px-3 py-2 rounded-lg text-white font-bold cursor-pointer">
                    Statutory Reward Rules
                  </button>
                  <a href="tel:1915" className="bg-amber-500 hover:bg-amber-400 text-slate-950 text-xs px-3 py-2 rounded-lg font-black flex items-center gap-1 cursor-pointer">
                    National Consumer Helpline 1915
                  </a>
                </div>
              </div>
            </div>
          )}

          {/* ========================================================================= */}
          {/* CONTROLLER PORTAL VIEWS (MATCHING IMAGE 1 & IMAGE 3 SPECIFICALLY)         */}
          {/* ========================================================================= */}
          {isController && controllerTab === 'COMMAND_DASHBOARD' && (
            <div className="space-y-6">
              {/* 1. Top Directorate Header Banner (Lapis Blue Banner) */}
              <div className="bg-[#0D1F3C] text-white border border-blue-900 rounded-xl p-5 relative overflow-hidden shadow-md">
                <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
                  <div>
                    <div className="flex items-center space-x-2 text-xs text-blue-200 font-semibold uppercase tracking-wider mb-1">
                      <ShieldAlert className="w-4 h-4 text-amber-400" />
                      <span>ENFORCEMENT HUB • SEC. 36, 38 & 53 LEGAL METROLOGY ACT 2011</span>
                      <span className="text-blue-400">|</span>
                      <span className="font-mono text-blue-200">DIN Registry: MH-HQ-9928/2024-25</span>
                    </div>
                    <h1 className="text-xl md:text-2xl font-black tracking-tight text-white">
                      Directorate of Legal Metrology, Maharashtra & Inter-State Command
                    </h1>
                    <p className="text-xs text-blue-100/80 mt-1">
                      नियंत्रक कमान केंद्र • Apex Surveillance, Statutory Traceback & Compounding Adjudication
                    </p>
                  </div>

                  <div className="flex flex-wrap items-center gap-3">
                    <div className="bg-[#081427] border border-blue-800/80 rounded-lg px-3.5 py-2 text-left">
                      <div className="text-[10px] text-blue-200 uppercase font-bold tracking-wider">FIELD DEPLOYMENT</div>
                      <div className="text-xs font-black text-emerald-400 flex items-center gap-1.5">
                        <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                        <span>1,428 Officers Online</span>
                      </div>
                    </div>

                    <div className="bg-[#081427] border border-blue-800/80 rounded-lg px-3.5 py-2 text-left">
                      <div className="text-[10px] text-blue-200 uppercase font-bold tracking-wider">ADJUDICATION CYCLE</div>
                      <div className="text-xs font-bold text-white font-mono">FY 2024-25 Q3</div>
                    </div>

                    <button 
                      onClick={handleSyncStateGrid}
                      className="bg-amber-500 hover:bg-amber-400 text-slate-950 font-black px-4 py-2.5 rounded-lg text-xs flex items-center space-x-2 shadow-lg transition-all cursor-pointer"
                    >
                      <RefreshCw className="w-4 h-4" />
                      <span>Sync State Grid</span>
                    </button>
                  </div>
                </div>

                {/* Live Ticker Bar at bottom of Directorate Banner */}
                <div className="mt-4 pt-3 border-t border-blue-800/80 flex items-center space-x-3 text-xs">
                  <span className="bg-rose-600 text-white font-extrabold text-[9px] uppercase px-2 py-0.5 rounded tracking-wide shrink-0">
                    LIVE STATUTORY TICKER
                  </span>
                  <p className="text-blue-100/90 text-[11px] truncate flex-1">
                    Alert: Repeat violation detected for FastFoods Brand in Pune Baramati Sector — Automated Section 36(2) Raid Warrant Generated.
                  </p>
                  <span className="text-[10px] text-blue-200/70 font-mono shrink-0">2 mins ago</span>
                </div>
              </div>

              {/* 2. Top Gross Surveillance Metrics Grid (Image 1 + Image 3) */}
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                {/* Card 1: Gross Surveillance */}
                <div className="bg-white border border-slate-200/80 rounded-xl p-4 space-y-3 shadow-sm hover:shadow-md transition-all">
                  <div className="flex items-center justify-between">
                    <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">GROSS SURVEILLANCE</span>
                    <div className="w-8 h-8 rounded-lg bg-blue-50 border border-blue-200 flex items-center justify-center text-blue-600">
                      <Activity className="w-4.5 h-4.5" />
                    </div>
                  </div>
                  <div>
                    <h3 className="text-xs text-slate-600 font-bold">Total Inspections</h3>
                    <div className="flex items-baseline space-x-2 mt-1">
                      <span className="text-2xl font-black text-slate-900 tracking-tight">
                        {stats?.totalInspections?.toLocaleString('en-IN') ?? '0'}
                      </span>
                      <span className="text-[10px] font-bold text-emerald-700 bg-emerald-50 px-1.5 py-0.5 rounded border border-emerald-200">
                        Live Database
                      </span>
                    </div>
                  </div>
                  
                  {/* HIGH VISIBILITY PROMINENT SUB-METRICS */}
                  <div className="pt-2.5 border-t border-slate-200/80 grid grid-cols-2 gap-2 text-xs">
                    <div className="bg-blue-50/70 border border-blue-200 p-2.5 rounded-lg space-y-1">
                      <span className="text-[11px] font-bold text-blue-900 block leading-tight">Surveillance Target</span>
                      <div className="text-sm font-black text-blue-700">{stats?.totalInspectionsTarget?.toLocaleString('en-IN') ?? '0'}</div>
                      <span className="text-[10px] font-bold text-blue-800 bg-blue-100/80 px-1.5 py-0.5 rounded inline-block">Annual Goal</span>
                    </div>
                    <div className="bg-emerald-50/70 border border-emerald-200 p-2.5 rounded-lg space-y-1">
                      <span className="text-[11px] font-bold text-emerald-900 block leading-tight">Active Officers</span>
                      <div className="text-sm font-black text-emerald-700">{stats?.activeOfficersCount ?? 0} On Duty</div>
                      <span className="text-[10px] font-bold text-emerald-800 bg-emerald-100/80 px-1.5 py-0.5 rounded inline-block">State Cadre</span>
                    </div>
                  </div>
                </div>

                {/* Card 2: Sec 36(1) Deficits (1st Offence cases booked & compounded) */}
                <div className="bg-white border border-slate-200/80 rounded-xl p-4 space-y-3 shadow-sm hover:shadow-md transition-all">
                  <div className="flex items-center justify-between">
                    <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">SEC 36(1) DEFICITS</span>
                    <div className="w-8 h-8 rounded-lg bg-amber-50 border border-amber-200 flex items-center justify-center text-amber-600">
                      <AlertTriangle className="w-4.5 h-4.5" />
                    </div>
                  </div>
                  <div>
                    <h3 className="text-xs text-slate-600 font-bold">1st Offences Logged</h3>
                    <div className="flex items-baseline space-x-2 mt-1">
                      <span className="text-2xl font-black text-slate-900 tracking-tight">
                        {stats?.firstOffencesLogged?.toLocaleString('en-IN') ?? '0'}
                      </span>
                      <span className="text-[10px] font-bold text-amber-800 bg-amber-50 px-1.5 py-0.5 rounded border border-amber-200">
                        30-Day Cum Notices
                      </span>
                    </div>
                  </div>
                  
                  {/* HIGH VISIBILITY PROMINENT SUB-METRICS */}
                  <div className="pt-2.5 border-t border-slate-200/80 grid grid-cols-2 gap-2 text-xs">
                    <div className="bg-slate-50 border border-slate-200 p-2.5 rounded-lg space-y-1">
                      <span className="text-[11px] font-bold text-slate-700 block leading-tight">1st Offence cases booked</span>
                      <div className="text-sm font-black text-slate-900">{stats?.firstOffencesNoticesServed ?? 0}</div>
                      <span className="text-[10px] font-bold text-slate-500 bg-slate-200/60 px-1.5 py-0.5 rounded inline-block">Notices Served</span>
                    </div>
                    <div className="bg-amber-50/70 border border-amber-200 p-2.5 rounded-lg space-y-1">
                      <span className="text-[11px] font-bold text-amber-900 block leading-tight">1st Offence cases compounded</span>
                      <div className="text-sm font-black text-amber-700">{stats?.firstOffencesUnderVerification ?? 0}</div>
                      <span className="text-[10px] font-bold text-amber-800 bg-amber-100/80 px-1.5 py-0.5 rounded inline-block">Under Verification</span>
                    </div>
                  </div>
                </div>

                {/* Card 3: Habitual Breaches (2nd Offence cases booked & court filed) */}
                <div className="bg-white border border-slate-200/80 rounded-xl p-4 space-y-3 shadow-sm hover:shadow-md transition-all">
                  <div className="flex items-center justify-between">
                    <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">HABITUAL BREACHES</span>
                    <div className="w-8 h-8 rounded-lg bg-rose-50 border border-rose-200 flex items-center justify-center text-rose-600">
                      <Gavel className="w-4.5 h-4.5" />
                    </div>
                  </div>
                  <div>
                    <h3 className="text-xs text-slate-600 font-bold">2nd / Repeat Offences</h3>
                    <div className="flex items-baseline space-x-2 mt-1">
                      <span className="text-2xl font-black text-rose-600 tracking-tight">
                        {stats?.secondOffencesLogged?.toLocaleString('en-IN') ?? '0'}
                      </span>
                      <span className="text-[10px] font-bold text-rose-800 bg-rose-50 px-1.5 py-0.5 rounded border border-rose-200">
                        Non-Compounding
                      </span>
                    </div>
                  </div>

                  {/* HIGH VISIBILITY PROMINENT SUB-METRICS */}
                  <div className="pt-2.5 border-t border-slate-200/80 grid grid-cols-2 gap-2 text-xs">
                    <div className="bg-rose-50/70 border border-rose-200 p-2.5 rounded-lg space-y-1">
                      <span className="text-[11px] font-bold text-rose-900 block leading-tight">2nd Offence cases booked</span>
                      <div className="text-sm font-black text-rose-700">{stats?.secondOffencesLogged ?? 0}</div>
                      <span className="text-[10px] font-bold text-rose-800 bg-rose-100/80 px-1.5 py-0.5 rounded inline-block">Non-Compounding</span>
                    </div>
                    <div className="bg-slate-50 border border-slate-200 p-2.5 rounded-lg space-y-1">
                      <span className="text-[11px] font-bold text-slate-700 block leading-tight">2nd Offence court filed</span>
                      <div className="text-sm font-black text-slate-900">{stats?.secondOffencesChargesheets ?? 0}</div>
                      <span className="text-[10px] font-bold text-slate-500 bg-slate-200/60 px-1.5 py-0.5 rounded inline-block">Lodged in Court</span>
                    </div>
                  </div>
                </div>

                {/* Card 4: Bharatkosh Revenue (Penalties Recovered) */}
                <div className="bg-white border border-slate-200/80 rounded-xl p-4 space-y-3 shadow-sm hover:shadow-md transition-all">
                  <div className="flex items-center justify-between">
                    <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">BHARATKOSH REVENUE</span>
                    <div className="w-8 h-8 rounded-lg bg-emerald-50 border border-emerald-200 flex items-center justify-center text-emerald-600">
                      <FileCheck className="w-4.5 h-4.5" />
                    </div>
                  </div>
                  <div>
                    <h3 className="text-xs text-slate-600 font-bold">Penalties Recovered</h3>
                    <div className="flex items-baseline space-x-2 mt-1">
                      <span className="text-2xl font-black text-emerald-600 tracking-tight">
                        {stats?.penaltiesRecoveredRupees ?? '₹0.00 Cr'}
                      </span>
                      <span className="text-[10px] font-bold text-blue-800 bg-blue-50 px-1.5 py-0.5 rounded border border-blue-200">
                        100% Audit Track
                      </span>
                    </div>
                  </div>
                  
                  {/* HIGH VISIBILITY PROMINENT SUB-METRICS */}
                  <div className="pt-2.5 border-t border-slate-200/80 grid grid-cols-2 gap-2 text-xs">
                    <div className="bg-emerald-50/70 border border-emerald-200 p-2.5 rounded-lg space-y-1">
                      <span className="text-[11px] font-bold text-emerald-900 block leading-tight">Citizen Rewards Paid</span>
                      <div className="text-sm font-black text-emerald-700">{(stats?.citizenRewardsPaidPoints ?? 0).toLocaleString('en-IN')} pts</div>
                      <span className="text-[10px] font-bold text-emerald-800 bg-emerald-100/80 px-1.5 py-0.5 rounded inline-block">Direct Credited</span>
                    </div>
                    <div className="bg-amber-50/70 border border-amber-200 p-2.5 rounded-lg space-y-1">
                      <span className="text-[11px] font-bold text-amber-900 block leading-tight">Active Officers</span>
                      <div className="text-sm font-black text-amber-700">{stats?.activeOfficersCount ?? 2} Enforcers</div>
                      <span className="text-[10px] font-bold text-amber-800 bg-amber-100/80 px-1.5 py-0.5 rounded inline-block">Field Deployment</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* 3. Middle Section: Western Region District Radar (Left) + Upstream Queue (Right - LIGHT THEMED) */}
              <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
                
                {/* Western Region District Radar (Left Box - 5 columns) */}
                <div className="lg:col-span-5 bg-white border border-slate-200/80 rounded-xl p-5 space-y-4 shadow-sm flex flex-col justify-between">
                  <div>
                    <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                      <div>
                        <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">DIVISIONAL SURVEILLANCE</span>
                        <div className="flex items-center space-x-2 mt-0.5">
                          <h3 className="text-base font-black text-slate-900">Western Region District Radar</h3>
                          {radarAlertFilter !== 'ALL' && (
                            <span className="bg-amber-100 text-amber-800 border border-amber-300 font-bold text-[10px] px-2 py-0.5 rounded flex items-center gap-1">
                              Filter: {radarAlertFilter}
                              <button onClick={() => setRadarAlertFilter('ALL')} className="hover:text-rose-600 font-bold">×</button>
                            </span>
                          )}
                        </div>
                      </div>
                      <button 
                        onClick={() => {
                          setTempRadarFilter(radarAlertFilter);
                          setActiveModal('FILTER_RADAR');
                        }}
                        className="p-2 rounded-lg bg-slate-50 hover:bg-slate-100 border border-slate-200 text-slate-600 transition-all cursor-pointer"
                        title="Radar Filter Options"
                      >
                        <SlidersHorizontal className="w-4 h-4" />
                      </button>
                    </div>

                    <p className="text-[11px] text-slate-500 mt-2 leading-relaxed">
                      Real-time compliance near-rating computed via automated inspection panchnama submissions across divisional metrology labs.
                    </p>

                    {/* Multi-Column District Items dynamically filtered */}
                    <div className="space-y-3 mt-4">
                      {displayedRadarRegions.length === 0 ? (
                        <div className="text-center p-6 bg-slate-50 border border-dashed border-slate-200 rounded-lg text-xs text-slate-500">
                          No divisions match the filter &quot;{radarAlertFilter}&quot;.
                          <button onClick={() => setRadarAlertFilter('ALL')} className="block mx-auto text-amber-700 font-bold underline mt-1 cursor-pointer">
                            Reset Filter
                          </button>
                        </div>
                      ) : (
                        displayedRadarRegions.map((item, idx) => (
                          <div key={idx} className="bg-slate-50 border border-slate-200/90 rounded-lg p-3 space-y-2.5 hover:bg-slate-100/50 transition-all">
                            <div className="flex items-center justify-between">
                              <div className="flex items-center space-x-2">
                                <span className={`w-2 h-2 rounded-full ${item.alertColor}`}></span>
                                <span className="font-black text-slate-900 text-xs">{item.region}</span>
                              </div>
                              <span className={`${item.badgeColor} font-extrabold text-[10px] px-2 py-0.5 rounded border`}>
                                {item.alertLevel}
                              </span>
                            </div>

                            <div className="grid grid-cols-4 gap-2 text-center text-xs pt-1 border-t border-slate-200/60">
                              <div>
                                <span className="text-[9px] text-slate-400 font-bold block uppercase">Inspections</span>
                                <span className="font-bold text-slate-900">{item.inspections}</span>
                              </div>
                              <div>
                                <span className="text-[9px] text-slate-400 font-bold block uppercase">Violations</span>
                                <span className={`font-bold ${item.violationColor}`}>{item.violations}</span>
                              </div>
                              <div>
                                <span className="text-[9px] text-slate-400 font-bold block uppercase">Recovery</span>
                                <span className="font-bold text-amber-700 font-mono">₹{item.recoveryRupees}</span>
                              </div>
                              <div>
                                <span className="text-[9px] text-slate-400 font-bold block uppercase">SLA Rate</span>
                                <span className="font-bold text-emerald-700 bg-emerald-100 px-1.5 py-0.5 rounded text-[10px]">{item.slaRatePercent}</span>
                              </div>
                            </div>
                          </div>
                        ))
                      )}
                    </div>
                  </div>

                  {/* Footer bar with Leaflet Spatial Map Option */}
                  <div className="pt-3 mt-4 border-t border-slate-100 flex flex-col sm:flex-row items-center justify-between gap-2 text-xs">
                    <span className="text-slate-500 text-[11px]">Divisional Cadence: <strong>14 Active Flying Squads</strong></span>
                    
                    <div className="flex items-center space-x-2">
                      {/* Interactive Leaflet GIS Spatial Map Button requested by user */}
                      <button 
                        onClick={() => setActiveModal('LEAFLET_MAP')}
                        className="bg-[#0D1F3C] hover:bg-[#081427] text-amber-400 font-extrabold text-[11px] px-3 py-1.5 rounded-lg shadow transition-all flex items-center space-x-1.5 cursor-pointer"
                        title="Open Interactive Leaflet GIS Spatial Radar Map (Image 2)"
                      >
                        <MapPin className="w-3.5 h-3.5 text-emerald-400" />
                        <span>Interactive Leaflet Map 🗺️</span>
                      </button>

                      <button 
                        onClick={() => setActiveModal('DISTRICT_LEDGER')}
                        className="text-amber-700 font-bold hover:text-amber-800 hover:underline flex items-center gap-1 text-[11px] cursor-pointer"
                      >
                        <span>Full Ledger</span>
                        <ArrowRight className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>
                </div>

                {/* Upstream Manufacturer / Wholesaler Traceback Queue (Right Box - 7 columns - LIGHT THEMED matching Image 1) */}
                <div className="lg:col-span-7 bg-white border border-slate-200/80 rounded-xl p-5 space-y-4 shadow-sm text-slate-900">
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-slate-100 pb-3">
                    <div className="flex items-center space-x-2">
                      <span className="bg-rose-700 text-white font-extrabold text-[9px] px-1.5 py-0.5 rounded tracking-wide">
                        GHPS 24 CORE
                      </span>
                      <span className="text-[11px] text-slate-400">Packaged Commodities Rules (Rule 6)</span>
                    </div>
                    <span className="bg-slate-100 text-slate-700 border border-slate-300 font-bold text-[10px] px-2.5 py-1 rounded-full w-fit">
                      Auto-Linked: {supplyChainLinks.length} Targets
                    </span>
                  </div>

                  <h3 className="text-base font-black text-slate-900">
                    Upstream Manufacturer / Wholesaler Traceback Queue
                  </h3>

                  {/* Statutory Traceback Automation Banner */}
                  <div className="bg-blue-50/70 border border-blue-200/80 rounded-lg p-3 text-[11px] text-slate-700 leading-relaxed flex items-start space-x-2.5">
                    <Sparkles className="w-4 h-4 text-blue-600 shrink-0 mt-0.5" />
                    <div>
                      <strong className="text-slate-900 font-bold">Statutory Traceback Automation:</strong> When an inspection at a local retail counter identifies non-compliant net weight, missing MRP or undeclared importer details, Maap-Tol Setu instantly binds the manufacturer/packager PAN & factory address, auto-raising raid warrants to the relevant Zonal Metrology Office.
                    </div>
                  </div>

                  {/* Dynamic Queue Item Cards (LIGHT THEMED) */}
                  <div className="space-y-3">
                    {supplyChainLinks.length === 0 ? (
                      <div className="bg-slate-50 border border-slate-200/90 rounded-lg p-6 text-center text-xs text-slate-500">
                        No supply chain tracebacks found.
                      </div>
                    ) : (
                      supplyChainLinks.map((link) => (
                        <div key={link.id} className="bg-slate-50 border border-slate-200/90 rounded-lg p-4 space-y-3 hover:bg-slate-100/60 transition-all">
                          <div className="flex flex-wrap items-center justify-between gap-2">
                            <div className="flex items-center space-x-2">
                              {link.status === 'RAID_SCHEDULED' ? (
                                <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
                              ) : (
                                <span className="w-2 h-2 rounded-full bg-rose-600 animate-ping"></span>
                              )}
                              <span className={`font-extrabold text-xs ${
                                link.status === 'RAID_SCHEDULED' ? 'text-emerald-700' : 'text-rose-700'
                              }`}>
                                {link.status === 'RAID_SCHEDULED' ? 'RAID SQUAD DEPLOYED' : 'ACTION MANDATE: RAID WARRANT'}
                              </span>
                              <span className="text-slate-400 text-xs font-mono">Ref #{link.id}</span>
                            </div>
                            <span className={`font-bold text-[10px] px-2 py-0.5 rounded border ${
                              link.status === 'RAID_SCHEDULED'
                                ? 'bg-emerald-100 text-emerald-800 border-emerald-300'
                                : link.status === 'ASSIGNED'
                                ? 'bg-blue-100 text-blue-800 border-blue-300'
                                : 'bg-amber-100 text-amber-800 border-amber-300'
                            }`}>
                              {link.status === 'RAID_SCHEDULED' ? 'Raid Deployed' : link.status === 'ASSIGNED' ? 'Assigned' : 'Pending Control Assignment'}
                            </span>
                          </div>

                          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs bg-white p-3 rounded-lg border border-slate-200">
                            <div>
                              <span className="text-[10px] text-slate-400 font-bold block uppercase">Retailer Caught</span>
                              <span className="font-bold text-slate-900">{link.sourceBusinessName}</span>
                              <span className="text-[10px] text-slate-500 block">{link.sourceAddress}</span>
                            </div>
                            <div className="border-t sm:border-t-0 sm:border-l border-slate-100 pt-2 sm:pt-0 sm:pl-3">
                              <span className="text-[10px] text-amber-700 font-bold block uppercase">Identified Upstream Manufacturer</span>
                              <span className="font-black text-slate-900">{link.namedBusinessName}</span>
                              <span className="text-[10px] text-slate-500 block">{link.namedBusinessAddress}</span>
                            </div>
                          </div>

                          <div className="text-xs text-slate-700">
                            <strong className="text-rose-700">Contraband Parameter:</strong> {link.contrabandParameter}
                          </div>

                          <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3 pt-1">
                            {link.status === 'RAID_SCHEDULED' ? (
                              <>
                                <div className="text-xs text-slate-600 font-semibold">
                                  Assigned Officer: <strong className="text-slate-900 font-bold">{link.assignedInspectorName || 'Inspector Rajesh Shinde'}</strong>
                                </div>
                                <span className="bg-emerald-50 border border-emerald-300 text-emerald-800 font-bold text-xs px-3.5 py-1.5 rounded-lg shadow-xs flex items-center space-x-1.5">
                                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                                  <span>Warrant Issued • Raid Mandate Active</span>
                                </span>
                              </>
                            ) : (
                              <>
                                <select 
                                  value={selectedInspector}
                                  onChange={(e) => setSelectedInspector(e.target.value)}
                                  className="bg-white border border-slate-300 rounded-lg px-3 py-1.5 text-xs text-slate-800 font-semibold focus:outline-none focus:border-rose-600"
                                >
                                  {inspectors.map((insp) => (
                                    <option key={insp.id} value={insp.id}>
                                      {insp.name} — {insp.jurisdiction}
                                    </option>
                                  ))}
                                </select>

                                <button 
                                  onClick={() => {
                                    setSelectedRaidTarget(link);
                                    setActiveModal('RAID_DISPATCH');
                                  }}
                                  className="bg-rose-700 hover:bg-rose-800 text-white font-black text-xs px-4 py-2 rounded-lg shadow transition-all flex items-center justify-center space-x-1.5 cursor-pointer"
                                >
                                  <Zap className="w-3.5 h-3.5 fill-current" />
                                  <span>Dispatch Surprise Raid</span>
                                </button>
                              </>
                            )}
                          </div>
                        </div>
                      ))
                    )}
                  </div>

                  {/* Footer link matching Image 1 */}
                  <div className="pt-3 border-t border-slate-100 flex items-center justify-between text-xs">
                    <span className="text-slate-500 text-[11px]">Automatic upstream matching powered by GSTN & Legal Metrology e-Registry</span>
                    <span className="text-slate-500 font-semibold text-[11px] flex items-center gap-1">
                      <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
                      <span>Rule 6 GSTN Automated Cross-Verification Active</span>
                    </span>
                  </div>
                </div>

              </div>

              {/* 4. Section 65B Digital Evidence Verification & Seizure Panchnama Registry (Table at Bottom - LIGHT THEMED matching Image 1) */}
              <div className="bg-white border border-slate-200/80 rounded-xl p-5 space-y-4 shadow-sm">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-slate-100 pb-3">
                  <div>
                    <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">LIVE ADJUDICATION QUEUE</span>
                    <h3 className="text-base font-black text-slate-900">
                      Section 65B Digital Evidence Verification & Seizure Panchnama Registry
                    </h3>
                  </div>

                  {/* Table Search & Download controls */}
                  <div className="flex items-center space-x-3">
                    <div className="relative">
                      <Search className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                      <input 
                        type="text"
                        value={searchDinQuery}
                        onChange={(e) => setSearchDinQuery(e.target.value)}
                        placeholder="Filter by PAN / Notice DIN..."
                        className="bg-slate-50 border border-slate-300 rounded-lg pl-8 pr-3 py-1.5 text-xs text-slate-800 placeholder-slate-400 focus:outline-none focus:border-amber-500 focus:bg-white w-56"
                      />
                    </div>

                    <button 
                      onClick={() => showToast('Exporting Section 65B Registry Dossiers (PDF/CSV)...')}
                      className="p-2 rounded-lg bg-slate-50 hover:bg-slate-100 border border-slate-200 text-slate-600 transition-all cursor-pointer"
                      title="Download Registry Dossiers"
                    >
                      <Download className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs text-slate-700">
                    <thead className="bg-slate-50 text-slate-500 text-[10px] uppercase font-bold tracking-wider border-b border-slate-200">
                      <tr>
                        <th className="p-3">EVIDENCE HASH & DIN</th>
                        <th className="p-3">OFFENDING COMMERCIAL ENTITY</th>
                        <th className="p-3">STATUTORY INFRINGEMENT</th>
                        <th className="p-3">FIELD OFFICER (GPS TIMESTAMP)</th>
                        <th className="p-3">COMPOUNDING FINE</th>
                        <th className="p-3">ADJUDICATION STATUS</th>
                        <th className="p-3 text-right">CONTROLLER ACTION</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {notices.length === 0 ? (
                        <tr>
                          <td colSpan={7} className="p-6 text-center text-xs text-slate-500">
                            No evidence or seizure records currently in registry.
                          </td>
                        </tr>
                      ) : (
                        notices
                          .filter((n) => !searchDinQuery || n.id.toLowerCase().includes(searchDinQuery.toLowerCase()) || n.businessName.toLowerCase().includes(searchDinQuery.toLowerCase()) || (n.gstin && n.gstin.toLowerCase().includes(searchDinQuery.toLowerCase())))
                          .map((n) => (
                            <tr key={n.id} className="hover:bg-slate-50/80 transition-all">
                              <td className="p-3 font-mono">
                                <div className="font-bold text-slate-900">{n.dinNumber}</div>
                                <div className="text-[10px] text-slate-400 font-mono">ID: {n.id}</div>
                              </td>
                              <td className="p-3">
                                <div className="font-bold text-slate-900">{n.businessName}</div>
                                <div className="text-[10px] text-slate-500 font-mono">GSTIN: {n.gstin}</div>
                              </td>
                              <td className="p-3">
                                <div className="font-bold text-rose-600 text-xs">
                                  {n.sectionRefs?.[0] || 'Section 36(1)'}
                                </div>
                                <div className="text-[10px] text-slate-500">{n.violatingProduct}</div>
                              </td>
                              <td className="p-3">
                                <div className="font-semibold text-slate-800">Inspector Rajesh Shinde</div>
                                <div className="text-[10px] text-slate-400 font-mono">
                                  {new Date(n.issuedDate).toLocaleString()}
                                </div>
                              </td>
                              <td className="p-3 font-mono">
                                <div className="font-black text-slate-900 text-sm">
                                  ₹{(n.penaltyAmount || 25000).toLocaleString('en-IN')}
                                </div>
                                <div className="text-[10px] text-slate-500">{n.offenceTier}</div>
                              </td>
                              <td className="p-3">
                                <span className={`font-bold text-[10px] px-2 py-0.5 rounded border ${
                                  n.status === 'APPROVED' ? 'bg-emerald-100 text-emerald-800 border-emerald-300' :
                                  n.status === 'REJECTED' ? 'bg-rose-100 text-rose-800 border-rose-300' :
                                  'bg-amber-100 text-amber-800 border-amber-300'
                                }`}>
                                  {n.status === 'APPROVED' ? 'Compounded' : n.status === 'REJECTED' ? 'Prosecution' : 'Notice Issued'}
                                </span>
                              </td>
                              <td className="p-3 text-right">
                                {n.status === 'APPROVED' ? (
                                  <button 
                                    onClick={() => showToast(`Opening Compounded Order #${n.id}...`)}
                                    className="bg-emerald-50 hover:bg-emerald-100 border border-emerald-300 text-emerald-900 font-bold text-xs px-3.5 py-1.5 rounded-lg shadow-sm transition-all cursor-pointer"
                                  >
                                    View Order
                                  </button>
                                ) : (
                                  <button 
                                    onClick={() => {
                                      setSelectedNoticeId(n.id);
                                      setActiveModal('DSC_SIGN');
                                    }}
                                    className="bg-[#0D1F3C] hover:bg-[#081427] text-white font-bold text-xs px-3.5 py-1.5 rounded-lg shadow transition-all cursor-pointer"
                                  >
                                    Sign Compounding Order
                                  </button>
                                )}
                              </td>
                            </tr>
                          ))
                      )}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* 5. Bottom Emergency Command Directives Banner */}
              <div className="bg-blue-50/70 border border-blue-200 rounded-xl p-4 flex flex-col md:flex-row items-center justify-between gap-4 shadow-sm">
                <div className="flex items-center space-x-3">
                  <div className="w-10 h-10 rounded-xl bg-[#0D1F3C] text-amber-400 flex items-center justify-center shrink-0 shadow-md">
                    <ShieldCheck className="w-6 h-6" />
                  </div>
                  <div>
                    <h4 className="text-sm font-black text-slate-900">Controller General Emergency Command Directives</h4>
                    <p className="text-xs text-slate-600">
                      Statutory executive powers under Section 29 (Power of inspection, search and seizure across inter-state supply lines).
                    </p>
                  </div>
                </div>

                <div className="flex flex-wrap items-center gap-3">
                  <button 
                    onClick={() => setControllerTab('COMPOUNDING_QUEUE')}
                    className="bg-[#0D1F3C] hover:bg-[#081427] text-amber-400 font-black text-xs px-4 py-2 rounded-lg shadow-md flex items-center space-x-2 transition-all cursor-pointer"
                  >
                    <ShieldAlert className="w-4 h-4 text-amber-400" />
                    <span>Open Case Queue ({notices.length})</span>
                  </button>
                  <button 
                    onClick={() => setControllerTab('SUPPLY_CHAIN')}
                    className="bg-white hover:bg-slate-50 border border-slate-300 text-slate-800 font-bold text-xs px-4 py-2 rounded-lg shadow-sm flex items-center space-x-1.5 transition-all cursor-pointer"
                  >
                    <GitMerge className="w-3.5 h-3.5 text-amber-600" />
                    <span>Upstream Traceback</span>
                  </button>
                </div>
              </div>

            </div>
          )}

          {/* Controller Compounding Queue Tab */}
          {isController && controllerTab === 'COMPOUNDING_QUEUE' && (
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 max-w-7xl mx-auto font-sans">
              {/* Left Column: Compounding Orders Approval Desk */}
              <div className="lg:col-span-4 bg-white border border-slate-200 rounded-xl p-4 space-y-4 shadow-sm flex flex-col justify-between">
                <div className="space-y-3">
                  {/* Top Header & Devanagari Subtitle */}
                  <div>
                    <div className="flex items-center justify-between">
                      <span className="text-[10px] text-amber-800 font-bold bg-amber-100 px-2 py-0.5 rounded border border-amber-300 uppercase">
                        SECTION 48 ADJUDICATION
                      </span>
                      <span className="text-[10px] text-slate-500 font-mono">LM ACT 2009 & PCR 2011</span>
                    </div>
                    <h2 className="text-base font-black text-slate-900 mt-1">Compounding Orders Approval Desk</h2>
                    <p className="text-[11px] text-slate-500 font-medium">
                      (प्रशमन आदेशसमीक्षा एवं न्यायिक प्रकलन)
                    </p>
                  </div>

                  {/* Summary Stat Badges */}
                  <div className="grid grid-cols-3 gap-1.5 text-center text-[10px] font-bold">
                    <div className="bg-amber-50 text-amber-800 border border-amber-300 rounded p-1.5">
                      <span className="block font-black text-xs">18</span>
                      <span>Pending DSC</span>
                    </div>
                    <div className="bg-rose-50 text-rose-800 border border-rose-200 rounded p-1.5">
                      <span className="block font-black text-xs">4</span>
                      <span>Habitual CJM</span>
                    </div>
                    <div className="bg-emerald-50 text-emerald-800 border border-emerald-200 rounded p-1.5">
                      <span className="block font-black text-xs">12</span>
                      <span>Executed Today</span>
                    </div>
                  </div>

                  {/* Filter Search Input */}
                  <div className="relative">
                    <Search className="w-3.5 h-3.5 absolute left-2.5 top-1/2 -translate-y-1/2 text-slate-400" />
                    <input
                      type="text"
                      value={queueSearch}
                      onChange={(e) => setQueueSearch(e.target.value)}
                      placeholder="Filter by Case No, Merchant, Barcode... (Ctrl+K)"
                      className="w-full bg-slate-50 border border-slate-300 rounded-lg pl-8 pr-3 py-1.5 text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:border-amber-500"
                    />
                  </div>

                  {/* Filter Pill Buttons */}
                  <div className="flex flex-wrap gap-1 text-[10px] font-bold">
                    <button
                      onClick={() => setQueueFilter('ALL')}
                      className={`px-2.5 py-1 rounded transition-all ${
                        queueFilter === 'ALL'
                          ? 'bg-slate-900 text-white'
                          : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
                      }`}
                    >
                      All (16)
                    </button>
                    <button
                      onClick={() => setQueueFilter('FIRST_OFFENCE')}
                      className={`px-2.5 py-1 rounded transition-all ${
                        queueFilter === 'FIRST_OFFENCE'
                          ? 'bg-blue-700 text-white'
                          : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
                      }`}
                    >
                      First Offence (14)
                    </button>
                    <button
                      onClick={() => setQueueFilter('HABITUAL')}
                      className={`px-2.5 py-1 rounded transition-all ${
                        queueFilter === 'HABITUAL'
                          ? 'bg-rose-700 text-white'
                          : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
                      }`}
                    >
                      Habitual (4)
                    </button>
                    <button
                      onClick={() => setQueueFilter('HIGH_VALUE')}
                      className={`px-2.5 py-1 rounded transition-all ${
                        queueFilter === 'HIGH_VALUE'
                          ? 'bg-amber-600 text-white'
                          : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
                      }`}
                    >
                      &gt; ₹1,00,000
                    </button>
                  </div>

                  {/* Rich Dossier Cards List (Light Theme as Image 1, Info as Image 2) */}
                  <div className="space-y-2 max-h-[460px] overflow-y-auto pr-1">
                    {filteredNotices.length === 0 ? (
                      <div className="p-6 text-center text-xs text-slate-500">
                        No statutory notices found matching filter.
                      </div>
                    ) : (
                      filteredNotices.map((n) => (
                        <div
                          key={n.id}
                          onClick={() => setSelectedNoticeId(n.id)}
                          className={`p-3 rounded-xl border transition-all cursor-pointer space-y-1.5 ${
                            selectedNoticeId === n.id
                              ? 'bg-amber-50/80 border-amber-500 shadow-md ring-1 ring-amber-500/40'
                              : 'bg-slate-50 border-slate-200 hover:bg-slate-100'
                          }`}
                        >
                          <div className="flex items-center justify-between">
                            <span className="font-mono text-xs font-black text-amber-800">{n.id}</span>
                            <div className="flex items-center space-x-1">
                              <span className={`text-[9px] font-bold px-1.5 py-0.5 rounded ${
                                (n.paymentStatus === 'PAID' || n.status === 'PAID') ? 'bg-emerald-100 text-emerald-800 border border-emerald-300' :
                                n.status === 'APPROVED' ? 'bg-teal-100 text-teal-800' :
                                n.status === 'REJECTED' ? 'bg-rose-100 text-rose-800' :
                                'bg-amber-100 text-amber-800 border border-amber-300'
                              }`}>
                                {(n.paymentStatus === 'PAID' || n.status === 'PAID') ? 'PAID / SETTLED' :
                                 n.status === 'APPROVED' ? 'Compounded' :
                                 n.status === 'REJECTED' ? 'Prosecution' :
                                 'UNPAID / Review'}
                              </span>
                              <span className="text-xs font-black text-emerald-700 font-mono">
                                ₹{(n.penaltyAmount || 25000).toLocaleString('en-IN')}
                              </span>
                            </div>
                          </div>
                          <div className="text-xs font-bold text-slate-900 leading-tight">{n.violatingProduct}</div>
                          <div className="text-[10px] text-slate-500">{n.businessName} • GSTIN: {n.gstin}</div>
                          <div className="flex items-center space-x-1.5 text-[9px] font-bold pt-1">
                            <span className="bg-rose-100 text-rose-700 px-1.5 py-0.5 rounded border border-rose-200">
                              {n.sectionRefs?.[0] || 'Rule 6 & Sec 36(1)'}
                            </span>
                            <span className="text-amber-800 font-semibold">{n.type}</span>
                          </div>
                          <div className="text-[9px] font-mono text-slate-500 pt-0.5 border-t border-slate-200/60 flex items-center justify-between">
                            <span>Case: {n.caseId}</span>
                            <span>Due: {new Date(n.deadlineDate).toLocaleDateString()}</span>
                          </div>
                        </div>
                      ))
                    )}
                  </div>
                </div>

                {/* COMPOUNDING FUND COLLECTIONS (Bottom Box matching Image 2 in Light Theme) */}
                <div className="bg-slate-900 text-white p-3.5 rounded-xl border border-slate-800 shadow-md mt-3 flex items-center justify-between">
                  <div>
                    <div className="text-[10px] text-amber-400 font-bold uppercase tracking-wider">COMPOUNDING FUND COLLECTIONS</div>
                    <div className="text-lg font-black text-white font-mono">₹14,85,000</div>
                    <div className="text-[9px] text-slate-300">Direct credit via Bharatkosh CFR Account</div>
                  </div>
                  <button
                    onClick={() => showToast('Opening Bharatkosh CFR Live Settlement Ledger...')}
                    className="w-9 h-9 rounded-lg bg-amber-500 hover:bg-amber-400 text-slate-950 flex items-center justify-center font-bold shadow cursor-pointer shrink-0"
                    title="View Bharatkosh Settlement Ledger"
                  >
                    <Landmark className="w-5 h-5" />
                  </button>
                </div>
              </div>

              {/* Right Main Column: Generated Statutory Notices (1 below other) + Case Adjudication */}
              {activeNotice && (
                <div className="lg:col-span-8 space-y-5">
                  {/* Case Level Dossier Header */}
                  <div className="bg-white border border-slate-200/80 rounded-xl p-5 shadow-sm flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                    <div>
                      <div className="flex items-center space-x-2">
                        <span className="bg-[#0D1F3C] text-amber-400 font-mono font-bold text-xs px-2.5 py-1 rounded">
                          Case #{activeNotice.caseId || activeNotice.id}
                        </span>
                        <span className="bg-blue-100 text-blue-900 border border-blue-200 text-xs font-bold px-2.5 py-0.5 rounded">
                          {displayedNotices.length} Statutory Notice{displayedNotices.length > 1 ? 's' : ''} Generated
                        </span>
                      </div>
                      <h2 className="text-base font-black text-slate-900 mt-1">
                        {activeNotice.businessName} <span className="text-xs font-normal text-slate-500">• GSTIN: {activeNotice.gstin || 'N/A'}</span>
                      </h2>
                    </div>

                    <div className="flex items-center space-x-2">
                      <span className={`text-xs font-bold px-3 py-1 rounded border ${
                        (activeNotice.paymentStatus === 'PAID' || activeNotice.status === 'PAID')
                          ? 'bg-emerald-100 text-emerald-800 border-emerald-300'
                          : 'bg-amber-100 text-amber-800 border-amber-300'
                      }`}>
                        {(activeNotice.paymentStatus === 'PAID' || activeNotice.status === 'PAID') ? 'STATUS: PAID' : 'STATUS: UNPAID'}
                      </span>
                      <button
                        onClick={() => setActiveModal('DETAILED_DOSSIER_PDF')}
                        className="bg-[#0D1F3C] hover:bg-[#081427] text-white font-bold text-xs px-3.5 py-1.5 rounded-lg shadow transition-all flex items-center space-x-1.5 cursor-pointer"
                        title="View Full Statutory Case Dossier PDF"
                      >
                        <FileText className="w-3.5 h-3.5 text-amber-400" />
                        <span>View Dossier (PDF)</span>
                        <Eye className="w-3 h-3 text-emerald-400" />
                      </button>
                    </div>
                  </div>

                  {/* Section Title: Generated Notices Stacking 1 Below Other */}
                  <div className="flex items-center justify-between pt-1">
                    <div className="flex items-center space-x-2">
                      <FileText className="w-4 h-4 text-amber-600" />
                      <h3 className="text-sm font-black text-slate-900 uppercase tracking-wide">
                        Statutory Notices Generated for this Case ({displayedNotices.length})
                      </h3>
                    </div>
                    <span className="text-[11px] font-mono text-slate-500">
                      Enforcement u/s 15 & 48 Legal Metrology Act, 2009
                    </span>
                  </div>

                  {/* Notices List: Displayed 1 below other */}
                  <div className="space-y-5">
                    {displayedNotices.map((notice, nIdx) => (
                      <div key={notice.id || nIdx} className="bg-white border-2 border-slate-200 hover:border-slate-300 transition-colors rounded-2xl p-6 space-y-5 shadow-sm font-sans relative">
                        {/* Notice Masthead & Title */}
                        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-slate-200 pb-4">
                          <div className="flex items-start space-x-3">
                            <div className={`p-2.5 rounded-xl text-white shadow-sm mt-0.5 ${
                              notice.type === 'COMPOUNDED' ? 'bg-[#0D1F3C]' :
                              notice.type === 'SEIZURE' ? 'bg-rose-700' :
                              notice.type === 'PANCHANAMA' ? 'bg-indigo-700' :
                              'bg-amber-600'
                            }`}>
                              {notice.type === 'COMPOUNDED' ? <Gavel className="w-5 h-5 text-amber-400" /> :
                               notice.type === 'SEIZURE' ? <ShieldAlert className="w-5 h-5 text-white" /> :
                               <FileText className="w-5 h-5 text-white" />}
                            </div>
                            <div>
                              <div className="flex items-center gap-2">
                                <span className={`text-xs font-black px-2.5 py-0.5 rounded uppercase tracking-wider border ${
                                  notice.type === 'COMPOUNDED' ? 'bg-[#0D1F3C] text-amber-400 border-amber-500/40' :
                                  notice.type === 'SEIZURE' ? 'bg-rose-100 text-rose-800 border-rose-300' :
                                  notice.type === 'PANCHANAMA' ? 'bg-indigo-100 text-indigo-800 border-indigo-300' :
                                  'bg-amber-100 text-amber-900 border-amber-300'
                                }`}>
                                  {notice.type === 'COMPOUNDED' ? 'Statutory Compounding Order u/s 48' :
                                   notice.type === 'SEIZURE' ? 'Seizure Inventory Memo (Form V) u/s 15' :
                                   notice.type === 'PANCHANAMA' ? 'Spot Witness Panchanama Record' :
                                   'Statutory Improvement Notice u/s 15'}
                                </span>
                                <span className="text-[10px] text-slate-500 font-mono font-bold">
                                  Notice {nIdx + 1} of {displayedNotices.length}
                                </span>
                              </div>
                              <h3 className="text-base font-black text-slate-900 mt-1">
                                {notice.violatingProduct} — Notice #{notice.id}
                              </h3>
                              <p className="text-[11px] text-slate-500 font-mono">
                                DIN: {notice.dinNumber} • Case Ref: {notice.caseId} • Section 36(1) PCR 2011
                              </p>
                            </div>
                          </div>

                          <div className="flex items-center space-x-2 shrink-0">
                            <span className={`text-[11px] font-bold px-2.5 py-1 rounded border ${
                              (notice.paymentStatus === 'PAID' || notice.status === 'PAID')
                                ? 'bg-emerald-100 text-emerald-800 border-emerald-300'
                                : 'bg-amber-50 text-amber-800 border-amber-300'
                            }`}>
                              {(notice.paymentStatus === 'PAID' || notice.status === 'PAID') ? 'SETTLED / PAID' : 'COMPLIANCE PENDING'}
                            </span>

                            <button
                              onClick={() => handleDownloadNoticePdf(notice)}
                              className="bg-[#0D1F3C] hover:bg-[#081427] text-white font-bold text-xs px-3.5 py-1.5 rounded-lg shadow transition-all flex items-center space-x-1.5 cursor-pointer"
                              title="Download Official Notice PDF"
                            >
                              <Download className="w-3.5 h-3.5 text-amber-400" />
                              <span>Download PDF</span>
                            </button>
                          </div>
                        </div>

                        {/* Notice Key Parameters Grid */}
                        <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-xs bg-slate-50 p-3.5 rounded-xl border border-slate-200">
                          <div>
                            <div className="text-[10px] text-slate-400 uppercase font-bold tracking-wider">ACCUSED ESTABLISHMENT</div>
                            <div className="font-bold text-slate-900 mt-0.5">{notice.businessName}</div>
                            <div className="text-[10px] text-slate-500 font-mono">GSTIN: {notice.gstin || 'N/A'}</div>
                          </div>
                          <div>
                            <div className="text-[10px] text-slate-400 uppercase font-bold tracking-wider">VIOLATING COMMODITY</div>
                            <div className="font-bold text-slate-900 mt-0.5">{notice.violatingProduct}</div>
                            <div className="text-[10px] text-slate-500">Packaged Commodity Standard Breach</div>
                          </div>
                          <div>
                            <div className="text-[10px] text-slate-400 uppercase font-bold tracking-wider">STATUTORY TIMELINE</div>
                            <div className="font-bold text-slate-800 mt-0.5">Issued: {new Date(notice.issuedDate).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}</div>
                            <div className="text-[10px] text-rose-700 font-bold">Due by: {new Date(notice.deadlineDate).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}</div>
                          </div>
                          <div>
                            <div className="text-[10px] text-slate-400 uppercase font-bold tracking-wider">PENALTY AMOUNT</div>
                            <div className="font-black text-emerald-600 text-sm mt-0.5">₹{(notice.penaltyAmount || 25000).toLocaleString('en-IN')}.00</div>
                            <div className="text-[10px] text-slate-500 font-mono">Statutory Compounding Tariff</div>
                          </div>
                        </div>

                        {/* Violations Table */}
                        <div className="space-y-2">
                          <div className="flex items-center justify-between text-xs font-bold text-slate-900">
                            <span className="flex items-center gap-1.5">
                              <AlertTriangle className="w-3.5 h-3.5 text-amber-600" />
                              <span>Statutory Non-Compliance & Detected Violations</span>
                            </span>
                            <span className="text-[10px] text-slate-500 font-mono">Legal Metrology Act, 2009 Section 36(1)</span>
                          </div>

                          {notice.violations && notice.violations.length > 0 ? (
                            <div className="border border-slate-200 rounded-xl overflow-hidden text-xs">
                              <table className="w-full text-left">
                                <thead className="bg-slate-100 text-slate-600 font-bold text-[10px] uppercase border-b border-slate-200">
                                  <tr>
                                    <th className="p-2.5">Rule / Section</th>
                                    <th className="p-2.5">Violation Title</th>
                                    <th className="p-2.5">Statutory Defect Description</th>
                                    <th className="p-2.5 text-right">Severity</th>
                                  </tr>
                                </thead>
                                <tbody className="divide-y divide-slate-100 bg-white">
                                  {notice.violations.map((v, vIdx) => (
                                    <tr key={v.id || vIdx} className="hover:bg-slate-50">
                                      <td className="p-2.5 font-mono font-bold text-rose-700">{v.ruleSection || 'Rule 6 & Sec 36(1)'}</td>
                                      <td className="p-2.5 font-bold text-slate-900">{v.ruleTitle || 'Mandatory Declaration Missing'}</td>
                                      <td className="p-2.5 text-slate-600">{v.description || 'Statutory declaration non-compliant'}</td>
                                      <td className="p-2.5 text-right">
                                        <span className={`text-[9px] font-bold px-2 py-0.5 rounded border uppercase ${
                                          (v.severity || '').toLowerCase() === 'high' ? 'bg-rose-100 text-rose-800 border-rose-300' :
                                          (v.severity || '').toLowerCase() === 'medium' ? 'bg-amber-100 text-amber-800 border-amber-300' :
                                          'bg-slate-100 text-slate-800 border-slate-300'
                                        }`}>
                                          {v.severity || 'HIGH'}
                                        </span>
                                      </td>
                                    </tr>
                                  ))}
                                </tbody>
                              </table>
                            </div>
                          ) : (
                            <div className="bg-slate-50 p-3 rounded-lg border border-slate-200 text-xs text-slate-700 flex items-center justify-between">
                              <span>Section Cited: <strong>{notice.sectionRefs?.join(', ') || 'Rule 6 read with Section 36(1)'}</strong></span>
                              <span className="text-[10px] text-slate-500 font-mono">Rule 6 Mandatory Package Declarations Non-Compliance</span>
                            </div>
                          )}
                        </div>

                        {/* Official Notice Body Text */}
                        <div className="bg-amber-50/50 border border-amber-200/80 rounded-xl p-3.5 text-xs text-slate-800 space-y-1">
                          <div className="text-[10px] font-bold uppercase tracking-wider text-amber-900 flex items-center gap-1.5">
                            <FileText className="w-3 h-3 text-amber-700" />
                            <span>Official Statutory Directive Text</span>
                          </div>
                          <p className="text-slate-700 leading-relaxed font-mono text-[11px]">
                            {notice.bodyText || `Official statutory notice issued under Legal Metrology Act, 2009 for non-compliance in ${notice.violatingProduct}. The establishment is directed to correct package declarations or settle compounding penalty.`}
                          </p>
                          {notice.inspectorRemark && (
                            <div className="text-[10px] text-slate-600 pt-1 border-t border-amber-200/60 font-sans">
                              <strong>Field Inspector Finding:</strong> {notice.inspectorRemark}
                            </div>
                          )}
                        </div>

                        {/* Cryptographic Digital Signature Strip */}
                        <div className="bg-gradient-to-r from-teal-50 via-emerald-50 to-teal-50 p-3 rounded-xl border border-teal-300 flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-xs">
                          <div className="flex items-center space-x-2.5">
                            <ShieldCheck className="w-4 h-4 text-teal-700 shrink-0" />
                            <div>
                              <div className="text-teal-950 font-black text-[11px]">
                                IT Act 2000 Section 3 Cryptographically Signed Notice
                              </div>
                              <div className="text-[9px] text-teal-800 font-mono">
                                Certifying Authority: eMudhra CCA Sub-CA 2026 / DocuSign Trust Services
                              </div>
                            </div>
                          </div>
                          <div className="text-right">
                            <div className="text-[9px] text-slate-500 font-mono font-bold">SHA-256 HASH:</div>
                            <div className="text-[10px] font-mono text-emerald-900 font-bold bg-white px-2 py-0.5 rounded border border-emerald-300">
                              {(notice.digitalSignatureHash || '790b4860b9fb0d3deba6eb4c89685df4570d0a3061801b8cb2a6f6467c59f883').substring(0, 24)}…
                            </div>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>

                  {/* Controller Adjudication Remarks & Final Action Bar */}
                  <div className="bg-white border border-slate-200/80 rounded-2xl p-6 space-y-5 shadow-sm">
                    <div className="space-y-1">
                      <label className="text-xs font-bold text-slate-700 flex items-center justify-between">
                        <span>Controller Adjudication Remarks & Directive</span>
                        <span className="text-[10px] text-slate-500 font-mono">Included in Form LM-4 Order</span>
                      </label>
                      <textarea 
                        rows={3}
                        value={remarks}
                        onChange={(e) => setRemarks(e.target.value)}
                        className="w-full bg-slate-50 border border-slate-300 rounded-lg p-3 text-xs text-slate-900 font-mono focus:outline-none focus:border-amber-500"
                      />
                    </div>

                    <div className="bg-slate-50 p-4 rounded-xl border border-slate-200 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                      <div>
                        <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider">TOTAL COMPOUNDING PAYABLE</div>
                        <div className="text-2xl font-black text-emerald-600 font-mono">₹{(activeNotice.penaltyAmount || 25000).toLocaleString('en-IN')}.00</div>
                        <div className="text-[10px] text-slate-500">Merchant must deposit via Bharatkosh Challan within 15 days</div>
                      </div>
                      <div className="flex flex-wrap items-center gap-3">
                        <button 
                          onClick={handleEscalateNotice} 
                          className="bg-rose-700 hover:bg-rose-800 text-white font-bold text-xs px-4 py-2.5 rounded-lg shadow cursor-pointer flex items-center space-x-1.5"
                        >
                          <ShieldAlert className="w-4 h-4" />
                          <span>Escalate to Prosecution</span>
                        </button>
                        <button 
                          onClick={handleApproveNotice} 
                          className="bg-emerald-600 hover:bg-emerald-700 text-white font-black text-xs px-5 py-2.5 rounded-lg shadow cursor-pointer flex items-center space-x-1.5"
                        >
                          <CheckCircle2 className="w-4 h-4" />
                          <span>Approve Compounded Order (DSC)</span>
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Controller Supply Chain Tab */}
          {isController && controllerTab === 'SUPPLY_CHAIN' && (
            <div className="bg-white border border-slate-200/80 rounded-xl p-6 space-y-4 shadow-sm max-w-7xl mx-auto">
              <div className="flex justify-between items-center border-b border-slate-100 pb-3">
                <div>
                  <h2 className="text-lg font-black text-slate-900">Supply Chain Upstream Traceback Graph</h2>
                  <p className="text-xs text-slate-500">Automated e-Way Bill & GSTN Ingestion Rule Engine</p>
                </div>
                <span className="bg-emerald-100 border border-emerald-300 text-emerald-800 text-[11px] font-bold px-3 py-1.5 rounded-lg shadow-xs flex items-center gap-1.5">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                  <span>E-Way Bill & GSTN Surveillance Active</span>
                </span>
              </div>

              <div className="space-y-3">
                {supplyChainLinks.map((l) => (
                  <div key={l.id} className="p-4 bg-slate-50 border border-slate-200 rounded-xl flex flex-col sm:flex-row justify-between sm:items-center gap-3">
                    <div>
                      <div className="text-xs font-bold text-slate-900 flex items-center space-x-2">
                        <span>{l.sourceBusinessName}</span>
                        <ArrowRight className="w-4 h-4 text-amber-600" />
                        <span className="text-amber-700">{l.namedBusinessName}</span>
                      </div>
                      <div className="text-[11px] text-slate-500 mt-1">{l.contrabandParameter}</div>
                    </div>
                    <span className="bg-amber-100 text-amber-800 border border-amber-300 text-xs font-bold px-3 py-1 rounded w-fit">
                      {l.status === 'RAID_SCHEDULED' ? 'RAID SCHEDULED' : 'PENDING ASSIGNMENT'}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Controller Jurisdiction Analytics & Heatmap Tab */}
          {isController && controllerTab === 'JURISDICTION' && (
            <div className="space-y-6 max-w-7xl mx-auto font-sans">
              {/* Header Banner */}
              <div className="bg-[#0D1F3C] text-white border border-blue-900 rounded-xl p-5 shadow-md flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                  <div className="flex items-center space-x-2 text-xs text-amber-400 font-bold uppercase tracking-wider mb-1">
                    <MapPin className="w-4 h-4 text-emerald-400" />
                    <span>SURVEILLANCE & REGISTRY • STATEWIDE JURISDICTION RADAR</span>
                  </div>
                  <h1 className="text-xl md:text-2xl font-black text-white">
                    Statewide Jurisdiction Analytics & Enforcement Heatmap
                  </h1>
                  <p className="text-xs text-blue-100/80 mt-1">
                    36 Districts • Real-Time Legal Metrology Inspection Velocity, Payment Recovery & Non-Compliance Spatial Index
                  </p>
                </div>

                <div className="flex items-center space-x-3">
                  {/* Leaflet GIS Map Button requested by user */}
                  <button
                    onClick={() => setActiveModal('LEAFLET_MAP')}
                    className="bg-amber-500 hover:bg-amber-400 text-slate-950 font-black text-xs px-4 py-2.5 rounded-lg shadow-lg flex items-center space-x-2 cursor-pointer transition-all shrink-0"
                  >
                    <MapPin className="w-4 h-4" />
                    <span>Open Leaflet GIS Map 🗺️</span>
                  </button>
                  <div className="hidden xl:flex items-center space-x-2 bg-[#081427] border border-blue-800 px-3 py-2 rounded-lg text-xs">
                    <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
                    <span className="text-slate-300 font-mono text-[11px]">Backend Graph API Ready</span>
                  </div>
                </div>
              </div>

              {/* Metric Cards Grid */}
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                <div className="bg-white border border-slate-200 rounded-xl p-4 space-y-1 shadow-sm">
                  <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider">TOTAL INSPECTIONS (FY 2024-25)</div>
                  <div className="text-2xl font-black text-slate-900 font-mono">48,290</div>
                  <div className="text-[11px] text-emerald-600 font-semibold flex items-center gap-1">
                    <TrendingUp className="w-3.5 h-3.5" /> +14.2% YoY Increase across 36 Districts
                  </div>
                </div>

                <div className="bg-white border border-slate-200 rounded-xl p-4 space-y-1 shadow-sm">
                  <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider">OFFENCE SEIZURE RATIO</div>
                  <div className="text-2xl font-black text-rose-600 font-mono">14.2%</div>
                  <div className="text-[11px] text-rose-700 font-semibold">3,412 Seizure Panchanamas Executed</div>
                </div>

                <div className="bg-white border border-slate-200 rounded-xl p-4 space-y-1 shadow-sm">
                  <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider">TOTAL COMPOUNDING RECOVERED</div>
                  <div className="text-2xl font-black text-emerald-600 font-mono">₹3.84 Cr</div>
                  <div className="text-[11px] text-emerald-700 font-semibold">Direct Credit via Bharatkosh CFR</div>
                </div>

                <div className="bg-white border border-slate-200 rounded-xl p-4 space-y-1 shadow-sm">
                  <div className="text-[10px] text-slate-500 font-bold uppercase tracking-wider">ACTIVE ZONAL RADARS</div>
                  <div className="text-2xl font-black text-amber-600 font-mono">4 Zones</div>
                  <div className="text-[11px] text-slate-600 font-semibold">Western, Vidarbha, Marathwada, Northern</div>
                </div>
              </div>

              {/* Embedded Leaflet GIS Spatial Map View directly on dashboard */}
              <div className="bg-white border border-slate-200 rounded-xl p-4 space-y-3 shadow-sm">
                <div className="flex items-center justify-between border-b border-slate-100 pb-2">
                  <h3 className="text-sm font-black text-slate-900 flex items-center gap-2">
                    <MapPin className="w-4 h-4 text-emerald-600" />
                    <span>Leaflet GIS Spatial Radar & District Enforcement Map</span>
                  </h3>
                  <span className="text-[10px] bg-slate-900 text-white font-bold px-2.5 py-1 rounded">
                    Interactive WebGL / CartoDB Map
                  </span>
                </div>
                <LeafletRadarMap />
              </div>

              {/* Interactive Recharts Graphical Analytics Section */}
              <JurisdictionAnalyticsGraphs />
            </div>
          )}


        </main>
      </div>

      {/* ========================================================================= */}
      {/* ALL INTERACTIVE MODALS FOR CONTROLLER WORKABLE ACTIONS                   */}
      {/* ========================================================================= */}

      {/* 1. Raid Dispatch Modal */}
      {activeModal === 'RAID_DISPATCH' && (
        <div className="fixed inset-0 bg-slate-950/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white border border-slate-200 rounded-2xl max-w-lg w-full p-6 space-y-4 shadow-2xl animate-in fade-in zoom-in duration-200">
            <div className="flex justify-between items-center border-b border-slate-100 pb-3">
              <div className="flex items-center space-x-2 text-rose-600 font-black">
                <Zap className="w-5 h-5 fill-current" />
                <h3 className="text-base font-black text-slate-900">Authorize Surprise Raid Warrant</h3>
              </div>
              <button onClick={() => setActiveModal(null)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="bg-slate-50 p-3 rounded-lg border border-slate-200 text-xs space-y-1">
              <div><strong className="text-slate-900">Target Facility:</strong> {selectedRaidTarget?.namedBusinessName || 'Bhoomi Agro Packagers & Mills Pvt Ltd'}</div>
              <div><strong className="text-slate-900">Location:</strong> {selectedRaidTarget?.namedBusinessAddress || 'Plot C-14, MIDC Taloja, Raigad Dist.'}</div>
              <div><strong className="text-rose-600">Offence:</strong> {selectedRaidTarget?.contrabandParameter || 'Mustard Oil 1L Net Qty Shortfall (12.4% deficit)'}</div>
            </div>

            <div className="space-y-2">
              <label className="text-xs font-bold text-slate-700">Select Assignee Inspector / Flying Squad</label>
              <select 
                value={selectedInspector}
                onChange={(e) => setSelectedInspector(e.target.value)}
                className="w-full bg-slate-50 border border-slate-300 rounded-lg p-2.5 text-xs font-semibold text-slate-800"
              >
                {inspectors.map((insp) => (
                  <option key={insp.id} value={insp.id}>
                    {insp.name} — {insp.jurisdiction} ({insp.email})
                  </option>
                ))}
              </select>
            </div>

            <div className="flex justify-end space-x-3 pt-2">
              <button onClick={() => setActiveModal(null)} className="bg-slate-100 text-slate-700 font-bold text-xs px-4 py-2 rounded-lg">
                Cancel
              </button>
              <button onClick={handleDeployRaid} className="bg-rose-700 hover:bg-rose-800 text-white font-black text-xs px-5 py-2 rounded-lg shadow">
                Confirm & Deploy Raid Squad
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 2. Live Field Panchnama Stream Modal */}
            {/* 3. DSC Compounding Signature Modal */}
      {activeModal === 'DSC_SIGN' && (
        <div className="fixed inset-0 bg-slate-950/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white border border-slate-200 rounded-2xl max-w-md w-full p-6 space-y-4 shadow-2xl">
            <div className="flex justify-between items-center border-b border-slate-100 pb-3">
              <h3 className="text-base font-black text-slate-900">Execute Digital Signature (DSC)</h3>
              <button onClick={() => setActiveModal(null)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="bg-slate-50 p-3 rounded-lg border border-slate-200 text-xs space-y-1">
              <div><strong className="text-slate-900">Notice ID:</strong> {activeNotice?.id}</div>
              <div><strong className="text-slate-900">Merchant:</strong> {activeNotice?.businessName}</div>
              <div><strong className="text-emerald-600 font-bold">Compounding Fee:</strong> ₹50,000.00</div>
            </div>

            <div className="space-y-1.5">
              <label className="text-xs font-bold text-slate-700">Enter Class-3 USB Token PIN</label>
              <input 
                type="password"
                value={dscPin}
                onChange={(e) => setDscPin(e.target.value)}
                className="w-full bg-slate-50 border border-slate-300 rounded-lg p-2.5 text-sm font-mono text-center font-bold tracking-widest text-slate-900"
              />
              <div className="text-[10px] text-emerald-600 font-bold text-center">✓ SafeNet eToken 5110 Connected (Valid till 2027)</div>
            </div>

            <div className="flex justify-end space-x-3 pt-2">
              <button onClick={() => setActiveModal(null)} className="bg-slate-100 text-slate-700 font-bold text-xs px-4 py-2 rounded-lg">
                Cancel
              </button>
              <button onClick={handleApproveNotice} className="bg-emerald-600 hover:bg-emerald-700 text-white font-black text-xs px-5 py-2 rounded-lg shadow">
                Sign & Issue Order
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 4. Public Prosecutor Transmission Modal */}
      {activeModal === 'PROSECUTION' && (
        <div className="fixed inset-0 bg-slate-950/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white border border-slate-200 rounded-2xl max-w-md w-full p-6 space-y-4 shadow-2xl">
            <div className="flex justify-between items-center border-b border-slate-100 pb-3">
              <h3 className="text-base font-black text-rose-700">Transmit to Public Prosecutor</h3>
              <button onClick={() => setActiveModal(null)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <p className="text-xs text-slate-600">
              Transmit repeat offender case dossier under Section 36(2) of Legal Metrology Act 2011 to state prosecution department for criminal trial.
            </p>

            <div className="space-y-2">
              <label className="text-xs font-bold text-slate-700">Designated Judicial Court</label>
              <select 
                value={prosecutionCourt}
                onChange={(e) => setProsecutionCourt(e.target.value)}
                className="w-full bg-slate-50 border border-slate-300 rounded-lg p-2 text-xs font-semibold text-slate-800"
              >
                <option value="Chief Metropolitan Magistrate Court, Esplanade Mumbai">Chief Metropolitan Magistrate Court, Esplanade Mumbai</option>
                <option value="District & Sessions Court, Thane">District & Sessions Court, Thane</option>
                <option value="Judicial Magistrate First Class (JMFC), Pune">Judicial Magistrate First Class (JMFC), Pune</option>
              </select>
            </div>

            <div className="flex justify-end space-x-3 pt-2">
              <button onClick={() => setActiveModal(null)} className="bg-slate-100 text-slate-700 font-bold text-xs px-4 py-2 rounded-lg">
                Cancel
              </button>
              <button onClick={handleEscalateNotice} className="bg-rose-700 hover:bg-rose-800 text-white font-black text-xs px-5 py-2 rounded-lg shadow">
                File Charge-sheet
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 5. District Ledger Modal */}
      {activeModal === 'DISTRICT_LEDGER' && (
        <div className="fixed inset-0 bg-slate-950/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white border border-slate-200 rounded-2xl max-w-3xl w-full p-6 space-y-4 shadow-2xl max-h-[85vh] flex flex-col">
            <div className="flex justify-between items-center border-b border-slate-100 pb-3">
              <h3 className="text-base font-black text-slate-900">Maharashtra State Metrology District Ledger</h3>
              <button onClick={() => setActiveModal(null)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="overflow-y-auto flex-1 space-y-2 pr-1">
              <table className="w-full text-left text-xs text-slate-700">
                <thead className="bg-slate-50 text-slate-500 text-[10px] uppercase font-bold sticky top-0 border-b border-slate-200">
                  <tr>
                    <th className="p-2.5">District / Region</th>
                    <th className="p-2.5">Status</th>
                    <th className="p-2.5">Inspections</th>
                    <th className="p-2.5">Violations</th>
                    <th className="p-2.5">Penal Revenue</th>
                    <th className="p-2.5">SLA %</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {stats?.regionalRadar.map((r, idx) => (
                    <tr key={idx} className="hover:bg-slate-50">
                      <td className="p-2.5 font-bold text-slate-900">{r.region}</td>
                      <td className="p-2.5"><span className="bg-emerald-100 text-emerald-800 text-[10px] font-bold px-2 py-0.5 rounded">{r.alertLevel}</span></td>
                      <td className="p-2.5 font-semibold">{r.inspections.toLocaleString()}</td>
                      <td className="p-2.5 font-bold text-rose-600">{r.violations}</td>
                      <td className="p-2.5 font-bold text-amber-700 font-mono">₹{r.recoveryRupees}</td>
                      <td className="p-2.5 font-bold text-emerald-600">{r.slaRatePercent}%</td>
                    </tr>
                  ))}

                </tbody>
              </table>
            </div>

            <div className="flex justify-end pt-2">
              <button onClick={() => setActiveModal(null)} className="bg-amber-500 text-slate-950 font-bold text-xs px-4 py-2 rounded-lg">
                Close Ledger
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 6. Auto-Assignment Rules Modal */}
      {/* 9. District Radar Options Modal */}
      {activeModal === 'FILTER_RADAR' && (
        <div className="fixed inset-0 bg-slate-950/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white border border-slate-200 rounded-2xl max-w-sm w-full p-6 space-y-4 shadow-2xl">
            <div className="flex justify-between items-center border-b border-slate-100 pb-3">
              <h3 className="text-base font-black text-slate-900">Filter Regional Radar</h3>
              <button onClick={() => setActiveModal(null)} className="text-slate-400 hover:text-slate-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-2 text-xs">
              <label className="block text-slate-700 font-bold">Alert Level Filter</label>
              <select 
                value={tempRadarFilter}
                onChange={(e) => setTempRadarFilter(e.target.value as any)}
                className="w-full bg-slate-50 border border-slate-300 rounded-lg p-2.5 text-xs font-semibold text-slate-800 focus:outline-none focus:border-amber-500"
              >
                <option value="ALL">All Divisions (High Alert, Watch &amp; Compliant)</option>
                <option value="High Alert">High Alert Only</option>
                <option value="Moderate Watch">Moderate Watch Only</option>
                <option value="Compliant">Compliant Only</option>
              </select>
            </div>

            <div className="flex justify-end space-x-2 pt-2">
              <button onClick={() => setActiveModal(null)} className="bg-slate-100 text-slate-700 font-bold text-xs px-3.5 py-2 rounded-lg">
                Cancel
              </button>
              <button onClick={() => {
                setRadarAlertFilter(tempRadarFilter);
                showToast(`Regional Radar filtered: ${tempRadarFilter === 'ALL' ? 'All Divisions' : tempRadarFilter}`);
                setActiveModal(null);
              }} className="bg-amber-500 hover:bg-amber-400 text-slate-950 font-black text-xs px-4 py-2 rounded-lg shadow cursor-pointer">
                Apply Filter
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 10. Detailed Statutory Case Dossier PDF Viewer Modal */}
      {activeModal === 'DETAILED_DOSSIER_PDF' && (
        <div className="fixed inset-0 bg-slate-950/75 backdrop-blur-md z-50 flex items-center justify-center p-4">
          <div className="bg-white border border-slate-300 rounded-2xl max-w-3xl w-full p-6 space-y-5 shadow-2xl animate-in fade-in zoom-in duration-200 max-h-[90vh] overflow-y-auto font-sans">
            {/* Top PDF Toolbar */}
            <div className="flex justify-between items-center border-b border-slate-200 pb-3 bg-slate-50 -mx-6 -mt-6 p-4 rounded-t-2xl">
              <div className="flex items-center space-x-2">
                <div className="w-8 h-8 rounded bg-[#0D1F3C] text-amber-400 flex items-center justify-center font-bold">
                  <FileText className="w-4 h-4" />
                </div>
                <div>
                  <h3 className="text-sm font-black text-slate-900">
                    Statutory Case Dossier & Inspection Report (PDF Document)
                  </h3>
                  <p className="text-[10px] text-slate-500 font-mono">
                    Document Ref: MH-LM-2024-CO-9041.pdf • Form LM-4 Under Sec 48
                  </p>
                </div>
              </div>

              <div className="flex items-center space-x-2">
                <button 
                  onClick={() => showToast('Printing Official Statutory Dossier (Form LM-4)...')} 
                  className="bg-slate-200 hover:bg-slate-300 text-slate-800 text-xs px-3 py-1.5 rounded-lg font-bold flex items-center space-x-1.5 transition-all cursor-pointer"
                >
                  <Printer className="w-3.5 h-3.5" />
                  <span className="hidden sm:inline">Print</span>
                </button>
                <button 
                  onClick={() => handleDownloadNoticePdf(activeNotice)} 
                  className="bg-[#0D1F3C] hover:bg-[#081427] text-white text-xs px-3.5 py-1.5 rounded-lg font-bold flex items-center space-x-1.5 transition-all cursor-pointer"
                >
                  <Download className="w-3.5 h-3.5 text-amber-400" />
                  <span>Download PDF</span>
                </button>
                <button onClick={() => setActiveModal(null)} className="text-slate-400 hover:text-slate-700 p-1">
                  <X className="w-5 h-5" />
                </button>
              </div>
            </div>

            {/* PDF Document Body Container (Simulated Official PDF Sheet) */}
            <div className="bg-slate-50 border border-slate-300 rounded-xl p-6 space-y-6 shadow-inner text-slate-900">
              {/* Emblem & Department Title */}
              <div className="text-center border-b border-slate-300 pb-4 space-y-1">
                <div className="text-[11px] font-bold tracking-widest text-slate-700 uppercase">
                  भारत सरकार • GOVERNMENT OF MAHARASHTRA
                </div>
                <h2 className="text-lg font-black text-slate-900 tracking-tight">
                  DIRECTORATE OF LEGAL METROLOGY ADJUDICATION DOSSIER
                </h2>
                <div className="text-xs text-amber-800 font-semibold">
                  Under Section 48 of Legal Metrology Act, 2009 & Legal Metrology (Packaged Commodities) Rules, 2011
                </div>
                <div className="pt-2 flex justify-center items-center space-x-3 text-[10px] font-mono text-slate-600">
                  <span>BARCODE: |||||| |||| |||||||| #SEC-DSO-CERT-96041</span>
                  <span>•</span>
                  <span>ISSUED AT: ENFORCEMENT HQ DELHI</span>
                </div>
              </div>

              {/* Grid 1: Accused Entity & License Metadata */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
                <div className="bg-white p-3.5 rounded-lg border border-slate-200 space-y-1">
                  <div className="text-[10px] text-slate-500 font-bold uppercase">ACCUSED ENTITY / MERCHANT</div>
                  <div className="font-black text-slate-900 text-sm">{activeNotice?.businessName || 'Regulated Establishment'}</div>
                  <div className="text-slate-600">Commodity: {activeNotice?.violatingProduct || 'Packaged Commodity'}</div>
                </div>

                <div className="bg-white p-3.5 rounded-lg border border-slate-200 space-y-1 font-mono">
                  <div className="text-[10px] text-slate-500 font-bold uppercase font-sans">STATUTORY REFERENCE & CASE</div>
                  <div><strong className="text-slate-700 font-sans">DIN:</strong> {activeNotice?.dinNumber || activeNotice?.id}</div>
                  <div><strong className="text-slate-700 font-sans">Case ID:</strong> {activeNotice?.caseId || activeNotice?.id}</div>
                  <div><strong className="text-slate-700 font-sans">Section:</strong> {activeNotice?.sectionRefs?.join(', ') || 'Section 36(1)'}</div>
                </div>
              </div>

              {/* Grid 2: Forensic Seizure Evidence Comparison */}
              <div className="bg-white p-4 rounded-xl border border-slate-200 space-y-3">
                <div className="flex items-center justify-between border-b border-slate-100 pb-2">
                  <span className="text-xs font-bold text-slate-900 flex items-center gap-1.5">
                    <Camera className="w-4 h-4 text-amber-600" /> Forensic Seizure Evidence & OCR Scan Analysis
                  </span>
                  <span className="bg-emerald-100 text-emerald-800 text-[10px] font-bold px-2 py-0.5 rounded">
                    E-Evidence Sec 65B Certified
                  </span>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
                  <div className="space-y-1">
                    <div className="font-bold text-slate-600">Original Stamped MRP: <span className="text-emerald-700 font-mono text-sm font-black">₹320.00</span></div>
                    <div className="text-[10px] text-slate-500 font-mono">Batch: S.No SB-4402 • Mfd: 09/2024 • Hindustan CleanCare Works Ltd</div>
                  </div>
                  <div className="space-y-1">
                    <div className="font-bold text-rose-600">Illegal Sticker Overwritten: <span className="text-rose-700 font-mono text-sm font-black">₹399.00</span></div>
                    <div className="text-[10px] text-rose-700 font-bold">TAMPER CONFIRMED • OVERCHARGING DIFF: +₹79.00 (+24.6% Hike)</div>
                  </div>
                </div>

                <div className="bg-slate-50 p-2.5 rounded border border-slate-200 text-[10px] font-mono text-slate-600 flex justify-between">
                  <span>Automated AI OCR Engine: 99.4% Certainty</span>
                  <span>GPS Geotag: 19.0728° N, 72.8826° E (Phoenix Kurla Premises)</span>
                </div>
              </div>

              {/* Step 3: Statutory Audit Trail & Compliance Checklist */}
              <div className="space-y-2">
                <div className="text-xs font-bold text-slate-900">Statutory Audit Trail & Procedural Compliance</div>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 text-[10px] font-semibold">
                  <div className="bg-white p-2.5 rounded border border-slate-200 text-center space-y-0.5">
                    <div className="font-bold text-slate-900">1. Notice Form I</div>
                    <div className="text-emerald-700">Served 14 Oct 2024</div>
                  </div>
                  <div className="bg-white p-2.5 rounded border border-slate-200 text-center space-y-0.5">
                    <div className="font-bold text-slate-900">2. Seizure Memo V</div>
                    <div className="text-emerald-700">Executed 16 Oct 2024</div>
                  </div>
                  <div className="bg-white p-2.5 rounded border border-slate-200 text-center space-y-0.5">
                    <div className="font-bold text-slate-900">3. Panchanama</div>
                    <div className="text-emerald-700">2 Independent Witness</div>
                  </div>
                  <div className="bg-white p-2.5 rounded border border-slate-200 text-center space-y-0.5">
                    <div className="font-bold text-slate-900">4. Consent Form</div>
                    <div className="text-emerald-700">Aadhaar e-Signed</div>
                  </div>
                </div>
              </div>

              {/* Penalty Computation Table */}
              <div className="border border-slate-200 rounded-xl overflow-hidden text-xs">
                <table className="w-full text-left">
                  <thead className="bg-slate-100 font-bold text-slate-700 border-b border-slate-200">
                    <tr>
                      <th className="p-2.5">Penalty Computation Head</th>
                      <th className="p-2.5 text-right font-mono">Statutory Amount</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-200 bg-white font-mono">
                    <tr>
                      <td className="p-2.5 font-sans font-medium text-slate-800">Base Statutory Penalty • Section 36(1)</td>
                      <td className="p-2.5 text-right font-bold text-slate-900">₹25,000.00</td>
                    </tr>
                    <tr>
                      <td className="p-2.5 font-sans font-medium text-slate-800">Compounding Settlement Tariff • Section 48(1)</td>
                      <td className="p-2.5 text-right font-bold text-slate-900">₹25,000.00</td>
                    </tr>
                    <tr className="bg-emerald-50/60 font-sans">
                      <td className="p-2.5 text-emerald-800 font-bold">Citizen Whistleblower Incentive Allocation (10%)</td>
                      <td className="p-2.5 text-right font-bold text-emerald-700 font-mono">₹5,000.00 (Disbursed)</td>
                    </tr>
                    <tr className="bg-slate-100 font-black font-sans">
                      <td className="p-3 text-slate-900">TOTAL COMPOUNDING RECOVERY PAYABLE</td>
                      <td className="p-3 text-right font-mono text-base text-emerald-700">₹50,000.00</td>
                    </tr>
                  </tbody>
                </table>
              </div>

              {/* Digital Signature Badge */}
              <div className="bg-blue-50 border border-blue-200 rounded-xl p-3.5 flex items-center justify-between text-xs">
                <div className="flex items-center space-x-3">
                  <ShieldCheck className="w-6 h-6 text-blue-700" />
                  <div>
                    <div className="font-bold text-slate-900">DSC Certificate Active (Class 3 Govt Token)</div>
                    <div className="text-[10px] text-slate-500 font-mono">Token Holder: Shri R.K. Singh • Controller General (Valid: 2028)</div>
                  </div>
                </div>
                <span className="bg-blue-700 text-white font-bold text-[10px] px-2.5 py-1 rounded shadow">
                  Digitally Authenticated
                </span>
              </div>
            </div>

            {/* Modal Actions */}
            <div className="flex justify-between items-center pt-2">
              <span className="text-[11px] text-slate-500 font-mono">Official Adjudication Dossier • Legal Metrology Enforcement Directorate</span>
              <button 
                onClick={() => setActiveModal(null)} 
                className="bg-slate-900 text-white font-bold text-xs px-5 py-2 rounded-lg shadow cursor-pointer"
              >
                Close Dossier Preview
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 11. Leaflet GIS Spatial Radar Map Modal */}
      {activeModal === 'LEAFLET_MAP' && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-md z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-700 rounded-2xl max-w-5xl w-full p-4 space-y-3 shadow-2xl animate-in fade-in zoom-in duration-200 font-sans">
            <div className="flex justify-between items-center border-b border-slate-800 pb-2">
              <div className="flex items-center space-x-2 text-amber-400">
                <MapPin className="w-5 h-5 text-emerald-400" />
                <h3 className="text-base font-black text-white">Leaflet GIS Spatial Radar & District Enforcement Heatmap</h3>
              </div>
              <button onClick={() => setActiveModal(null)} className="text-slate-400 hover:text-white p-1">
                <X className="w-5 h-5" />
              </button>
            </div>

            <LeafletRadarMap onClose={() => setActiveModal(null)} />

            <div className="flex justify-between items-center text-xs text-slate-400 font-mono pt-1">
              <span>Connected to OpenStreetMap / CartoDB Dark Tiles & GIS Server</span>
              <button 
                onClick={() => setActiveModal(null)} 
                className="bg-slate-800 hover:bg-slate-700 text-white font-bold px-4 py-1.5 rounded-lg text-xs"
              >
                Close Map View
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 12. Citizen Detailed Complaint Dossier View Modal */}
      {viewingComplaintItem && (
        <div className="fixed inset-0 z-50 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white border border-slate-200 text-slate-900 rounded-2xl max-w-xl w-full p-6 space-y-4 shadow-2xl animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <div className="flex items-center space-x-2">
                <span className="bg-slate-900 text-white font-mono font-bold text-xs px-2.5 py-1 rounded">
                  Case #{viewingComplaintItem.id}
                </span>
                <span className="text-xs text-slate-500 font-bold">Filed {viewingComplaintItem.date}</span>
              </div>
              <button 
                onClick={() => setViewingComplaintItem(null)}
                className="p-1 rounded bg-slate-100 hover:bg-slate-200 text-slate-600 cursor-pointer"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="space-y-3 text-xs">
              <div className="bg-slate-50 p-3 rounded-xl border border-slate-200 space-y-1">
                <div className="font-black text-slate-900 text-sm">{viewingComplaintItem.product}</div>
                <div className="text-slate-500">{viewingComplaintItem.brandSub}</div>
              </div>

              <div className="grid grid-cols-2 gap-3 bg-slate-50 p-3 rounded-xl border border-slate-200">
                <div>
                  <span className="text-[10px] text-slate-400 font-bold uppercase block">Accused Entity</span>
                  <span className="font-bold text-slate-900">{viewingComplaintItem.entityName}</span>
                  <div className="text-[10px] text-slate-500">{viewingComplaintItem.entityAddress}</div>
                </div>
                <div>
                  <span className="text-[10px] text-slate-400 font-bold uppercase block">Inspector In-Charge</span>
                  <span className="font-bold text-amber-700">{viewingComplaintItem.inspector} ({viewingComplaintItem.inspectorZone})</span>
                </div>
                <div>
                  <span className="text-[10px] text-slate-400 font-bold uppercase block">Current State</span>
                  <span className="font-bold text-rose-600">{viewingComplaintItem.status}</span>
                </div>
                <div>
                  <span className="text-[10px] text-slate-400 font-bold uppercase block">Penal Outcome</span>
                  <span className="font-bold text-emerald-600">{viewingComplaintItem.penalty}</span>
                </div>
              </div>

              <div className="space-y-1">
                <span className="font-bold text-slate-700">Statement of Fact Observation:</span>
                <p className="p-3 bg-slate-50 border border-slate-200 rounded-lg text-slate-600 font-mono text-[11px] leading-relaxed">
                  {viewingComplaintItem.statement}
                </p>
              </div>

              <div className="flex items-center justify-between p-3.5 bg-[#0D1F3C] text-white rounded-xl shadow-md">
                <div>
                  <div className="text-[10px] text-amber-400 font-bold">WHISTLEBLOWER REWARD STATUS</div>
                  <div className="font-mono font-black text-amber-300 text-sm">{viewingComplaintItem.rewardStatus}</div>
                </div>
                <button
                  onClick={() => {
                    showToast(`Downloading official legal dossier for case #${viewingComplaintItem.id}...`);
                    setViewingComplaintItem(null);
                  }}
                  className="bg-amber-500 hover:bg-amber-400 text-slate-950 text-xs font-bold px-3.5 py-2 rounded-lg flex items-center gap-1.5 cursor-pointer shadow"
                >
                  <Download className="w-3.5 h-3.5" />
                  <span>Download Case PDF</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 13. Citizen Advanced Filter Modal */}
      {isAdvFilterModalOpen && (
        <div className="fixed inset-0 z-50 bg-slate-950/70 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white border border-slate-200 text-slate-900 rounded-2xl max-w-md w-full p-6 space-y-4 shadow-2xl animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 className="text-sm font-extrabold text-slate-900 flex items-center gap-2">
                <SlidersHorizontal className="w-4 h-4 text-amber-500" />
                <span>Advanced Complaint Registry Filters</span>
              </h3>
              <button onClick={() => setIsAdvFilterModalOpen(false)} className="p-1 rounded bg-slate-100 hover:bg-slate-200 text-slate-600 cursor-pointer">
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="space-y-3 text-xs">
              <div className="space-y-1">
                <label className="font-bold text-slate-700">Filter by Date Range</label>
                <select className="w-full bg-slate-50 border border-slate-200 rounded-lg p-2 font-semibold cursor-pointer">
                  <option>Last 30 Days (Oct - Nov 2024)</option>
                  <option>Last 90 Days (Q3 FY 2024-25)</option>
                  <option>All Time Records</option>
                </select>
              </div>

              <div className="space-y-1">
                <label className="font-bold text-slate-700">Filter by Inspector Division</label>
                <select className="w-full bg-slate-50 border border-slate-200 rounded-lg p-2 font-semibold cursor-pointer">
                  <option>All Mumbai / Thane / Pune Divisions</option>
                  <option>LMO Zone 4 (Mumbai Central)</option>
                  <option>LMO Zone 3 (Mumbai Suburban)</option>
                  <option>LMO Thane Division</option>
                </select>
              </div>
            </div>

            <div className="flex items-center justify-end space-x-2 pt-2 border-t border-slate-100">
              <button onClick={() => setIsAdvFilterModalOpen(false)} className="px-3 py-2 rounded-lg border border-slate-200 text-slate-600 font-bold cursor-pointer hover:bg-slate-50">
                Cancel
              </button>
              <button onClick={() => {
                showToast('Advanced filters applied to case registry.');
                setIsAdvFilterModalOpen(false);
              }} className="px-4 py-2 rounded-lg bg-amber-500 hover:bg-amber-400 text-slate-950 font-black cursor-pointer shadow">
                Apply Filters
              </button>
            </div>
          </div>
        </div>
      )}

      <Footer />
    </div>
  );
}
