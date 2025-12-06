import React, { useState, useEffect } from 'react';
import Header from './component/Header';
import Footer from './component/Footer';
import HeroSection from './component/HeroSection';
import TabSwitcher from './component/TabSwitcher';
import InputForm from './component/InputForm';
import ResultsSection from './component/ResultsSection';
import MapSection from './component/MapSection';
import TopPairsList from './component/TopPairsList';

// --- COORDINATE DATABASE ---
const ALGERIA_COORDS = {
  "adrar": { lat: 27.8743, lng: -0.2939 },
  "chlef": { lat: 36.1652, lng: 1.3345 },
  "laghouat": { lat: 33.8000, lng: 2.8651 },
  "oum el bouaghi": { lat: 35.8754, lng: 7.1135 },
  "batna": { lat: 35.5559, lng: 6.1741 },
  "bejaia": { lat: 36.7509, lng: 5.0567 },
  "biskra": { lat: 34.8505, lng: 5.7280 },
  "bechar": { lat: 31.6212, lng: -2.2121 },
  "blida": { lat: 36.4702, lng: 2.8286 },
  "bouira": { lat: 36.3748, lng: 3.9020 },
  "tamanrasset": { lat: 22.7850, lng: 5.5228 },
  "tebessa": { lat: 35.4041, lng: 8.1143 },
  "tlemcen": { lat: 34.8790, lng: -1.3158 },
  "tiaret": { lat: 35.3710, lng: 1.3169 },
  "tizi ouzou": { lat: 36.7118, lng: 4.0459 },
  "algiers": { lat: 36.7528, lng: 3.0420 },
  "alger": { lat: 36.7528, lng: 3.0420 },
  "djelfa": { lat: 34.6727, lng: 3.2630 },
  "jijel": { lat: 36.8205, lng: 5.7667 },
  "setif": { lat: 36.1898, lng: 5.4108 },
  "saida": { lat: 34.8303, lng: 0.1477 },
  "skikda": { lat: 36.8663, lng: 6.9046 },
  "sidi bel abbes": { lat: 35.1899, lng: -0.6308 },
  "annaba": { lat: 36.9009, lng: 7.7669 },
  "guelma": { lat: 36.4621, lng: 7.4260 },
  "constantine": { lat: 36.3650, lng: 6.6147 },
  "medea": { lat: 36.2641, lng: 2.7539 },
  "mostaganem": { lat: 35.9398, lng: 0.0898 },
  "msila": { lat: 35.7058, lng: 4.5419 },
  "mascara": { lat: 35.3966, lng: 0.1544 },
  "ouargla": { lat: 31.9493, lng: 5.3250 },
  "oran": { lat: 35.6969, lng: -0.6331 },
  "el bayadh": { lat: 33.6831, lng: 1.0192 },
  "illizi": { lat: 26.4833, lng: 8.4666 },
  "bordj bou arreridj": { lat: 36.0732, lng: 4.7610 },
  "boumerdes": { lat: 36.7664, lng: 3.4771 },
  "el tarf": { lat: 36.7672, lng: 8.3137 },
  "tindouf": { lat: 27.6711, lng: -8.1474 },
  "tissemsilt": { lat: 35.6072, lng: 1.8109 },
  "el oued": { lat: 33.3683, lng: 6.8674 },
  "khenchela": { lat: 35.4358, lng: 7.1433 },
  "souk ahras": { lat: 36.2863, lng: 7.9511 },
  "tipaza": { lat: 36.5897, lng: 2.4475 },
  "mila": { lat: 36.4502, lng: 6.2644 },
  "ain defla": { lat: 36.2590, lng: 1.9679 },
  "naama": { lat: 32.7500, lng: -0.3000 },
  "ain temouchent": { lat: 35.3072, lng: -1.1400 },
  "ghardaia": { lat: 32.4909, lng: 3.6734 },
  "relizane": { lat: 35.7373, lng: 0.5559 },
  "timimoun": { lat: 29.2638, lng: 0.2309 },
  "in salah": { lat: 27.1935, lng: 2.4606 }
};

