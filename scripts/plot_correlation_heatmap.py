import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# === Path to CSV ===
csv_path = "data/darshan_csv/darshan_parsed_output_6-30-V4.csv"

# === Load CSV ===
df = pd.read_csv(csv_path)

# === Identify numeric columns (excluding test_id) ===
exclude_cols = ["test_id"]
numeric_cols = [col for col in df.columns if col not in exclude_cols and pd.api.types.is_numeric_dtype(df[col])]

# === Create presence matrix (1 = non-zero, 0 = zero) ===
presence_df = df[numeric_cols].copy()
presence_df = presence_df.notna() & (presence_df != 0)
presence_df = presence_df.astype(int)

# === Plot heatmap ===
plt.figure(figsize=(20, 12))
sns.heatmap(presence_df, cmap="Greens", cbar=True, linewidths=0.1)

plt.title("Presence Matrix: Non-Zero Counters per Config", fontsize=18)
plt.xlabel("Counters")
plt.ylabel("Configs (rows)")

plt.tight_layout()

# === Save plot ===
plt.savefig("presence_matrix_heatmap.png", dpi=300)
plt.close()

print("✅ Saved presence matrix heatmap to 'presence_matrix_heatmap.png'.")
