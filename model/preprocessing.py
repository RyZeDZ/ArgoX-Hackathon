import pandas as pd
import numpy as np
import os


INPUT_FILE = "data/genus_data.csv"
OUTPUT_FILE = "clean/genus_data_cleaned.csv"

NUMERIC_FEATURES = [
    "HybProp",
    "perc_per",
    "perc_wood",
    "C_value",
    "tavg",
    "floral_symm",
    "mating_system",
    "repro_syndrome",
    "pollination_syndrome",
    "RedList",
]


def load_and_sanitize(filepath):
    """
    Loads the CSV and converts non-numeric placeholders ('.') to NaNs.
    """
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"File not found: {filepath}")

    print(f"Loading data from {filepath}...")
    df = pd.read_csv(filepath)

    df.replace(".", np.nan, inplace=True)

    for col in NUMERIC_FEATURES:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")

    print(f"Data Loaded. Shape: {df.shape}")
    print(f"Initial missing values:\n{df[NUMERIC_FEATURES].isna().sum()}\n")
    return df


def smart_fill_data(df):
    """
    Implements 'Hierarchical Imputation'.
    1. Try to fill missing values using the average of the FAMILY.
    2. If Family data is also missing, fall back to the Global Average.
    """
    print("Starting Smart Fill...")

    df_clean = df.copy()

    for col in NUMERIC_FEATURES:
        if col not in df_clean.columns:
            continue

        df_clean[col] = df_clean[col].fillna(
            df_clean.groupby("Family")[col].transform("mean")
        )

        if df_clean[col].isna().sum() > 0:
            global_mean = df_clean[col].mean()
            df_clean[col] = df_clean[col].fillna(global_mean)

    print("Smart Fill Complete.")
    return df_clean


def validate_data(df):
    """
    Final check to ensure no NaN values remain in critical columns.
    """
    missing_count = df[NUMERIC_FEATURES].isna().sum().sum()
    if missing_count == 0:
        print("SUCCESS: Data is fully clean. No missing values.")
        return True
    else:
        print(f"WARNING: {missing_count} missing values remain!")
        return False


if __name__ == "__main__":
    raw_df = load_and_sanitize(INPUT_FILE)

    clean_df = smart_fill_data(raw_df)

    if validate_data(clean_df):
        clean_df.to_csv(OUTPUT_FILE, index=False)
        print(f"Cleaned dataset saved to: {OUTPUT_FILE}")

        print("\n--- Sample of Cleaned Data (First 5 Rows) ---")
        print(clean_df[NUMERIC_FEATURES].head())
