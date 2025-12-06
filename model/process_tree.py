import pandas as pd
import numpy as np
from Bio import Phylo
import os
import sys

# --- CONFIGURATION ---
TREE_FILE = "data/genus.tre"
# FORCE BACK TO ORIGINAL CLEAN FILE (Ignore Enriched)
INPUT_FILE = "clean/genus_data_cleaned.csv"
OUTPUT_FILE = "clean/genus_data_with_tree.csv"


def process_tree():
    print(f"--- 🔙 RESTORING ORIGINAL TREE DATA ---")

    if not os.path.exists(INPUT_FILE):
        print(f"❌ Error: {INPUT_FILE} not found. Run preprocessing.py first.")
        sys.exit(1)

    # 1. Load Data
    print(f"Loading {INPUT_FILE}...")
    df = pd.read_csv(INPUT_FILE)
    df.columns = df.columns.str.strip()
    df["Genus"] = df["Genus"].astype(str).str.strip()

    # 2. Load Tree
    print(f"Loading tree from {TREE_FILE}...")
    try:
        tree = Phylo.read(TREE_FILE, "newick")
    except Exception as e:
        print(f"❌ Error reading tree file: {e}")
        sys.exit(1)

    # 3. Extract Features (The logic that worked)
    print("Calculating phylogenetic distances...")
    phylo_features = []
    terminals = {term.name: term for term in tree.get_terminals()}

    for index, row in df.iterrows():
        genus = row["Genus"]

        if genus in terminals:
            term = terminals[genus]
            dist_root = tree.distance(term)
            # Default to 1.0 if branch length is missing (Topology tree)
            branch_len = term.branch_length if term.branch_length else 1.0
        else:
            # Fallback for plants missing from tree
            dist_root = 15.0
            branch_len = 1.0

        phylo_features.append(
            {
                "Genus": genus,
                "Phylo_Dist_Root": dist_root,
                "Phylo_Branch_Len": branch_len,
            }
        )

    phylo_df = pd.DataFrame(phylo_features)

    # 4. Merge
    print("Merging Tree Features...")
    df_final = pd.merge(df, phylo_df, on="Genus", how="left")

    # 5. Save
    df_final.to_csv(OUTPUT_FILE, index=False)
    print(f"✅ RESTORED DATASET: {OUTPUT_FILE}")


if __name__ == "__main__":
    process_tree()
