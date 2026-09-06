'use client';

import React, { useEffect, useRef, useState } from 'react';
import { MapPin, X } from 'lucide-react';

interface LeafletRadarMapProps {
  onClose?: () => void;
}

export default function LeafletRadarMap({ onClose }: LeafletRadarMapProps) {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<any>(null);

  useEffect(() => {
    if (typeof window === 'undefined' || !mapContainerRef.current) return;

    // Dynamically inject Leaflet CSS if missing
    if (!document.getElementById('leaflet-css')) {
      const link = document.createElement('link');
      link.id = 'leaflet-css';
      link.rel = 'stylesheet';
      link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
      document.head.appendChild(link);
    }

    // Dynamically import Leaflet JS to prevent SSR issues
    import('leaflet').then((L) => {
      if (mapInstanceRef.current) return;

      const indiaBounds = L.latLngBounds([6.5, 68.0], [35.5, 97.5]);

      const map = L.map(mapContainerRef.current!, {
        center: [21.5, 78.9629],
        zoom: 5.5,
        minZoom: 5.2,
        maxZoom: 18,
        worldCopyJump: false,
        maxBounds: indiaBounds,
        maxBoundsViscosity: 1.0,
        zoomControl: false,
      });

      mapInstanceRef.current = map;

      // Reliable OpenStreetMap tiles locked strictly to India (no world wrap, no sliding to Africa/Europe)
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
        subdomains: 'abc',
        maxZoom: 19,
        noWrap: true,
        bounds: indiaBounds,
      }).addTo(map);

      // Custom marker icon creation with glowing circles
      const createGlowIcon = (colorHex: string, pulse: boolean = false) => {
        return L.divIcon({
          className: 'custom-leaflet-marker',
          html: `<div style="position: relative; width: 24px; height: 24px; display: flex; align-items: center; justify-content: center;">
            <div style="position: absolute; width: 20px; height: 20px; border-radius: 50%; background-color: ${colorHex}; opacity: 0.35; ${pulse ? 'animation: ping 1.5s cubic-bezier(0, 0, 0.2, 1) infinite;' : ''}"></div>
            <div style="width: 12px; height: 12px; border-radius: 50%; background-color: ${colorHex}; border: 2px solid #ffffff; box-shadow: 0 0 12px ${colorHex};"></div>
          </div>`,
          iconSize: [24, 24],
          iconAnchor: [12, 12]
        });
      };

      // Enforcement Hub Markers Data
      const markersData = [
        { lat: 19.0760, lng: 72.8777, name: 'Mumbai Suburban Circle (Zones 1-4)', category: 'High Alert', color: '#f43f5e', inspections: '4,120', violations: '620', recovery: '₹2.10 Cr' },
        { lat: 18.5204, lng: 73.8567, name: 'Pune Metro & Pimpri-Chinchwad', category: 'Moderate Watch', color: '#f59e0b', inspections: '3,210', violations: '480', recovery: '₹1.60 Cr' },
        { lat: 21.1458, lng: 79.0882, name: 'Nagpur & Vidarbha Enforcement Hub', category: 'Compliant', color: '#10b981', inspections: '1,840', violations: '210', recovery: '₹82.0 L' },
        { lat: 19.9975, lng: 73.7898, name: 'Nashik & Sambhajinagar Belt', category: 'Compliant', color: '#06b6d4', inspections: '1,420', violations: '165', recovery: '₹54.5 L' },
        { lat: 19.2183, lng: 72.9781, name: 'Thane Industrial Zone', category: 'High Alert', color: '#f43f5e', inspections: '2,950', violations: '410', recovery: '₹1.15 Cr' },
        { lat: 19.8762, lng: 75.3433, name: 'Chhatrapati Sambhajinagar Circle', category: 'Moderate Watch', color: '#f59e0b', inspections: '1,890', violations: '230', recovery: '₹42.0 L' },
        { lat: 28.6139, lng: 77.2090, name: 'Enforcement HQ Delhi', category: 'Apex Command', color: '#3b82f6', inspections: 'Direct HQ Command', violations: 'Central Registry', recovery: 'National Oversight' },
      ];

      markersData.forEach((m) => {
        const marker = L.marker([m.lat, m.lng], {
          icon: createGlowIcon(m.color, m.category === 'High Alert')
        }).addTo(map);

        const popupContent = `
          <div style="font-family: sans-serif; padding: 6px; color: #0f172a; min-width: 180px;">
            <div style="font-size: 11px; font-weight: 800; color: #1e293b; margin-bottom: 2px;">${m.name}</div>
            <div style="font-size: 10px; font-weight: 700; color: ${m.color}; text-transform: uppercase; margin-bottom: 6px;">${m.category}</div>
            <div style="font-size: 10px; border-top: 1px solid #e2e8f0; padding-top: 4px; display: flex; flex-direction: column; gap: 2px;">
              <div><strong>Inspections:</strong> ${m.inspections}</div>
              <div><strong>Violations:</strong> ${m.violations}</div>
              <div style="color: #059669; font-weight: 700;"><strong>Recovery:</strong> ${m.recovery}</div>
            </div>
          </div>
        `;
        marker.bindPopup(popupContent);
      });
    });

    return () => {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    };
  }, []);

  const handleZoomIn = () => {
    if (mapInstanceRef.current) mapInstanceRef.current.zoomIn();
  };

  const handleZoomOut = () => {
    if (mapInstanceRef.current) mapInstanceRef.current.zoomOut();
  };

  return (
    <div className="relative w-full h-[520px] rounded-2xl overflow-hidden border border-slate-800 bg-[#0b0f19] shadow-2xl font-sans">
      {/* Map Element Container */}
      <div ref={mapContainerRef} className="w-full h-full z-0 [&_.leaflet-tile]:!brightness-[0.65] [&_.leaflet-tile]:!invert-[1] [&_.leaflet-tile]:!contrast-[1.4] [&_.leaflet-tile]:!hue-rotate-[200deg] [&_.leaflet-container]:!bg-[#0b0f19]" />

      {/* Top Banner Overlay */}
      <div className="absolute top-4 left-4 z-10 bg-[#0D1F3C]/90 backdrop-blur-md border border-blue-500/40 text-white p-3 rounded-xl shadow-xl flex items-center space-x-3">
        <div className="w-8 h-8 rounded-lg bg-amber-500 text-slate-950 flex items-center justify-center font-bold">
          <MapPin className="w-5 h-5" />
        </div>
        <div>
          <div className="text-xs font-black text-white flex items-center gap-2">
            <span>Leaflet GIS Spatial Radar & District Enforcement Heatmap</span>
            <span className="bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 text-[9px] px-2 py-0.5 rounded font-mono">
              Live GIS / India Radar
            </span>
          </div>
          <p className="text-[10px] text-blue-200/90">
            Real-time geospatial monitoring across Maharashtra 36 Divisions & Central HQ
          </p>
        </div>
      </div>

      {/* Custom Zoom Controls matching Image 2 top left */}
      <div className="absolute top-4 right-4 z-10 flex flex-col space-y-1">
        <button
          onClick={handleZoomIn}
          className="w-9 h-9 bg-slate-900/90 hover:bg-slate-800 border border-slate-700 text-white rounded-lg flex items-center justify-center font-bold text-lg shadow-lg cursor-pointer transition-all"
          title="Zoom In"
        >
          +
        </button>
        <button
          onClick={handleZoomOut}
          className="w-9 h-9 bg-slate-900/90 hover:bg-slate-800 border border-slate-700 text-white rounded-lg flex items-center justify-center font-bold text-lg shadow-lg cursor-pointer transition-all"
          title="Zoom Out"
        >
          −
        </button>
        {onClose && (
          <button
            onClick={onClose}
            className="w-9 h-9 bg-rose-600/90 hover:bg-rose-500 text-white rounded-lg flex items-center justify-center font-bold shadow-lg cursor-pointer transition-all mt-2"
            title="Close GIS Map"
          >
            <X className="w-5 h-5" />
          </button>
        )}
      </div>

      {/* Bottom Left Legend Overlay matching Image 2 */}
      <div className="absolute bottom-4 left-4 z-10 bg-[#081427]/90 backdrop-blur-md border border-blue-900 text-white px-3.5 py-2.5 rounded-xl shadow-xl flex items-center space-x-4 text-xs font-bold">
        <div className="flex items-center space-x-1.5">
          <span className="w-3 h-3 rounded-full bg-emerald-400 shadow-[0_0_8px_#10b981]"></span>
          <span className="text-slate-200 text-[11px]">High Growth / Compliant</span>
        </div>
        <div className="flex items-center space-x-1.5">
          <span className="w-3 h-3 rounded-full bg-amber-400 shadow-[0_0_8px_#f59e0b]"></span>
          <span className="text-slate-200 text-[11px]">Medium Growth / Watch</span>
        </div>
        <div className="flex items-center space-x-1.5">
          <span className="w-3 h-3 rounded-full bg-rose-500 shadow-[0_0_8px_#f43f5e]"></span>
          <span className="text-slate-200 text-[11px]">Low Risk / High Alert</span>
        </div>
      </div>

      {/* Bottom Right Metrics Cards matching Image 2 */}
      <div className="absolute bottom-4 right-4 z-10 flex items-center space-x-2">
        <div className="bg-[#081427]/95 backdrop-blur-md border border-slate-700/80 text-white px-4 py-2 rounded-xl shadow-xl text-center min-w-[70px]">
          <div className="text-slate-400 text-[9px] uppercase font-bold tracking-wider">CITIES</div>
          <div className="text-base font-black text-amber-400 font-mono">10</div>
        </div>
        <div className="bg-[#081427]/95 backdrop-blur-md border border-slate-700/80 text-white px-4 py-2 rounded-xl shadow-xl text-center min-w-[70px]">
          <div className="text-slate-400 text-[9px] uppercase font-bold tracking-wider">ROUTES</div>
          <div className="text-base font-black text-emerald-400 font-mono">45</div>
        </div>
        <div className="bg-[#081427]/95 backdrop-blur-md border border-slate-700/80 text-white px-4 py-2 rounded-xl shadow-xl text-center min-w-[85px]">
          <div className="text-slate-400 text-[9px] uppercase font-bold tracking-wider">POPULATION</div>
          <div className="text-base font-black text-white font-mono">128M</div>
        </div>
      </div>
    </div>
  );
}
