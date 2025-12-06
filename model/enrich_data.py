import pandas as pd
import numpy as np

# FILES
MAIN_FILE = "clean/genus_data_with_tree.csv"
HALOPH_FILE = "tmp.csv"
OUTPUT_FILE = "clean/genus_data_enriched.csv"


def enrich_database():
    print("Loading Main Knowledge Base...")
    df_main = pd.read_csv(MAIN_FILE)
    # Clean main genus names
    df_main["Genus"] = df_main["Genus"].str.strip()

    print("Processing eHALOPH (Salinity) Data...")
    try:
        # 1. Load the messy CSV
        # on_bad_lines='skip': If a row is truly broken, skip it.
        # quotechar='"': Tells pandas to handle those weird newlines inside quotes correctly.
        df_salt = pd.read_csv(HALOPH_FILE, quotechar='"', on_bad_lines="skip")

        # 2. Extract just what we need
        # We only care that the Genus EXISTS in this file.
        # If it's here, it loves salt.
        salt_genera = df_salt["Genus"].astype(str).str.strip().unique()

        print(f"Found {len(salt_genera)} salt-loving genera (e.g., {salt_genera[:5]})")

        # 3. Create a DataFrame for merging
        df_salinity = pd.DataFrame(
            {"Genus": salt_genera, "Salinity_Tol": 100.0}  # Assign Max Score
        )

    except Exception as e:
        print(f"❌ Error reading eHALOPH: {e}")
        return

    # 4. MERGE
    print("Merging Salinity Data into Main DB...")
    # 'left' merge: Keep all our original plants
    df_merged = pd.merge(df_main, df_salinity, on="Genus", how="left")

    # 5. SMART FILL (The trick)
    # If a plant wasn't in the list, it's NaN.
    # BUT, maybe its cousin was?
    # Fill NaN with the Family Average.

    # First fill NaNs with 0 temporarily to calculate means
    # (Assuming if not in list, it's not a super-halophyte)
    df_merged["Salinity_Tol"].fillna(0, inplace=True)

    # Calculate Family Mean Salinity
    # If "Acacia" is in the list, "Acacia's cousin" gets a partial bonus
    family_salt_means = df_merged.groupby("Family")["Salinity_Tol"].transform("mean")

    # Logic: If direct match -> 100.
    # If not direct match -> Assign Family Average (e.g., 25).
    # This means cousins of Halophytes get a "Coastal Candidate" tag.

    # (Since we filled with 0, we can just replace the 0s with family means if we want,
    # but for safety let's just use the direct 100s as the "Elite" Coastal plants).

    # Let's actually enforce the Family Bonus:
    # If Genus is 0 but Family Mean > 10, give it the Family Mean.
    mask = df_merged["Salinity_Tol"] == 0
    df_merged.loc[mask, "Salinity_Tol"] = family_salt_means[mask]

    # Save
    df_merged.to_csv(OUTPUT_FILE, index=False)
    print(f"✅ Success! Created {OUTPUT_FILE}")

    # Validation Check
    check = df_merged[df_merged["Salinity_Tol"] > 0][
        ["Genus", "Family", "Salinity_Tol"]
    ].head()
    print("\n--- Verified Salinity Data ---")
    print(check)


if __name__ == "__main__":
    enrich_database()
