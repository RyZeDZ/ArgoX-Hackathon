import React from 'react';
import { FileText, AlertTriangle, Sprout, Activity } from 'lucide-react';

const ResultsSection = ({ result, activeTab }) => {
  if (!result) return null;

  // --- ERROR STATE ---
  if (result.status === "Error") {
    return (
      <div className="bg-red-50 border border-red-200 rounded-xl p-6 mb-6 animate-fade-in">
        <div className="flex items-center gap-3 text-red-700 mb-2">
          <AlertTriangle size={24} />
          <h3 className="text-lg font-bold">Analysis Error</h3>
        </div>
        <p className="text-sm text-red-800 bg-red-100 p-3 rounded-lg border border-red-200">
          {result.reason || "Unable to process request."}
        </p>
      </div>
    );
  }

  // --- EXTRACT DATA ---
  const {
    plant_a_name: plantA,
    plant_b_name: plantB,
    percentage: score,
    futureScore,
    status,
    resilience,
    recommended_zone: zone,
    recommended_states: states,
    traits,
    agronomics,
    explanation
  } = result;

  const isCompatible = status === "Compatible";

  // Helper: "drought_tolerance" → "Drought Tolerance"
  const formatTraitName = (key) =>
    key.replace(/_/g, " ").replace(/\b\w/g, (l) => l.toUpperCase());

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-6 animate-fade-in">

      {/* --- LEFT CARD: SCORES & NAMES --- */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 md:col-span-1 flex flex-col h-full">
        <h4 className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-6">
          Model Output
        </h4>

        {/* Dynamic Title */}
        <div className="mb-6 bg-emerald-50 border border-emerald-100 p-3 rounded-lg text-center">
          <span className="text-xs text-emerald-600 font-bold uppercase block mb-1">
            {activeTab === 'single' ? "Best Match Discovered" : "Pair Analysis"}
          </span>

          <div className="flex flex-col items-center justify-center gap-1 text-emerald-800 font-bold">
            <div className="flex items-center gap-2">
              <Sprout size={18} />
              <span>{plantA}</span>
            </div>
            <span className="text-xs text-gray-400">+</span>
            <div className="flex items-center gap-2">
              <Sprout size={18} />
              <span>{plantB}</span>
            </div>
          </div>
        </div>

        {/* SCORES */}
        <div className="text-center mb-8">
          <div className={`text-5xl font-bold mb-1 ${!isCompatible ? "text-yellow-600" : "text-emerald-600"}`}>
            {(score || 0).toFixed(1)}%
          </div>

          <div className={`font-medium px-3 py-1 rounded-full inline-block text-sm ${!isCompatible ? "bg-yellow-100 text-yellow-800" : "bg-emerald-100 text-emerald-800"}`}>
            {status}
          </div>

          {futureScore !== null && futureScore !== undefined && (
            <div className="text-sm text-gray-600 mt-2">
              Future Projection: <span className="font-bold text-emerald-700">{futureScore.toFixed(1)}%</span>
            </div>
          )}

          {resilience && (
            <div className="text-sm text-blue-700 mt-2 font-medium bg-blue-50 py-1 px-2 rounded inline-block">
              Status: {resilience}
            </div>
          )}
        </div>

        {/* ZONE & STATES */}
        <div className="mt-auto space-y-3 pt-4 border-t border-gray-100">
          {zone && (
            <div className="text-center text-sm font-bold text-slate-700">
              Recommended Zone:
              <span className="text-emerald-600 block text-lg">{zone}</span>
            </div>
          )}

          {states && states.length > 0 && (
            <div className="text-center">
              <span className="text-xs font-bold text-gray-400 uppercase">States</span>
              <p className="text-xs text-slate-600 mt-1 leading-relaxed">
                {states.join(", ")}
              </p>
            </div>
          )}
        </div>
      </div>

      {/* --- RIGHT CARD: TRAITS + AGRONOMICS + EXPLANATION --- */}
      <div className="bg-emerald-50/50 rounded-xl border border-emerald-100 p-6 md:col-span-2 flex flex-col">
        
        {/* TRAITS */}
        <div className="mb-6">
          <h4 className="flex items-center gap-2 font-bold text-emerald-800 mb-4">
            <Activity size={20} /> Predicted Synergy Traits
          </h4>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {Object.entries(traits).map(([key, value]) =>
              value !== null && (
                <div key={key} className="bg-white p-3 rounded-lg border border-emerald-100 shadow-sm flex justify-between items-center">
                  <span className="text-sm text-gray-600 font-medium">{formatTraitName(key)}</span>
                  <span className="text-sm font-bold text-emerald-700">{value}</span>
                </div>
              )
            )}
          </div>
        </div>

        {/* AGRONOMICS (NEW) */}
        {agronomics && (
          <div className="mb-6">
            <h4 className="flex items-center gap-2 font-bold text-emerald-800 mb-4">
              <Activity size={20} /> Agronomics Insights
            </h4>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {Object.entries(agronomics).map(([key, value]) =>
                value !== null && (
                  <div key={key} className="bg-white p-3 rounded-lg border border-emerald-100 shadow-sm flex justify-between items-center">
                    <span className="text-sm text-gray-600 font-medium">{formatTraitName(key)}</span>
                    <span className="text-sm font-bold text-emerald-700">{value}</span>
                  </div>
                )
              )}
            </div>
          </div>
        )}

        {/* EXPLANATION */}
        <div className="mt-auto">
          <div className="flex items-center gap-2 mb-2 text-emerald-800 border-t border-emerald-200 pt-4">
            <FileText size={20} />
            <h4 className="font-bold">AI Analysis</h4>
          </div>

          <p className="text-sm text-slate-700 leading-relaxed whitespace-pre-line">
            {explanation}
          </p>
        </div>

      </div>

    </div>
  );
};

export default ResultsSection;
