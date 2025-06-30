#!/usr/bin/env python3
import pandas as pd

# === Input and output paths ===
INPUT_CSV  = "data/darshan_csv/darshan_parsed_output_6-29-V5.csv"
OUTPUT_CSV = "data/darshan_csv/darshan_parsed_output_6-29-V5_sorted_by_tag.csv"

def main():
    # Load CSV
    df = pd.read_csv(INPUT_CSV)
    print(f"🔹 Loaded {len(df)} rows from {INPUT_CSV}")

    # Check columns
    if "tag" not in df.columns or "test_id" not in df.columns:
        raise ValueError("Input CSV must contain 'tag' and 'test_id' columns!")

    # Sort by tag (ascending: lowest to highest)
    sorted_df = df.sort_values(by="tag", ascending=True)

    # Select only needed columns
    output_df = sorted_df[["test_id", "tag"]]

    # Save
    output_df.to_csv(OUTPUT_CSV, index=False)
    print(f"✅ Saved sorted test_ids with tags to {OUTPUT_CSV}")

if __name__ == "__main__":
    main()
