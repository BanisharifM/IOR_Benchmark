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

    # Separate features and exclude 'tag' and 'test_id' if present
    exclude_cols = []
    if 'tag' in df.columns:
        exclude_cols.append('tag')
    if 'test_id' in df.columns:
        exclude_cols.append('test_id')

    features = df.drop(columns=exclude_cols)
    extras = df[exclude_cols] if exclude_cols else None

    print(f"🔹 Excluding columns from normalization: {exclude_cols}")

    # Compute L2 norm per row
    print("🔹 Computing L2 norms per row...")
    data = features.values.astype(float)
    norms = np.linalg.norm(data, axis=1, keepdims=True)
    norms[norms == 0] = 1.0  # avoid divide by zero

    # Apply L2 normalization
    normed_data = data / norms

    # Build DataFrame
    df_normed = pd.DataFrame(normed_data, columns=features.columns)
    if extras is not None:
        for col in extras.columns:
            df_normed[col] = extras[col].values

    # Ensure output directory exists
    os.makedirs(os.path.dirname(args.output_csv) or '.', exist_ok=True)
    df_normed.to_csv(args.output_csv, index=False)
    print(f"✅ Saved L2-normalized CSV to: {args.output_csv}")

if __name__ == '__main__':
    main()


# python scripts/normalize_counters_l2.py \
#   --input_csv data/darshan_csv_log/darshan_parsed_output_6-29-V5_normalized_log.csv \
#   --output_csv data/darshan_csv_log_L2/darshan_parsed_output_6-29-V5_norm_log_L2.csv