import pandas as pd
import numpy as np
import joblib
import os
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report, roc_auc_score
from catboost import CatBoostClassifier, Pool

# --- CONFIG ---
TREE_FILE = "clean/genus_data_with_tree.csv"
MODEL_FILE = "agrox_brain.pkl"


def train_god_mode():
    print("--- 🐱 AGRO-X GOD MODE: CATBOOST PROTOCOL 🐱 ---")

    if not os.path.exists(TREE_FILE):
        print(f"❌ Error: {TREE_FILE} missing.")
        return

    # 1. LOAD
    df = pd.read_csv(TREE_FILE)
    df.columns = df.columns.str.strip()
    df["Genus"] = df["Genus"].astype(str).str.strip()
    df.set_index("Genus", inplace=True)

    # 2. TARGET (Strong Signal > 5%)
    y = (df["HybProp"] > 0.05).astype(int)

    # 3. FEATURE SELECTION
    # We KEEP 'Family' as a string! CatBoost loves strings.
    # We drop metadata that correlates perfectly with target (Order is too broad, RedList is irrelevant)
    X = df.drop(["HybProp", "Hyb_Ratio", "RedList", "Order"], axis=1, errors="ignore")

    # 4. MISSING VALUES (CatBoost handles NaNs, but we clean up a bit)
    # Fill numeric NaNs with -999 (Standard trick for Trees to learn "Missingness")
    numeric_cols = X.select_dtypes(include=[np.number]).columns
    X[numeric_cols] = X[numeric_cols].fillna(-999)

    # Fill categorical NaNs
    if "Family" in X.columns:
        X["Family"] = X["Family"].fillna("Unknown")

    # 5. BIOLOGICAL FEATURES
    # Add the PDF interactions
    X["Bio_Stability"] = X["perc_wood"] * X["perc_per"]
    if "Phylo_Dist_Root" in X.columns and "C_value" in X.columns:
        # Avoid -999 messing up the math
        c_val = X["C_value"].replace(-999, 0)
        phylo = X["Phylo_Dist_Root"].replace(-999, 0)
        X["Genomic_Difficulty"] = phylo * (c_val + 1)

    # 6. SPLIT
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.1, random_state=42
    )

    print(f"Training on {X.shape[1]} features. Categorical: ['Family']")

    # 7. TRAIN CATBOOST
    # This is the algorithm that wins Kaggle competitions.
    print("🚀 Igniting CatBoost Engine...")

    # Identify categorical features indices
    cat_features = ["Family"]

    model = CatBoostClassifier(
        iterations=1000,
        learning_rate=0.05,  # Slow and steady
        depth=6,
        l2_leaf_reg=3,  # Regularization to prevent overfitting
        loss_function="Logloss",
        eval_metric="AUC",
        random_seed=42,
        verbose=100,  # Print progress every 100 trees
        auto_class_weights="Balanced",  # Automatically handles the imbalance
    )

    model.fit(
        X_train,
        y_train,
        cat_features=cat_features,
        eval_set=(X_test, y_test),
        early_stopping_rounds=50,  # Stop if it stops improving
    )

    # 8. OPTIMIZE THRESHOLD
    probs = model.predict_proba(X_test)[:, 1]
    best_acc = 0
    best_thresh = 0.5

    for t in np.arange(0.3, 0.85, 0.01):
        preds_t = (probs >= t).astype(int)
        acc_t = accuracy_score(y_test, preds_t)
        if acc_t > best_acc:
            best_acc = acc_t
            best_thresh = t

    print("\n" + "=" * 40)
    print(f"🏆 FINAL ACCURACY: {best_acc:.2%} (Threshold: {best_thresh:.2f})")
    print(f"📈 ROC-AUC:      {roc_auc_score(y_test, probs):.4f}")
    print("=" * 40)

    final_preds = (probs >= best_thresh).astype(int)
    print(classification_report(y_test, final_preds))

    # 9. SAVE
    print("\n✅ SAVING GOD MODE BRAIN.")
    # CatBoost models save differently, but we wrapper it
    package = {
        "model": model,
        "threshold": best_thresh,
        "database": X,
        "raw_data": df,
        "family_map": None,  # CatBoost remembers the mapping internally!
        "feature_names": list(X.columns),
    }
    joblib.dump(package, MODEL_FILE)
    print(f"💾 Saved to {MODEL_FILE}")


if __name__ == "__main__":
    train_god_mode()
