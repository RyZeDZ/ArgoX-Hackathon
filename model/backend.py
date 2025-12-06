import pandas as pd
import joblib
import os
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

MODEL_FILE = os.path.join(BASE_DIR, "agrox_brain.pkl")
SALINITY_FILE = os.path.join(BASE_DIR, "clean/genus_data_enriched.csv")

ALGERIAN_ZONES = {
    "Sahara": [
        "Adrar",
        "Tamanrasset",
        "Biskra",
        "Ouargla",
        "Bechar",
        "Tindouf",
        "El Oued",
        "Ghardaia",
        "Illizi",
        "Timimoun",
        "In Salah",
    ],
    "High Plateau": [
        "Setif",
        "Djelfa",
        "Tiaret",
        "Batna",
        "Bordj Bou Arreridj",
        "M'Sila",
        "Saida",
        "Medea",
        "Khenchela",
        "Tebessa",
        "Souk Ahras",
    ],
    "Coastal": [
        "Algiers",
        "Tipaza",
        "Oran",
        "Annaba",
        "Skikda",
        "Bejaia",
        "Boumerdes",
        "Tizi Ouzou",
        "Jijel",
        "Mostaganem",
        "Ain Temouchent",
    ],
}


class AgroX_Intelligence:
    def __init__(self):
        if not os.path.exists(MODEL_FILE):
            raise FileNotFoundError("Brain not found! Run builder.py first.")

        package = joblib.load(MODEL_FILE)
        self.model = package["model"]
        self.threshold = package["threshold"]
        self.db = package["database"]
        self.features = package["feature_names"]

        self.salt_lookup = {}
        if os.path.exists(SALINITY_FILE):
            try:
                df_salt = pd.read_csv(SALINITY_FILE)
                self.salt_lookup = (
                    df_salt.set_index("Genus")["Salinity_Tol"].fillna(0).to_dict()
                )
            except Exception as e:
                print(f"Could not load salinity file: {e}")

    def _get_raw_traits(self, genus):
        if genus not in self.db.index:
            return None
        row = self.db.loc[genus].copy()
        row["Family"] = str(row["Family"]) if "Family" in row else "Unknown"
        return row

    def _prepare_vector(self, t1, t2, climate_shift=0.0):
        num_cols = t1.index.difference(["Family"])
        avg_traits = (t1[num_cols] + t2[num_cols]) / 2

        family_val = t1["Family"]

        combined = avg_traits.to_dict()
        combined["Family"] = family_val

        if climate_shift > 0:
            combined["tavg"] = min(1.0, combined.get("tavg", 0.5) + 0.1)

        combined["Bio_Stability"] = combined["perc_wood"] * combined["perc_per"]

        c_val = combined.get("C_value", 0)
        if c_val == -999:
            c_val = 0
        phylo = combined.get("Phylo_Dist_Root", 0)
        if phylo == -999:
            phylo = 0

        combined["Genomic_Difficulty"] = phylo * (c_val + 1)

        df_vector = pd.DataFrame([combined])
        for col in self.features:
            if col not in df_vector.columns:
                df_vector[col] = -999

        return df_vector[self.features]

    def _generate_scientific_explanation(
        self, plant_a, plant_b, prob, traits, is_salt_tolerant, same_family
    ):
        """
        Generates a dynamic reason for the match.
        """
        reasons = []

        if same_family:
            reasons.append("strong taxonomic alignment (Same Family)")
        elif prob > 0.8:
            reasons.append("high inter-family compatibility")

        if traits["perc_wood"] > 0.7:
            reasons.append("robust woody structure compatibility")
        elif traits["perc_wood"] < 0.2:
            reasons.append("similar herbaceous growth patterns")

        if is_salt_tolerant:
            reasons.append("shared salinity tolerance traits")
        if traits["tavg"] > 0.7:
            reasons.append("aligned high-temperature preferences")

        if not reasons:
            reasons.append("convergent biological traits")

        intro = "Exceptional match" if prob > 0.8 else "Viable match"
        joined_reasons = ", ".join(reasons)
        return f"{intro} driven by {joined_reasons}."

    def _determine_zone(self, traits, salt_level):
        tavg = traits.get("tavg", 0.5)
        wood = traits.get("perc_wood", 0)

        if salt_level > 50:
            return "Coastal"

        if tavg > 0.6 and wood > 0.4:
            return "Sahara"

        if tavg > 0.5 and wood < 0.2:
            return "Coastal"

        if tavg < 0.5:
            return "High Plateau"

        return "Coastal"

    def _assess_agronomics(self, traits, zone):
        """
        Calculates Water Footprint and Disease Risk based on Environment + Biology.
        """
        drought_score = traits["perc_wood"] * 100

        water_footprint = "High"
        irrigation_advice = "Intensive Drip Irrigation Required"

        if drought_score > 75:
            water_footprint = "Minimal (Sustainable)"
            irrigation_advice = "Rain-fed (No artificial irrigation needed)"
        elif drought_score > 40:
            water_footprint = "Moderate"
            irrigation_advice = "Supplemental Irrigation (During summer)"

        disease_risk = "Moderate"
        pathogen_type = "Standard Spectrum"

        if zone == "Coastal":
            disease_risk = "High"
            pathogen_type = "Fungal Pathogens (Rust/Mildew due to Humidity)"
        elif zone == "Sahara":
            disease_risk = "Low"
            pathogen_type = "Sterile Environment (Low fungal pressure)"
        elif zone == "High Plateau":
            disease_risk = "Moderate"
            pathogen_type = "Cold-tolerant bacteria/viruses"

        return {
            "Water_Footprint": water_footprint,
            "Irrigation_Rec": irrigation_advice,
            "Disease_Risk": disease_risk,
            "Likely_Pathogens": pathogen_type,
        }

    def analyze_pair(self, plant_a, plant_b):
        """
        The main API function. Returns Score + Zone + State List + Explanation.
        """
        t1 = self._get_raw_traits(plant_a)
        t2 = self._get_raw_traits(plant_b)

        if t1 is None or t2 is None:
            return None

        vector = self._prepare_vector(t1, t2)
        prob = self.model.predict_proba(vector)[0][1]

        vector_future = self._prepare_vector(t1, t2, climate_shift=2.0)
        prob_future = self.model.predict_proba(vector_future)[0][1]

        avg_traits = (t1.drop("Family") + t2.drop("Family")) / 2

        salt_a = self.salt_lookup.get(plant_a, 0)
        salt_b = self.salt_lookup.get(plant_b, 0)
        max_salt = max(salt_a, salt_b)

        zone_name = self._determine_zone(avg_traits, max_salt)
        recommended_states = ALGERIAN_ZONES.get(zone_name, [])

        is_compatible = prob > self.threshold
        delta = prob_future - prob
        resilience = "STABLE"
        if delta < -0.03:
            resilience = "VULNERABLE"
        if delta > 0.03:
            resilience = "THRIVING"

        explanation = self._generate_scientific_explanation(
            plant_a,
            plant_b,
            prob,
            avg_traits,
            max_salt > 50,
            t1["Family"] == t2["Family"],
        )

        agronomics = self._assess_agronomics(avg_traits, zone_name)

        return {
            "Plant_A": plant_a,
            "Plant_B": plant_b,
            "Score": round(prob * 100, 1),
            "Future_Score": round(prob_future * 100, 1),
            "Compatible": bool(is_compatible),
            "Resilience": resilience,
            "Zone": zone_name,
            "States": recommended_states,
            "Explanation": explanation,
            "Traits": {
                "Drought_Tol": round(avg_traits["perc_wood"] * 100, 0),
                "Growth_Speed": round((1 - avg_traits["perc_per"]) * 100, 0),
                "Salinity_Tol": round(max_salt, 1),
            },
            "Agronomics": {
                "Water_Usage": agronomics["Water_Footprint"],
                "Irrigation_Strategy": agronomics["Irrigation_Rec"],
                "Disease_Pressure": agronomics["Disease_Risk"],
                "Pathogen_Alert": agronomics["Likely_Pathogens"],
            },
        }

    def find_best_match(self, genus, target_zone=None):
        if genus not in self.db.index:
            return {"error": "Plant not found"}

        candidates = self.db.sample(n=60, random_state=42).index.tolist()
        best_match = None
        best_score = -1

        for partner in candidates:
            if partner == genus:
                continue

            res = self.analyze_pair(genus, partner)
            if not res:
                continue

            if target_zone and target_zone.lower() not in res["Zone"].lower():
                continue

            if res["Score"] > best_score:
                best_score = res["Score"]
                best_match = res

        if not best_match:
            return {"message": "No match found."}
        return best_match

    def get_top_hybrids(self, sample_size=100):
        candidates = self.db.sample(n=sample_size, random_state=42).index.tolist()
        results = []
        seen = set()

        for p1 in candidates:
            for p2 in candidates:
                if p1 == p2:
                    continue
                key = tuple(sorted((p1, p2)))
                if key in seen:
                    continue
                seen.add(key)

                res = self.analyze_pair(p1, p2)
                if res and res["Score"] > 60:
                    results.append(res)

        results.sort(key=lambda x: x["Score"], reverse=True)
        return results[:10]


if __name__ == "__main__":
    api = AgroX_Intelligence()
    print(api.analyze_pair("Pratia", "Plantago"))
    print(api.find_best_match("Pratia"))
