#!/usr/bin/env python3
"""
Apply L2 normalization (row-wise) to log-normalized counters, excluding the 'tag' column, using NumPy and Pandas (no PyTorch dependency).
Usage:
  python normalize_counters_l2.py --input_csv INPUT --output_csv OUTPUT
"""
import argparse
import os
import pandas as pd
import numpy as np

def main():
    parser = argparse.ArgumentParser(
        description="Apply L2 normalization to log-normalized counters (excluding 'tag')"
    )
    parser.add_argument(
        "--input_csv", required=True,
        help="Path to log-normalized CSV (with numeric features + optional tag)"
    )
    parser.add_argument(
        "--output_csv", required=True,
        help="Path to save the L2-normalized CSV"
    )
    args = parser.parse_args()

    print(f"🔹 Loading data from: {args.input_csv}")
    df = pd.read_csv(args.input_csv)

    # Separate features and optional tag
    if 'tag' in df.columns:
        features = df.drop(columns=['tag'])
        tag = df['tag']
        print("🔹 Excluding 'tag' from normalization.")
    else:
        features = df.copy()
        tag = None
        print("🔹 No 'tag' column found; normalizing all columns.")

    # Compute L2 norm per row
    print("🔹 Computing L2 norms per row...")
    data = features.values.astype(float)
    norms = np.linalg.norm(data, axis=1, keepdims=True)
    # Prevent division by zero
    norms[norms == 0] = 1.0

    # Apply L2 normalization
    normed_data = data / norms

    # Build DataFrame
    df_normed = pd.DataFrame(normed_data, columns=features.columns)
    if tag is not None:
        df_normed['tag'] = tag.values

    # Ensure output directory exists
    os.makedirs(os.path.dirname(args.output_csv) or '.', exist_ok=True)
    df_normed.to_csv(args.output_csv, index=False)
    print(f"✅ Saved L2-normalized CSV to: {args.output_csv}")

if __name__ == '__main__':
    main()


# python scripts/normalize_counters_l2.py \
#   --input_csv data/darshan_csv_log_scaled/darshan_parsed_output_6-29-V2_norm_log_scaled.csv \
#   --output_csv data/darshan_csv_log_scaled_L2/darshan_parsed_output_6-29-V2_norm_log_scaled.csv