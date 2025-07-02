import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os

# === Settings ===
csv_path = "data/darshan_csv/darshan_parsed_output_6-30-V4.csv"
output_dir = "plots3/io_counter_histograms_actual"
os.makedirs(output_dir, exist_ok=True)

# === Load CSV ===
df = pd.read_csv(csv_path)

# === Columns to plot ===
exclude_cols = ["test_id"]
cols_to_plot = [col for col in df.columns if col not in exclude_cols and pd.api.types.is_numeric_dtype(df[col])]

# === Individual plots (actual value histograms) ===
for col in cols_to_plot:
    plt.figure(figsize=(8, 6))
    data = df[col].dropna()
    
    # Plot histogram of actual values (no log scale, no transformation)
    sns.histplot(data, bins=50, kde=False, color="steelblue", edgecolor="black")
    
    plt.title(f"Histogram of {col}")
    plt.xlabel("Value")
    plt.ylabel("Frequency")  # Regular frequency
    plt.grid(True, alpha=0.3)
    
    # Save
    plot_path = os.path.join(output_dir, f"{col}_hist_actual.png")
    plt.savefig(plot_path)
    plt.close()
    
    print(f"✅ Saved actual value histogram for {col} to {plot_path}")

# === Combined grid plot example (first 12 counters) ===
subset_cols = cols_to_plot[:12]
fig, axes = plt.subplots(3, 4, figsize=(20, 15))
axes = axes.flatten()

for ax, col in zip(axes, subset_cols):
    data = df[col].dropna()
    sns.histplot(data, bins=50, kde=False, ax=ax, color="teal", edgecolor="black")
    ax.set_title(col)
    ax.grid(True, alpha=0.2)

plt.tight_layout()
grid_path = os.path.join(output_dir, "combined_grid_histograms_actual.png")
plt.savefig(grid_path)
plt.close()

print(f"🎨 Saved combined grid summary plot to {grid_path}")
print("🎉 All actual value histograms generated and saved!")
