import React from 'react';
import { Heart } from 'lucide-react';

const Header = () => {
  return (
    <header className="bg-white border-b border-gray-100 py-4 px-6 md:px-12 sticky top-0 z-10">
      <div className="max-w-7xl mx-auto flex justify-between items-center">
        <div className="flex items-center gap-2">
          <div className="bg-emerald-500 p-1.5 rounded-lg text-white">
            <Heart size={20} fill="white" />
          </div>
          <div className="leading-tight">
            <h1 className="text-emerald-700 font-bold text-lg tracking-tight">AgroX Intelligence</h1>
            <p className="text-xs text-gray-400 font-medium">Plant Breeding AI Assistant</p>
          </div>
        </div>
        <div className="hidden md:flex bg-gray-100 rounded-lg p-1 gap-1">
          <button className="px-4 py-1.5 text-sm font-medium text-gray-500 hover:text-gray-700">Data Explorer</button>
          <button className="px-4 py-1.5 text-sm font-medium bg-white text-emerald-600 shadow-sm rounded-md border border-gray-200">AI Predictor</button>
        </div>
      </div>
    </header>
  );
};

export default Header;