const getCoordinates = (stateName) => {
  if (!stateName) return null;
  const normalized = stateName
    .toLowerCase()
    .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .replace(/['’]/g, "")
    .trim();
  return ALGERIA_COORDS[normalized];
};

const processDataToResult = (data) => {
  const returnedStates = data.States || [];
  
  const generatedMapPoints = returnedStates.map(stateName => {
    const coord = getCoordinates(stateName);
    if (coord) {
      return {
        id: stateName,
        name: stateName,
        lat: coord.lat,
        lng: coord.lng,
        intensity: 0.9,
        type: 'Recommended'
      };
    }
    return null;
  }).filter(p => p !== null);

  return {
    status: data.Compatible ? "Compatible" : "Not Compatible",
    percentage: data.Score || 0,
    futureScore: data.Future_Score || null,
    plant_a_name: data.Plant_A || "Unknown",
    plant_b_name: data.Plant_B || "Unknown",
    traits: {
      drought_tolerance: data.Traits?.Drought_Tol ?? null,
      growth_speed: data.Traits?.Growth_Speed ?? null,
      salinity_tolerance: data.Traits?.Salinity_Tol ?? null,
    },
    agronomics: {
    water_usage: data.Agronomics?.Water_Usage ?? null,
    irrigation_strategy: data.Agronomics?.Irrigation_Strategy ?? null,
    disease_pressure: data.Agronomics?.Disease_Pressure ?? null,
    pathogen_alert: data.Agronomics?.Pathogen_Alert ?? null,
    },

    recommended_zone: data.Zone || "",
    recommended_states: returnedStates,
    resilience: data.Resilience ?? null,
    explanation: data.Explanation || "",
    heatmapPoints: generatedMapPoints 
  };
};

const App = () => {
  const [activeTab, setActiveTab] = useState('single'); 
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState(null);
  const [topPairs, setTopPairs] = useState([]);

  // --- OPTIMIZED FETCH WITH LOCAL STORAGE ---
  useEffect(() => {
    const CACHE_KEY = 'top_pairs_data'; // Key name for browser storage

    const fetchTopPairs = async () => {
      // 1. Try to load from Local Storage first
      const cachedData = localStorage.getItem(CACHE_KEY);

      if (cachedData) {
        try {
          console.log("⚡ Loaded Top Pairs from Local Storage cache");
          setTopPairs(JSON.parse(cachedData));
          return; // Stop here, don't fetch from API
        } catch (e) {
          console.warn("Cache corrupted, fetching fresh data...");
          localStorage.removeItem(CACHE_KEY);
        }
      }

      // 2. If no cache, fetch from API
      try {
        console.log("🌐 Cache miss. Fetching from API...");
        const response = await fetch('http://127.0.0.1:8000/api/ranks/'); 
        const data = await response.json();
        
        if (Array.isArray(data)) {
          setTopPairs(data);
          // 3. Save to Local Storage for next time
          localStorage.setItem(CACHE_KEY, JSON.stringify(data));
          console.log("💾 Data saved to Local Storage");
        }
      } catch (error) {
        console.error("Failed to fetch top pairs:", error);
      }
    };

    fetchTopPairs();
  }, []);

  // --- OPTIONAL: Function to force refresh (clear cache) ---
  const handleRefreshCache = () => {
    localStorage.removeItem('top_pairs_data');
    window.location.reload();
  };

  const handleSelectTopPair = (pairData) => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
    setActiveTab('cross');
    const uiData = processDataToResult(pairData);
    setResult(uiData);
  };

  const handleCalculate = async (plantA, plantB) => {
    setLoading(true);
    setResult(null);

    const isSingle = activeTab === 'single';
    const endpoint = isSingle 
      ? 'http://127.0.0.1:8000/api/predict-single/' 
      : 'http://127.0.0.1:8000/api/predict/';

    const payload = isSingle 
      ? { plant: plantA } 
      : { plant_a: plantA, plant_b: plantB };

    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      const data = await response.json();

      if (!response.ok && !data.status) {
        throw new Error(data.error || "Server Error");
      }
      
      if (data.status === "Error") {
         setResult({ status: "Error", reason: data.reason });
         setLoading(false);
         return;
      }

      setResult(processDataToResult(data));

    } catch (error) {
      console.error("Fetch Error:", error);
      setResult({ status: 'Error', reason: "Failed to connect to the backend." });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col font-sans text-slate-800">
      <Header />
      <main className="flex-grow max-w-5xl mx-auto w-full px-6 py-12">
        <HeroSection />
        
        <TabSwitcher activeTab={activeTab} setActiveTab={setActiveTab} />
        
        <InputForm 
          activeTab={activeTab} 
          onCalculate={handleCalculate} 
          loading={loading} 
        />
        
        {result && (
          <>
            <ResultsSection result={result} activeTab={activeTab} />
            
            {result.heatmapPoints.length > 0 && (
              <MapSection points={result.heatmapPoints} /> 
            )}

            <div className="text-center mt-12 mb-8 border-t border-gray-100 pt-8">
              <button 
                onClick={() => setResult(null)}
                className="text-emerald-600 hover:text-emerald-800 font-semibold underline text-sm transition-colors"
              >
                ← Back to Top 10 Rankings
              </button>
            </div>
          </>
        )}

        {!result && (
          <>
            <TopPairsList 
              pairs={topPairs} 
              onSelectPair={handleSelectTopPair} 
            />
            
            {/* Optional small link to refresh data if it gets old */}
            {topPairs.length > 0 && (
              <div className="text-center">
                <button 
                  onClick={handleRefreshCache} 
                  className="text-xs text-gray-400 hover:text-gray-600 underline"
                >
                  Refresh Data
                </button>
              </div>
            )}
          </>
        )}
      </main>
      <Footer />
    </div>
  );
};

export default App;