import os
import pandas as pd
from django.conf import settings

SEARCH_INDEX = []
VALID_GENERA = set()

def initialize_plant_data():
    global SEARCH_INDEX, VALID_GENERA

    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    MAIN_DATA_PATH = os.path.join(BASE_DIR, "sementic/genus_data_enriched.csv")
    LOOKUP_DATA_PATH = os.path.join(BASE_DIR, "sementic/plants.csv")

    print("--- LOADING PLANT DATASETS ---")

    # ---- 1. LOAD MAIN GENUS DATA (The ML features) ----
    try:
        # Standard CSV format based on your snippet
        df_main = pd.read_csv(MAIN_DATA_PATH)
        
        # Clean column names just in case
        df_main.columns = df_main.columns.str.strip()

        # Create the allow-list of Genera
        VALID_GENERA = set(
            df_main["Genus"]
            .dropna()
            .astype(str)
            .str.strip()
            .str.capitalize()
            .unique()
        )

        print(f"✅ Loaded {len(VALID_GENERA)} valid genera from Agrox dataset.")
        # Debug: Print first 5 to check formatting
        # print("Debug Valid Genera:", list(VALID_GENERA)[:5]) 

    except Exception as e:
        print(f"❌ Error loading main dataset: {e}")
        return

    # ---- 2. LOAD LOOKUP DATA (USDA Plants Database) ----
    try:
        # CRITICAL FIX: Handle the spaces and quotes in your plants.csv
        # skipinitialspace=True helps with the spaces after commas
        # quotechar='"' tells pandas the fields are wrapped in quotes
        df_lookup = pd.read_csv(LOOKUP_DATA_PATH, quotechar='"', skipinitialspace=True)

        # CRITICAL FIX: Clean the Column Headers
        # Your snippet shows headers might have spaces or quotes stuck to them
        df_lookup.columns = df_lookup.columns.str.replace('"', '').str.strip()
        
        # print("Debug Columns found:", df_lookup.columns.tolist()) 

        # Verify columns exist before looping
        required_cols = ["Common Name", "Scientific Name with Author"]
        if not all(col in df_lookup.columns for col in required_cols):
             print(f"❌ Columns mismatch. Found: {df_lookup.columns.tolist()}")
             return

        temp_index = []
        match_count = 0

        for _, row in df_lookup.iterrows():
            # Get values safely
            common_name = str(row["Common Name"]).strip()
            sci_full = str(row["Scientific Name with Author"]).strip()

            # Skip if common name is missing or "nan"
            if not common_name or common_name.lower() == 'nan':
                continue

            # Extract genus: "Abutilon abutiloides..." -> "Abutilon"
            # Remove any surrounding quotes just in case
            sci_full = sci_full.replace('"', '')
            genus_candidate = sci_full.split(" ")[0].capitalize()

            # CROSS-REFERENCE
            if genus_candidate in VALID_GENERA:
                temp_index.append({
                    "display_name": f"{common_name} ({genus_candidate})",
                    "common_name": common_name,
                    "genus": genus_candidate,
                })
                match_count += 1
            
            # DEBUGGING: If you have 0 results, uncomment this to see why mismatches happen
            # else:
            #     if match_count == 0: print(f"Mismatch: '{genus_candidate}' not in VALID_GENERA")

        # Deduplicate
        SEARCH_INDEX = list({item["display_name"]: item for item in temp_index}.values())

        print(f"✅ Built search index with {len(SEARCH_INDEX)} entries (from {len(df_lookup)} raw rows).")

    except Exception as e:
        print(f"❌ Error loading lookup dataset: {e}")

# Load on startup
initialize_plant_data()

def search_plants_service(query):
    if not query:
        return []

    query = query.lower().strip()
    results = []

    for item in SEARCH_INDEX:
        c_name = item["common_name"].lower()
        g_name = item["genus"].lower()

        # Check if query is inside Common Name OR Genus
        if query in c_name or query in g_name:
            results.append(item)

        if len(results) >= 20:
            break

    return results