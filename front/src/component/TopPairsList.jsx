import React from 'react';
import { Trophy, ArrowRight, TrendingUp, Sprout } from 'lucide-react';

const TopPairsList = ({ pairs, onSelectPair }) => {
  // Guard clause: if no data, don't render anything
  if (!pairs || pairs.length === 0) return null;

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mb-8 animate-fade-in">
      {/* Section Header */}
      <div className="flex items-center gap-3 mb-6 border-b border-gray-100 pb-4">
        <div className="bg-yellow-100 p-2 rounded-lg">
            <Trophy className="text-yellow-600" size={24} />
        </div>
        <div>
          <h3 className="font-bold text-lg text-slate-800">Top 10 Genetically Compatible Pairs</h3>
          <p className="text-xs text-gray-500">
            Ranked by AI based on symbiotic potential, resilience, and yield traits.
          </p>
        </div>
      </div>

      {/* Table */}
      <div className="overflow-x-auto">
        <table className="w-full text-sm text-left">
          <thead className="bg-gray-50 text-gray-500 font-bold uppercase text-xs">
            <tr>
              <th className="px-4 py-3 rounded-tl-lg">Rank</th>
              <th className="px-4 py-3">Pairing</th>
              <th className="px-4 py-3">Compatibility</th>
              <th className="px-4 py-3">Rec. Zone</th>
              <th className="px-4 py-3 rounded-tr-lg text-right">Analysis</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {pairs.map((pair, index) => (
              <tr 
                key={index} 
                onClick={() => onSelectPair(pair)}
                className="hover:bg-emerald-50/50 cursor-pointer transition-colors group"
              >
                {/* Rank */}
                <td className="px-4 py-4 font-bold text-slate-400">
                  #{index + 1}
                </td>

                {/* Plant Names */}
                <td className="px-4 py-4">
                  <div className="flex flex-col">
                    <div className="flex items-center gap-2 font-bold text-slate-700">
                        <Sprout size={14} className="text-emerald-600"/>
                        {pair.Plant_A}
                    </div>
                    <div className="flex items-center gap-2 text-xs text-emerald-600 font-medium ml-1">
                        <span>+</span> {pair.Plant_B}
                    </div>
                  </div>
                </td>

                {/* Score */}
                <td className="px-4 py-4">
                  <div className="flex items-center gap-2">
                    <div className="font-bold text-emerald-700 text-base">
                        {(pair.Score || 0).toFixed(1)}%
                    </div>
                    {/* Show icon if Future Score is higher */}
                    {pair.Future_Score > pair.Score && (
                        <div title="Projected to improve over time" className="flex items-center text-xs text-blue-500 bg-blue-50 px-1.5 py-0.5 rounded">
                            <TrendingUp size={12} className="mr-1" />
                            <span>{(pair.Future_Score).toFixed(1)}%</span>
                        </div>
                    )}
                  </div>
                </td>

                {/* Zone */}
                <td className="px-4 py-4 text-gray-600">
                  <span className="bg-white border border-gray-200 text-slate-600 px-2 py-1 rounded text-xs font-medium">
                    {pair.Zone || "Multi-Region"}
                  </span>
                </td>

                {/* Button */}
                <td className="px-4 py-4 text-right">
                  <button className="bg-white border border-gray-200 p-2 rounded-full text-gray-400 group-hover:text-emerald-600 group-hover:border-emerald-200 transition-all shadow-sm">
                    <ArrowRight size={16} />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default TopPairsList;