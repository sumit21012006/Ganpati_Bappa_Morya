'use client';

import React, { useState, useRef, useEffect } from 'react';
import { useApp } from '@/context/AppContext';
import { submitCitizenComplaint } from '@/lib/api';
import { searchBusinesses } from '@/lib/api/businesses';
import { Business, Complaint } from '@/types';
import { VIOLATION_CATEGORIES } from '@/lib/constants';
import { 
  ShieldCheck, 
  Award, 
  Upload, 
  Camera, 
  FileText, 
  CheckCircle2, 
  Building, 
  Sparkles, 
  AlertCircle, 
  Info,
  MapPin,
  Check,
  Plus,
  Trash2
} from 'lucide-react';

export const MAHARASHTRA_CITIES = [
  'Mumbai Suburban',
  'Pune Metro',
  'Thane Circle',
  'Nashik Region',
  'Nagpur East & West',
  'Chhatrapati Sambhajinagar',
  'Solapur District',
  'Kolhapur Circle',
  'Amravati Hub',
  'Nanded Division',
  'Jalgaon Belt',
  'Sangli City'
];

interface CitizenComplaintFormProps {
  isDarkMode?: boolean;
  onComplaintSubmitted?: (complaint: Complaint) => void;
}

export default function CitizenComplaintForm({ isDarkMode = true, onComplaintSubmitted }: CitizenComplaintFormProps) {
  const { setRewardPointsBalance, user, setCitizenTab } = useApp();
  
  // Active Step Highlight State (1 = Merchant/City, 2 = Statement of Fact, 3 = Evidence Upload & AI)
  const [activeStep, setActiveStep] = useState<number>(1);

  // Section Refs for smooth scrolling when step pill is clicked
  const step1Ref = useRef<HTMLDivElement>(null);
  const step2Ref = useRef<HTMLDivElement>(null);
  const step3Ref = useRef<HTMLDivElement>(null);

  const scrollToStep = (step: number) => {
    setActiveStep(step);
    const targetRef = step === 1 ? step1Ref : step === 2 ? step2Ref : step3Ref;
    targetRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  };

  // Form Field States
  const [channel, setChannel] = useState<'OFFLINE_STORE' | 'ECOMMERCE_PLATFORM'>('OFFLINE_STORE');
  const [selectedCity, setSelectedCity] = useState<string>('Mumbai Suburban');
  const [selectedCategory, setSelectedCategory] = useState<string>(VIOLATION_CATEGORIES[0]);
  const [retailerSearch, setRetailerSearch] = useState<string>('');
  const [selectedRetailer, setSelectedRetailer] = useState<Business | null>(null);
  const [businessResults, setBusinessResults] = useState<Business[]>([]);
  const [isSearching, setIsSearching] = useState<boolean>(false);

  // Debounced backend business search
  useEffect(() => {
    if (!retailerSearch.trim() || selectedRetailer) {
      setBusinessResults([]);
      return;
    }
    const timer = setTimeout(async () => {
      setIsSearching(true);
      try {
        const results = await searchBusinesses(retailerSearch);
        setBusinessResults(results);
      } catch {
        setBusinessResults([]);
      } finally {
        setIsSearching(false);
      }
    }, 350);
    return () => clearTimeout(timer);
  }, [retailerSearch, selectedRetailer]);

  // Image Upload State — stores file info + DataURL for backend transmission
  const [uploadedPhotos, setUploadedPhotos] = useState<Array<{ name: string; type: string; url?: string; dataUrl?: string }>>([]);

  // Statement of Fact
  const [statementOfFact, setStatementOfFact] = useState<string>(
    'Purchased bottle from QuickMart Supermarket shelf in Mumbai Suburban. Bottle felt visibly underweight compared to adjacent brands. Upon laboratory calibrated scale measurement in our cooperative society test bench, gross package weighed 925g with net oil estimated at 848ml vs statutory mandatory 1000ml declaration. Variance exceeds the 15ml maximum permissible error under Second Schedule of PCR 2011.'
  );

  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [submittedToken, setSubmittedToken] = useState<string | null>(null);

  // Authenticated user details fetched directly from profile
  const citizenName = user ? user.name : 'Authenticated Citizen';
  const citizenMobile = user?.mobile || '+91 98450 XXXXX';
  const citizenUpiVpa = user?.upiVpa || (user?.name ? `${user.name.toLowerCase().replace(/\s+/g, '.')}@upi` : 'citizen@upi');

  const handleSelectRetailer = (b: Business) => {
    setSelectedRetailer(b);
    setRetailerSearch(b.name);
    setBusinessResults([]);
    setActiveStep(1);
  };

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    setActiveStep(3);
    if (!e.target.files) return;
    const files = Array.from(e.target.files);

    // Helper to compress image client-side to max 1280px and 0.8 JPEG quality
    const compressImage = (file: File): Promise<string> => {
      return new Promise((resolve) => {
        const reader = new FileReader();
        reader.onload = (event) => {
          const img = new Image();
          img.onload = () => {
            const canvas = document.createElement('canvas');
            const MAX_DIM = 1280;
            let { width, height } = img;
            if (width > height && width > MAX_DIM) {
              height = Math.round((height * MAX_DIM) / width);
              width = MAX_DIM;
            } else if (height > MAX_DIM) {
              width = Math.round((width * MAX_DIM) / height);
              height = MAX_DIM;
            }
            canvas.width = width;
            canvas.height = height;
            const ctx = canvas.getContext('2d');
            if (ctx) {
              ctx.drawImage(img, 0, 0, width, height);
              resolve(canvas.toDataURL('image/jpeg', 0.8));
            } else {
              resolve(event.target?.result as string);
            }
          };
          img.onerror = () => resolve(event.target?.result as string);
          img.src = event.target?.result as string;
        };
        reader.onerror = () => resolve('');
        reader.readAsDataURL(file);
      });
    };

    // Read and compress each file for swift backend transmission
    files.forEach(async (file) => {
      const dataUrl = await compressImage(file);
      setUploadedPhotos((prev) => {
        if (prev.length >= 6) return prev;
        return [
          ...prev,
          {
            name: file.name,
            type:
              file.name.includes('bill') || file.name.includes('invoice')
                ? 'Retail Bill (Optional)'
                : 'Additional Evidence',
            url: URL.createObjectURL(file),
            dataUrl,
          },
        ];
      });
    });
  };

  const handleRemovePhoto = (index: number) => {
    setUploadedPhotos((prev) => prev.filter((_, i) => i !== index));
  };

  const [submitError, setSubmitError] = useState<string | null>(null);

  const handleSubmit = async (e?: React.FormEvent | React.MouseEvent) => {
    if (e && e.preventDefault) e.preventDefault();
    setIsSubmitting(true);
    setSubmitError(null);

    // Collect DataURLs from uploaded photos for backend
    const photoUrls = uploadedPhotos
      .map((p) => p.dataUrl || p.url || '')
      .filter(Boolean);

    try {
      console.log('[complaint] Submitting to backend...');
      const res = await submitCitizenComplaint({
        citizenId: user?.id || 'citizen_web',
        citizenName,
        citizenMobile,
        citizenUpiVpa,
        retailerNameText: selectedRetailer ? selectedRetailer.name : retailerSearch || 'Unknown Retailer',
        retailerAddressText: selectedRetailer
          ? selectedRetailer.address
          : `${selectedCity}, Maharashtra`,
        businessId: selectedRetailer?.id,
        channel,
        category: selectedCategory || 'General Metrology Violation',
        statementOfFact,
        photoUrls,
      });

      console.log('[complaint] Submission successful, ID:', res.id);
      setSubmittedToken(res.id);
      setRewardPointsBalance((prev) => prev + 500);
      if (onComplaintSubmitted) {
        onComplaintSubmitted(res);
      }
      if (typeof window !== 'undefined') {
        window.scrollTo({ top: 0, behavior: 'smooth' });
      }
    } catch (err: any) {
      console.error('[complaint] Error submitting complaint:', err);
      setSubmitError(err.message || 'Failed to submit complaint. Please check network connection.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const bgCard = isDarkMode ? 'bg-slate-950 border-slate-800 text-slate-100' : 'bg-white border-slate-200 text-slate-900';
  const bgInput = isDarkMode ? 'bg-slate-900 border-slate-700 text-slate-200 placeholder-slate-500' : 'bg-slate-50 border-slate-300 text-slate-900 placeholder-slate-400';
  const textSub = isDarkMode ? 'text-slate-400' : 'text-slate-500';

  return (
    <div className="space-y-6 font-sans">
      {/* Whistleblower Scheme Banner */}
      <div className={`${isDarkMode ? 'bg-gradient-to-r from-slate-950 via-slate-900 to-slate-950 border-slate-800' : 'bg-gradient-to-r from-[#0D1F3C] via-[#102A52] to-[#0D1F3C] border-blue-900'} border rounded-xl p-5 relative overflow-hidden shadow-xl text-white`}>
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 relative z-10">
          <div>
            <span className="bg-amber-500/20 text-amber-300 border border-amber-500/40 text-[10px] uppercase font-bold px-2.5 py-1 rounded-full tracking-wider">
              NATIONAL WHISTLEBLOWER INCENTIVE SCHEME • RULE 32A REDRESSAL
            </span>
            <h1 className="text-xl md:text-2xl font-black tracking-tight text-white mt-2">
              Register Packaging Violation & Claim Citizen Reward Points
            </h1>
            <p className="text-xs text-slate-300 mt-1">
              सत्यमेव जयते | Vigilant Citizens Shield The Nation Against Metric Deceptions
            </p>
          </div>

          <div className="bg-slate-900/90 border border-amber-500/40 rounded-lg p-3 flex items-center space-x-3 shadow-lg shrink-0">
            <div className="w-10 h-10 rounded-full bg-amber-500 text-slate-950 flex items-center justify-center font-black text-lg">
              🪙
            </div>
            <div>
              <div className="text-xs font-bold text-amber-400">
                Earn 10% Citizen Vigilance Reward Points (250 – 2,500 Points)
              </div>
              <div className="text-[10px] text-slate-300 flex items-center gap-1 mt-0.5">
                <ShieldCheck className="w-3 h-3 text-emerald-400" />
                <span>Direct Authenticated Citizen Profile Dispatch</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Stepper Bar (3-Step Single Page Indicator) */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-3 text-xs font-semibold sticky top-16 z-30 bg-slate-900/90 backdrop-blur py-1.5 rounded-xl">
        {[
          { step: 1, title: '1. Incident Details', sub: 'City & Merchant Credentials' },
          { step: 2, title: '2. Statement of Fact', sub: 'Ground Reality Observation' },
          { step: 3, title: '3. Photo Evidence & Examples', sub: 'Upload Photos & AI Audit' },
        ].map((s) => {
          const isActive = activeStep === s.step;
          const isDone = activeStep > s.step;

          return (
            <button
              key={s.step}
              type="button"
              onClick={() => scrollToStep(s.step)}
              className={`p-3 rounded-xl border text-left flex items-center space-x-2.5 transition-all cursor-pointer ${
                isActive
                  ? 'bg-amber-500/15 border-amber-500 text-amber-500 shadow-md ring-2 ring-amber-500/40 font-bold'
                  : isDone
                  ? 'bg-emerald-950/40 border-emerald-600/60 text-emerald-400'
                  : isDarkMode
                  ? 'bg-slate-950 border-slate-800 text-slate-400 hover:border-slate-700'
                  : 'bg-white border-slate-200 text-slate-600 hover:border-slate-300'
              }`}
            >
              <span
                className={`w-6 h-6 rounded-full font-bold flex items-center justify-center text-xs shrink-0 ${
                  isActive
                    ? 'bg-amber-500 text-slate-950 ring-2 ring-amber-400'
                    : isDone
                    ? 'bg-emerald-500 text-slate-950'
                    : isDarkMode
                    ? 'bg-slate-800 text-slate-300'
                    : 'bg-slate-200 text-slate-700'
                }`}
              >
                {isDone ? <Check className="w-3.5 h-3.5 stroke-[3]" /> : s.step}
              </span>
              <div>
                <div className={`font-bold text-xs ${isActive ? 'text-amber-500' : isDone ? 'text-emerald-400' : isDarkMode ? 'text-slate-200' : 'text-slate-800'}`}>
                  {s.title}
                </div>
                <div className="text-[10px] opacity-80">{s.sub}</div>
              </div>
            </button>
          );
        })}
      </div>

      {/* Success Confirmation Alert if submitted */}
      {submittedToken && (
        <div className="bg-emerald-950/80 border border-emerald-500 rounded-xl p-4 flex items-center justify-between text-emerald-200 shadow-xl">
          <div className="flex items-center space-x-3">
            <CheckCircle2 className="w-6 h-6 text-emerald-400" />
            <div>
              <h4 className="text-sm font-bold">Complaint Successfully Logged! Legal Token Issued.</h4>
              <p className="text-xs text-emerald-300">
                Tracking Token ID: <strong className="font-mono text-white">{submittedToken}</strong> • 500 Pending Reward Points queued to profile.
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={() => setCitizenTab('MY_COMPLAINTS')}
            className="bg-emerald-500 text-slate-950 text-xs font-bold px-4 py-2 rounded-lg hover:bg-emerald-400 transition-all cursor-pointer"
          >
            Track in My Complaints →
          </button>
        </div>
      )}

      {/* Main Single Page Form Layout */}
      <form onSubmit={handleSubmit} className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        
        {/* ========================================================================= */}
        {/* LEFT COLUMN (6 COLS): MERCHANT, CITY, STATEMENT OF FACT & UPLOAD PHOTOS   */}
        {/* ========================================================================= */}
        <div className="lg:col-span-6 space-y-6">
          
          {/* Card 1: Purchase Channel & Vendor Credentials */}
          <div ref={step1Ref} onClick={() => setActiveStep(1)} className={`${bgCard} border rounded-xl p-5 space-y-4 shadow-sm transition-all ${activeStep === 1 ? 'ring-1 ring-amber-500/40' : ''}`}>
            <div className="flex items-center justify-between border-b border-slate-800/80 pb-2.5">
              <h3 className="text-sm font-bold flex items-center gap-2">
                <Building className="w-4 h-4 text-amber-500" />
                <span>Purchase Channel & Vendor Credentials</span>
              </h3>
              <span className="text-[10px] bg-amber-500/20 text-amber-400 border border-amber-500/30 px-2.5 py-1 rounded font-bold uppercase">
                Mandatory
              </span>
            </div>

            {/* Channel Selection Toggle */}
            <div className="grid grid-cols-2 gap-3">
              <button
                type="button"
                onClick={() => setChannel('OFFLINE_STORE')}
                className={`p-3 rounded-lg border text-xs font-bold text-center transition-all ${
                  channel === 'OFFLINE_STORE'
                    ? 'bg-amber-500/15 border-amber-500 text-amber-500 shadow-md'
                    : isDarkMode ? 'bg-slate-900 border-slate-800 text-slate-400' : 'bg-slate-50 border-slate-200 text-slate-600'
                }`}
              >
                🏢 Offline Kirana / Retail Store
              </button>
              <button
                type="button"
                onClick={() => setChannel('ECOMMERCE_PLATFORM')}
                className={`p-3 rounded-lg border text-xs font-bold text-center transition-all ${
                  channel === 'ECOMMERCE_PLATFORM'
                    ? 'bg-amber-500/15 border-amber-500 text-amber-500 shadow-md'
                    : isDarkMode ? 'bg-slate-900 border-slate-800 text-slate-400' : 'bg-slate-50 border-slate-200 text-slate-600'
                }`}
              >
                🛒 E-Commerce Platform (Rule 6(15))
              </button>
            </div>

            {/* Retailer Name Input */}
            <div className="space-y-1 relative">
              <label className="text-xs font-semibold">Retailer Name / Trade Name</label>
              <input
                type="text"
                value={retailerSearch}
                onFocus={() => setActiveStep(1)}
                onChange={(e) => {
                  setRetailerSearch(e.target.value);
                  setSelectedRetailer(null);
                }}
                placeholder="Type retailer name or select from MCA database..."
                className={`w-full ${bgInput} rounded-lg px-3 py-2 text-xs focus:outline-none focus:border-amber-500`}
              />

              {/* Business Search Dropdown (Live from NestJS Backend) */}
              {retailerSearch && !selectedRetailer && (
                <div className={`absolute left-0 right-0 top-full mt-1 ${isDarkMode ? 'bg-slate-950 border-slate-800' : 'bg-white border-slate-200'} border rounded-lg shadow-xl z-20 max-h-48 overflow-y-auto`}>
                  {isSearching ? (
                    <div className="p-3 text-xs text-slate-400 animate-pulse">Searching business registry…</div>
                  ) : businessResults.length > 0 ? (
                    businessResults.map((b) => (
                      <div
                        key={b.id}
                        onClick={() => handleSelectRetailer(b)}
                        className={`p-2.5 ${isDarkMode ? 'hover:bg-slate-900 border-slate-900' : 'hover:bg-slate-50 border-slate-100'} cursor-pointer border-b text-xs`}
                      >
                        <div className="font-bold">{b.name}</div>
                        <div className={`text-[10px] ${textSub}`}>{b.address}</div>
                        {b.gstin && <div className="text-[10px] font-mono text-amber-500/70">GSTIN: {b.gstin}</div>}
                      </div>
                    ))
                  ) : (
                    <div className="p-2.5 text-xs text-slate-400">No registered businesses found. Enter retailer name manually.</div>
                  )}
                </div>
              )}
            </div>

            {/* City Option Dropdown with Scrollable Feature (12 Cities) */}
            <div className="space-y-1.5 pt-1">
              <label className="text-xs font-semibold flex items-center justify-between">
                <span className="flex items-center gap-1.5">
                  <MapPin className="w-3.5 h-3.5 text-amber-500" />
                  <span>Jurisdiction City / Location (Select City)</span>
                </span>
                <span className="text-[10px] text-amber-500 font-bold">12 Cities Scrollable</span>
              </label>
              <select
                value={selectedCity}
                onChange={(e) => setSelectedCity(e.target.value)}
                className={`w-full ${bgInput} rounded-lg px-3 py-2.5 text-xs font-bold focus:outline-none focus:border-amber-500 cursor-pointer`}
              >
                {MAHARASHTRA_CITIES.map((city) => (
                  <option key={city} value={city} className={isDarkMode ? 'bg-slate-900 text-slate-100 p-2' : 'bg-white text-slate-900 p-2'}>
                    📍 {city}
                  </option>
                ))}
              </select>
              <p className={`text-[10px] ${textSub}`}>
                Selected jurisdiction circle will route automatically to LMO District Inspector.
              </p>
            </div>
          </div>

          {/* Card 2: Ground Reality Observation / Statement of Fact */}
          <div ref={step2Ref} onClick={() => setActiveStep(2)} className={`${bgCard} border rounded-xl p-5 space-y-3 shadow-sm transition-all ${activeStep === 2 ? 'ring-1 ring-amber-500/40' : ''}`}>
            <div className="flex items-center justify-between border-b border-slate-800/80 pb-2.5">
              <h3 className="text-sm font-bold flex items-center gap-2">
                <FileText className="w-4 h-4 text-amber-500" />
                <span>Ground Reality Observation / Statement of Fact (विस्तृत विवरण)</span>
              </h3>
              <span className="text-[10px] text-slate-400 font-mono">PCR 2011 Rule 32</span>
            </div>

            {/* Statement of Fact Textarea */}
            <div className="space-y-1.5 text-xs">
              <label className="font-semibold text-slate-300">Detailed Violation Summary & Physical Measurement Details</label>
              <textarea
                rows={6}
                value={statementOfFact}
                onFocus={() => setActiveStep(2)}
                onChange={(e) => setStatementOfFact(e.target.value)}
                className={`w-full ${bgInput} rounded-lg p-3.5 text-xs font-mono leading-relaxed focus:outline-none focus:border-amber-500 shadow-inner`}
                placeholder="Write detailed statement of fact..."
              />
              <p className={`text-[10px] ${textSub}`}>
                State exact location, observed deficit, container condition, and physical weighing scale readouts.
              </p>
            </div>
          </div>

          {/* Card 3: Upload Product Photos (Moved to Left Side Column) */}
          <div ref={step3Ref} onClick={() => setActiveStep(3)} className={`${bgCard} border rounded-xl p-5 space-y-4 shadow-sm transition-all ${activeStep === 3 ? 'ring-1 ring-amber-500/40' : ''}`}>
            <div className="flex items-center justify-between border-b border-slate-800/80 pb-2.5">
              <h3 className="text-sm font-bold flex items-center gap-2">
                <Camera className="w-4 h-4 text-amber-500" />
                <span>Upload Product Photos (4 to 6 Images)</span>
              </h3>
              <span className={`text-[10px] font-black px-2.5 py-0.5 rounded ${
                uploadedPhotos.length >= 4 ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/40' : 'bg-amber-500/20 text-amber-400 border border-amber-500/40'
              }`}>
                {uploadedPhotos.length} / 6 Uploaded
              </span>
            </div>

            {/* Upload Action Drag-Drop / Button Container */}
            <div className={`p-4 rounded-xl border-2 border-dashed ${isDarkMode ? 'bg-slate-900/90 border-amber-500/40' : 'bg-slate-50 border-amber-400'} text-center space-y-3`}>
              <div className="w-10 h-10 rounded-full bg-amber-500/20 text-amber-400 flex items-center justify-center mx-auto">
                <Upload className="w-5 h-5" />
              </div>
              <div>
                <h4 className="text-xs font-bold text-slate-200">Drag & Drop Product Evidence Photos</h4>
                <p className={`text-[10px] ${textSub} mt-0.5`}>Clear photos of Front Label, MRP Declarations, Scale Reading & Bill</p>
              </div>

              <div className="flex items-center justify-center gap-3 pt-1">
                <label className="bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-slate-950 text-xs font-bold px-4 py-2 rounded-lg cursor-pointer flex items-center gap-2 shadow-md transition-all">
                  <Plus className="w-4 h-4 stroke-[3]" />
                  <span>Choose Images to Upload</span>
                  <input
                    type="file"
                    multiple
                    accept="image/*"
                    onChange={handleFileUpload}
                    className="hidden"
                  />
                </label>
              </div>
              <span className={`text-[10px] block ${textSub}`}>Accepted format: JPG, PNG, WEBP (Max 10MB per file)</span>
            </div>

            {/* List of Uploaded Photos */}
            <div className="space-y-2">
              <label className="text-[11px] font-semibold text-slate-300">Uploaded Evidence Files ({uploadedPhotos.length}):</label>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                {uploadedPhotos.map((photo, idx) => (
                  <div key={idx} className={`p-2 rounded-lg border ${isDarkMode ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200'} flex items-center justify-between text-xs`}>
                    <div className="flex items-center space-x-2 truncate">
                      <span className="w-5 h-5 rounded-full bg-amber-500/20 text-amber-400 text-[10px] font-bold flex items-center justify-center shrink-0">
                        {idx + 1}
                      </span>
                      <div className="truncate">
                        <div className="font-mono text-amber-400 text-[11px] truncate">{photo.name}</div>
                        <div className="text-[9px] text-slate-400">{photo.type}</div>
                      </div>
                    </div>
                    <button
                      type="button"
                      onClick={(e) => {
                        e.stopPropagation();
                        handleRemovePhoto(idx);
                      }}
                      className="p-1 text-slate-500 hover:text-rose-400 transition-colors shrink-0"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                ))}
              </div>
            </div>

            {/* Optional Retail Invoice Upload Action */}
            <div className={`p-3 rounded-lg border ${isDarkMode ? 'bg-slate-900/60 border-slate-800' : 'bg-slate-50 border-slate-200'} flex items-center justify-between text-xs`}>
              <span className="font-bold flex items-center gap-1.5 text-slate-200">
                <FileText className="w-4 h-4 text-blue-400" />
                <span>Retail Purchase Invoice / Cash Memo</span>
                <span className="text-blue-400 text-[10px] font-mono bg-blue-500/20 px-1.5 py-0.5 rounded">(OPTIONAL)</span>
              </span>
              <label className="bg-slate-800 hover:bg-slate-700 text-slate-200 text-[10px] font-bold px-3 py-1.5 rounded-lg cursor-pointer transition-all border border-slate-700">
                Upload Invoice
                <input type="file" accept="image/*,.pdf" className="hidden" />
              </label>
            </div>
          </div>

        </div>

        {/* ========================================================================= */}
        {/* RIGHT COLUMN (6 COLS): LARGE EXAMPLE IMAGES, AI ANALYSIS & SUBMIT         */}
        {/* ========================================================================= */}
        <div className="lg:col-span-6 space-y-6">
          
          {/* Card 1: Sample Photo Evidence Examples (Enlarged & Prominent) */}
          <div className={`${bgCard} border rounded-xl p-5 space-y-4 shadow-sm`}>
            <div className="flex items-center justify-between border-b border-slate-800/80 pb-2.5">
              <h3 className="text-sm font-bold flex items-center gap-2">
                <Info className="w-4 h-4 text-amber-500" />
                <span>Sample Photo Evidence Guidelines (Photo Examples)</span>
              </h3>
              <span className="text-[10px] bg-amber-500/20 text-amber-400 border border-amber-500/30 px-2.5 py-0.5 rounded font-bold">
                4 Reference Examples
              </span>
            </div>

            <p className={`text-xs ${textSub}`}>
              Reference guide showing high-quality sample photos for maximum compliance & fast processing:
            </p>

            {/* 4 Enlarged Example Photo Cards Grid */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              
              {/* 1. Front (MRP) */}
              <div className={`p-3 rounded-xl border ${isDarkMode ? 'bg-slate-900 border-slate-800' : 'bg-slate-50 border-slate-200'} space-y-2.5 flex flex-col justify-between shadow-md`}>
                <div className="h-44 rounded-lg overflow-hidden border border-slate-700 relative bg-slate-950 group">
                  <img 
                    src="/images/sample_front_mrp.jpg" 
                    alt="Front MRP Sample" 
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" 
                  />
                  <span className="absolute top-2 left-2 bg-emerald-950/90 text-emerald-400 border border-emerald-500/50 text-[10px] font-bold px-2 py-0.5 rounded shadow">
                    ✓ Correct
                  </span>
                </div>
                <div>
                  <div className="text-xs font-black text-emerald-400 flex items-center justify-between">
                    <span>1. Front Package (MRP)</span>
                    <span className="text-[9px] bg-emerald-500/20 text-emerald-300 px-1.5 py-0.5 rounded font-mono">Mandatory</span>
                  </div>
                  <p className="text-[10px] text-slate-400 mt-1 leading-snug">
                    Capture clear front label showing brand name, product description & visible MRP print.
                  </p>
                </div>
              </div>

              {/* 2. Declarations */}
              <div className={`p-3 rounded-xl border ${isDarkMode ? 'bg-slate-900 border-slate-800' : 'bg-slate-50 border-slate-200'} space-y-2.5 flex flex-col justify-between shadow-md`}>
                <div className="h-44 rounded-lg overflow-hidden border border-slate-700 relative bg-slate-950 group">
                  <img 
                    src="/images/sample_declarations.jpg" 
                    alt="Declarations Sample" 
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" 
                  />
                  <span className="absolute top-2 left-2 bg-emerald-950/90 text-emerald-400 border border-emerald-500/50 text-[10px] font-bold px-2 py-0.5 rounded shadow">
                    ✓ Correct
                  </span>
                </div>
                <div>
                  <div className="text-xs font-black text-emerald-400 flex items-center justify-between">
                    <span>2. Mandated Declarations</span>
                    <span className="text-[9px] bg-emerald-500/20 text-emerald-300 px-1.5 py-0.5 rounded font-mono">Mandatory</span>
                  </div>
                  <p className="text-[10px] text-slate-400 mt-1 leading-snug">
                    Back panel showing Batch No, Mfg Date, Net Qty declaration & Manufacturer details.
                  </p>
                </div>
              </div>

              {/* 3. Scale Reading */}
              <div className={`p-3 rounded-xl border ${isDarkMode ? 'bg-slate-900 border-slate-800' : 'bg-slate-50 border-slate-200'} space-y-2.5 flex flex-col justify-between shadow-md`}>
                <div className="h-44 rounded-lg overflow-hidden border border-slate-700 relative bg-slate-950 group">
                  <img 
                    src="/images/sample_scale_reading.jpg" 
                    alt="Scale Reading Sample" 
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" 
                  />
                  <span className="absolute top-2 left-2 bg-rose-950/90 text-rose-300 border border-rose-500/50 text-[10px] font-bold px-2 py-0.5 rounded shadow">
                    ⚠️ Weight Shortage
                  </span>
                </div>
                <div>
                  <div className="text-xs font-black text-rose-400 flex items-center justify-between">
                    <span>3. Scale Reading (Weight)</span>
                    <span className="text-[9px] bg-rose-500/20 text-rose-300 px-1.5 py-0.5 rounded font-mono">Mandatory</span>
                  </div>
                  <p className="text-[10px] text-slate-400 mt-1 leading-snug">
                    Calibrated scale readout displaying exact package weight vs statutory declaration.
                  </p>
                </div>
              </div>

              {/* 4. Retail Bill (OPTIONAL) */}
              <div className={`p-3 rounded-xl border ${isDarkMode ? 'bg-slate-900 border-slate-800' : 'bg-slate-50 border-slate-200'} space-y-2.5 flex flex-col justify-between shadow-md`}>
                <div className="h-44 rounded-lg overflow-hidden border border-slate-700 relative bg-slate-950 group">
                  <img 
                    src="/images/sample_retail_bill.jpg" 
                    alt="Retail Bill Sample" 
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" 
                  />
                  <span className="absolute top-2 left-2 bg-blue-950/90 text-blue-300 border border-blue-500/50 text-[10px] font-bold px-2 py-0.5 rounded shadow">
                    📄 Purchase Proof
                  </span>
                </div>
                <div>
                  <div className="text-xs font-black text-blue-400 flex items-center justify-between">
                    <span>4. Retail Purchase Bill</span>
                    <span className="text-[9px] bg-blue-500/20 text-blue-300 px-1.5 py-0.5 rounded font-bold font-mono">OPTIONAL</span>
                  </div>
                  <p className="text-[10px] text-slate-400 mt-1 leading-snug">
                    Cash memo / tax invoice showing store name, purchase date & commodity item line.
                  </p>
                </div>
              </div>

            </div>
          </div>

          {/* Card 2: AI Metrology Optical Analysis */}
          <div className="bg-[#0D1F3C] text-white border border-blue-900 rounded-xl p-5 space-y-3.5 shadow-md">
            <div className="flex items-center justify-between border-b border-blue-800/80 pb-2.5">
              <span className="text-xs font-bold text-amber-400 flex items-center gap-1.5">
                <Sparkles className="w-4 h-4" /> AI METROLOGY OPTICAL ANALYSIS
              </span>
              <span className="text-[10px] text-blue-200 font-mono">Model LM-Net v4.2</span>
            </div>

            <div className="space-y-2 text-xs">
              <div className="flex justify-between text-blue-100/90">
                <span>Declared Nominal Qty:</span>
                <span className="font-bold font-mono text-white">1000 ml</span>
              </div>
              <div className="flex justify-between text-rose-300">
                <span>Optical Deficit Measurement:</span>
                <span className="font-bold font-mono text-rose-300">855 ml (± 4ml)</span>
              </div>
              <div className="flex justify-between text-blue-200">
                <span>Statutory Tolerable Error (MPE):</span>
                <span className="font-mono">-15 ml maximum allowed</span>
              </div>
            </div>

            <div className="bg-rose-950/80 border border-rose-700/80 p-3 rounded-lg text-xs text-rose-200 space-y-1">
              <div className="font-bold text-rose-300 flex items-center gap-1">
                <AlertCircle className="w-3.5 h-3.5" /> Critical Violation Confirmed
              </div>
              <p className="text-[11px] text-rose-200/90 leading-snug">
                Actual shortage of 145 ml (14.5% deficit); exceeds permissible error threshold 9.6x under PCR 2011 Schedule 2.
              </p>
            </div>
          </div>

          {/* Card 3: Incentive Estimator & Submit Action */}
          <div className="space-y-4">
            <div className={`${bgCard} border rounded-xl p-5 space-y-3 shadow-sm`}>
              <div className="flex items-center justify-between border-b border-slate-800/80 pb-2">
                <h3 className="text-sm font-bold flex items-center gap-2">
                  <Award className="w-4 h-4 text-amber-500" />
                  <span>Incentive Estimator (Reward Points)</span>
                </h3>
                <span className="text-[10px] text-amber-400 font-bold">Rule 32A Multiplier</span>
              </div>

              <div className="space-y-2 text-xs">
                <div className="flex justify-between">
                  <span className={textSub}>Statutory Base Points:</span>
                  <span className="font-mono font-bold">2,500 Points</span>
                </div>
                <div className="border-t border-slate-800/80 pt-2 flex justify-between items-center">
                  <span className="font-bold">Potential Reward Points:</span>
                  <span className="text-xl font-black text-amber-400 font-mono">2,500 Points</span>
                </div>
              </div>
            </div>

            {/* Submit Error Message */}
            {submitError && (
              <div className="bg-rose-950/80 border border-rose-600 rounded-xl p-3.5 text-xs text-rose-200 flex items-center space-x-2">
                <AlertCircle className="w-4 h-4 text-rose-400 shrink-0" />
                <span>{submitError}</span>
              </div>
            )}

            {/* Inline Confirmation Card when submitted */}
            {submittedToken && (
              <div className="bg-emerald-950/90 border border-emerald-500 rounded-xl p-4 text-emerald-200 space-y-2 shadow-lg">
                <div className="flex items-center space-x-2">
                  <CheckCircle2 className="w-5 h-5 text-emerald-400 shrink-0" />
                  <span className="font-bold text-sm">Complaint Registered Successfully!</span>
                </div>
                <p className="text-xs text-emerald-300">
                  Tracking Token ID: <strong className="font-mono text-white">{submittedToken}</strong> • +500 Reward Points added.
                </p>
                <button
                  type="button"
                  onClick={() => setCitizenTab('MY_COMPLAINTS')}
                  className="w-full bg-emerald-500 hover:bg-emerald-400 text-slate-950 text-xs font-bold py-2 rounded-lg transition-all cursor-pointer"
                >
                  Track in My Complaints →
                </button>
              </div>
            )}

            {/* Submit Action Button */}
            <button
              type="submit"
              disabled={isSubmitting}
              onClick={(e) => handleSubmit(e)}
              className="w-full bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-slate-950 font-black py-3.5 rounded-xl shadow-xl shadow-amber-500/20 flex items-center justify-center space-x-2 text-sm transition-all cursor-pointer"
            >
              {isSubmitting ? (
                <span>Logging Complaint & Issuing Legal Token...</span>
              ) : (
                <>
                  <CheckCircle2 className="w-5 h-5" />
                  <span>Submit Complaint & Issue Legal Token</span>
                </>
              )}
            </button>
          </div>

        </div>

      </form>
    </div>
  );
}

