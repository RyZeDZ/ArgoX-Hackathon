import React from 'react';
import { MapContainer, TileLayer, CircleMarker, Popup, Tooltip } from 'react-leaflet';
import 'leaflet/dist/leaflet.css'; // CRITICAL: This must be here
import { MapPin } from 'lucide-react';

// Fix for default Leaflet marker icons in React (if you used Markers, but we use CircleMarker so this is less critical but good practice)
import L from 'leaflet';
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: require('leaflet/dist/images/marker-icon-2x.png'),
  iconUrl: require('leaflet/dist/images/marker-icon.png'),
  shadowUrl: require('leaflet/dist/images/marker-shadow.png'),
});

const MapSection = ({ points }) => {
  if (!points || points.length === 0) return null;

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mt-6 animate-fade-in">
      
      <div className="flex items-center gap-2 mb-4 text-slate-800">
        <MapPin className="text-emerald-600" size={24} />
        <div>
          <h3 className="font-bold text-lg">Geospatial Suitability Map</h3>
          <p className="text-xs text-gray-500">
            {points.length} locations identified across Algeria
          </p>
        </div>
      </div>

      {/* Force explicit height with style to rule out Tailwind issues */}
      <div className="rounded-lg overflow-hidden border border-gray-100 z-0 relative" style={{ height: "400px", width: "100%" }}>
        <MapContainer 
          center={[28.0, 3.0]} // Center of Algeria
          zoom={5} 
          scrollWheelZoom={false} 
          style={{ height: "100%", width: "100%" }}
        >
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            url="https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png"
          />

          {points.map((point) => (
            <CircleMarker
              key={point.id || point.name}
              center={[point.lat, point.lng]}
              pathOptions={{ 
                fillColor: "#059669", 
                color: "#059669",
                weight: 1,
                opacity: 0.8,
                fillOpacity: 0.5 
              }}
              radius={10} 
            >
              <Popup>
                <strong>{point.name}</strong>
              </Popup>
              <Tooltip direction="top" offset={[0, -10]} opacity={1}>
                {point.name}
              </Tooltip>
            </CircleMarker>
          ))}
        </MapContainer>
      </div>
    </div>
  );
};

export default MapSection;