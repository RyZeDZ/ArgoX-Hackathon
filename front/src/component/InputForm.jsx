import React, { useState, useEffect, useRef } from 'react';
import { Loader2, Search, FlaskConical, Sprout, Check } from 'lucide-react';

// --- AUTOCOMPLETE COMPONENT ---
const AutocompleteInput = ({ label, placeholder, value, onChange, onGenusSelect }) => {
  const [suggestions, setSuggestions] = useState([]);
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [isSearching, setIsSearching] = useState(false);
  const wrapperRef = useRef(null);

  // Close dropdown if clicked outside
  useEffect(() => {
    function handleClickOutside(event) {
      if (wrapperRef.current && !wrapperRef.current.contains(event.target)) {
        setShowSuggestions(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  // Debounced Search Logic
  useEffect(() => {
    // Don't search if value is empty or very short
    if (value.length < 2) {
      setSuggestions([]);
      return;
    }

    // Debounce to prevent API flooding
    const timer = setTimeout(async () => {
      // Only search if the dropdown is supposed to be open (meaning user is typing)
      if (showSuggestions) {
        setIsSearching(true);
        try {
          const response = await fetch('http://127.0.0.1:8000/api/search-plants/', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ query: value })
          });
          
          if (response.ok) {
            const data = await response.json();
            setSuggestions(data);
          }
        } catch (error) {
          console.error("Search API Error:", error);
        } finally {
          setIsSearching(false);
        }
      }
    }, 300); // 300ms delay

    return () => clearTimeout(timer);
  }, [value, showSuggestions]);

  const handleInputChange = (e) => {
    const newVal = e.target.value;
    onChange(newVal);
    setShowSuggestions(true);
    
    // CRITICAL: If user starts typing again, clear the "Selected Genus"
    // This forces the app to look for a new match or use raw input
    onGenusSelect(null); 
  };

  const handleSelect = (item) => {
    // 1. Update the visible input to show what they picked
    onChange(item.display_name); // e.g., "Shrubby Indian mallow (Abutilon)"
    
    // 2. Store the scientific Genus for the backend logic
    onGenusSelect(item.genus);   // e.g., "Abutilon"
    
    // 3. Close UI
    setSuggestions([]);
    setShowSuggestions(false);
  };

  return (
    <div className="relative" ref={wrapperRef}>
      <label className="block text-xs font-semibold text-gray-500 mb-2">{label}</label>
      <div className="relative">
        <input 
          type="text"
          value={value}
          onChange={handleInputChange}
          onFocus={() => value.length > 1 && setShowSuggestions(true)}
          placeholder={placeholder}
          className="w-full bg-gray-50 border border-gray-200 text-gray-700 py-3 px-4 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 transition-all placeholder-gray-400"
        />
        
        {/* Loading Spinner or Checkmark icon */}
        <div className="absolute right-3 top-3.5 text-gray-400">
           {isSearching ? <Loader2 size={18} className="animate-spin text-emerald-500" /> : <Search size={18} />}
        </div>
      </div>

      {/* SUGGESTION DROPDOWN */}
      {showSuggestions && suggestions.length > 0 && (
        <ul className="absolute z-50 w-full bg-white border border-gray-200 rounded-lg shadow-xl mt-1 max-h-60 overflow-y-auto">
          {suggestions.map((item, idx) => (
            <li 
              key={idx}
              onClick={() => handleSelect(item)}
              className="px-4 py-3 hover:bg-emerald-50 cursor-pointer text-sm text-gray-700 border-b border-gray-50 last:border-0 flex justify-between items-center group"
            >
              <div>
                <span className="font-semibold block">{item.common_name}</span>
                <span className="text-xs text-gray-400 italic font-medium">Scientific: {item.genus}</span>
              </div>
              <Check size={14} className="text-emerald-600 opacity-0 group-hover:opacity-100 transition-opacity" />
            </li>
          ))}
        </ul>
      )}
      
      {/* Empty State / No Results */}
      {showSuggestions && !isSearching && value.length > 2 && suggestions.length === 0 && (
        <div className="absolute z-50 w-full bg-white border border-gray-200 rounded-lg shadow-lg mt-1 p-3 text-center text-xs text-gray-400">
          No matches found in database. <br/> Try using the scientific Genus directly.
        </div>
      )}
    </div>
  );
};

// --- MAIN INPUT FORM ---
const InputForm = ({ onCalculate, loading, activeTab }) => {
  // 1. Display Values (What appears in the text box)
  const [plantAInput, setPlantAInput] = useState('');
  const [plantBInput, setPlantBInput] = useState('');

  // 2. Scientific Values (What gets sent to the prediction API)
  const [plantAGenus, setPlantAGenus] = useState(null);
  const [plantBGenus, setPlantBGenus] = useState(null);

  // Clear B when switching tabs
  useEffect(() => {
    if (activeTab === 'single') {
      setPlantBInput('');
      setPlantBGenus(null);
    }
  }, [activeTab]);

  const handleSubmit = () => {
    if (!plantAInput.trim()) return;
    if (activeTab === 'cross' && !plantBInput.trim()) return;

    // INTELLIGENT SELECTION:
    // If user clicked a suggestion, `plantAGenus` is set (e.g., "Abutilon").
    // If user typed "Abutilon" manually and ignored suggestions, `plantAGenus` is null.
    // In that case, we send the raw input `plantAInput` assuming they typed the Genus.
    
    const finalPlantA = plantAGenus || plantAInput;
    const finalPlantB = plantBGenus || plantBInput;

    onCalculate(finalPlantA, finalPlantB);
  };

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-8 mb-8 relative">
      <div className="flex items-center gap-3 mb-6">
        {activeTab === 'single' 
          ? <Search className="text-emerald-600" /> 
          : <FlaskConical className="text-emerald-600" />
        }
        <h3 className="text-lg font-bold text-slate-800">
          {activeTab === 'single' ? 'Find Compatible Hybrid Partner' : 'Evaluate Cross-Breeding Pair'}
        </h3>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
        <div className={activeTab === 'single' ? 'md:col-span-2' : ''}>
          <AutocompleteInput 
            label={activeTab === 'single' ? 'Target Plant (Common Name or Genus)' : 'Parent A (Common Name or Genus)'}
            placeholder={activeTab === 'single' ? "e.g. Indian Mallow, Wheat..." : "e.g. Abies..."}
            value={plantAInput}
            onChange={setPlantAInput}
            onGenusSelect={setPlantAGenus}
          />
        </div>

        {activeTab === 'cross' && (
          <div>
            <AutocompleteInput 
              label="Parent B (Common Name or Genus)"
              placeholder="e.g. Clover..."
              value={plantBInput}
              onChange={setPlantBInput}
              onGenusSelect={setPlantBGenus}
            />
          </div>
        )}
      </div>

      <div className="flex justify-end">
        <button 
          onClick={handleSubmit}
          disabled={loading || !plantAInput || (activeTab === 'cross' && !plantBInput)}
          className="bg-emerald-700 hover:bg-emerald-800 text-white font-medium py-2.5 px-8 rounded-lg shadow-sm transition-colors flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {loading ? <Loader2 size={18} className="animate-spin" /> : <Sprout size={18} />}
          {loading ? 'Analyzing...' : 'Run Analysis'}
        </button>
      </div>
    </div>
  );
};

export default InputForm;