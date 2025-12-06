import React from 'react';

const TabSwitcher = ({ activeTab, setActiveTab }) => {
  return (
    <div className="flex justify-center mb-8">
      <div className="bg-white p-1 rounded-xl border border-gray-200 shadow-sm inline-flex">
        <button 
          onClick={() => setActiveTab('single')}
          className={`px-6 py-2 rounded-lg text-sm font-medium transition-colors ${activeTab === 'single' ? 'bg-emerald-100 text-emerald-700 font-semibold' : 'text-gray-500 hover:bg-gray-50'}`}
        >
          Single Genus Discovery
        </button>
        <button 
          onClick={() => setActiveTab('cross')}
          className={`px-6 py-2 rounded-lg text-sm font-medium transition-colors ${activeTab === 'cross' ? 'bg-emerald-100 text-emerald-700 font-semibold' : 'text-gray-500 hover:bg-gray-50'}`}
        >
          Pair Compatibility Check
        </button>
      </div>
    </div>
  );
};

export default TabSwitcher;
