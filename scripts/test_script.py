import pandas as pd
from collections import Counter

# === Load CSV ===
df = pd.read_csv("ior_configurations_targeted.csv")

# === Columns we care about for diversity ===
cols = ["api", "transferSize", "blockSize", "segmentCount", "numTasks",
        "filePerProc", "useStridedDatatype", "setAlignment", "useO_DIRECT", "fsync",
        "LUSTRE_STRIPE_SIZE", "LUSTRE_STRIPE_WIDTH"]

# === Count frequency of each value for each column ===
freqs = {col: Counter(df[col]) for col in cols}

# === Function to compute diversity score ===
def compute_diversity(row):
    score = 0
    for col in cols:
        val = row[col]
        # Lower frequency means higher diversity
        score += 1 / freqs[col][val]
    return score

# === Apply function to each row ===
df["diversity_score"] = df.apply(compute_diversity, axis=1)

# === Sort configs by diversity score descending ===
df_sorted = df.sort_values(by="diversity_score", ascending=False)

# === Print top diverse configs ===
print("🔥 Top 10 most diverse configs:")
print(df_sorted[["config_id", "testFile", "diversity_score"] + cols].head(10))

# === Print summary usage for each parameter value ===
print("\n=== Parameter value usage counts ===")
for col in cols:
    print(f"\n--- {col} ---")
    print(df[col].value_counts())
