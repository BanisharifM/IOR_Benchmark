#!/usr/bin/env python3
"""
Normalize a counters CSV by applying log10(x + 1) to every numeric column.
Usage:
  python normalize_counters.py input.csv output_normalized.csv
"""
import argparse
import pandas as pd
import numpy as np

def main():
    parser = argparse.ArgumentParser(
        description="Apply log10(x + 1) normalization to all numeric columns in a CSV"
    )
    parser.add_argument(
        "input_csv",
        help="Path to the raw counters CSV (nprocs + counters + tag)"
    )
    parser.add_argument(
        "output_csv",
        help="Where to write the normalized output CSV"
    )
    args = parser.parse_args()

    # Load the dataset
    df = pd.read_csv(args.input_csv)

    # Identify numeric columns to normalize (e.g., nprocs, all counters, tag)
    numeric_cols = df.select_dtypes(include=[np.number]).columns.tolist()

    # Explicitly exclude columns if needed (e.g., "test_id" if mistakenly included)
    exclude_cols = ["test_id"]
    cols_to_normalize = [col for col in numeric_cols if col not in exclude_cols]

    print(f"Normalizing columns: {cols_to_normalize}")

    # Apply log10(x + 1) to each numeric column
    df[cols_to_normalize] = np.log10(df[cols_to_normalize] + 1)

    # Save the result
    df.to_csv(args.output_csv, index=False)
    print(f"✅ Wrote normalized CSV with {len(cols_to_normalize)} columns to {args.output_csv}")

if __name__ == "__main__":
    main()


# python scripts/normalize_counters_log.py \
#   data/darshan_csv/darshan_parsed_output_6-29-V5.csv \
#   data/darshan_csv_log/darshan_parsed_output_6-29-V5_normalized_log.csv