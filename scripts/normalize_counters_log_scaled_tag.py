#!/usr/bin/env python3
"""
Same as normalize_counters.py, but rescales only the tag so it lands in your train range.
Usage:
  python normalize_counters_log_scaled_tag.py \
      --input_csv raw_parse.csv \
      --output_csv normalized.csv \
      --tag_target_max 4.0
"""
import argparse
import os
import pandas as pd
import numpy as np

def main():
    p = argparse.ArgumentParser(
        description="Log10‐normalize counters and rescale tag to match train max"
    )
    p.add_argument("input_csv",
                   help="raw parsed CSV (with raw tag = bytes/time)")
    p.add_argument("output_csv",
                   help="where to write log10‐normalized + scaled-tag CSV")
    p.add_argument("--tag_target_max", type=float, default=4.0,
                   help="maximum tag (after log) seen in your training data")
    args = p.parse_args()

    df = pd.read_csv(args.input_csv)
    if "tag" not in df.columns:
        raise RuntimeError("input CSV must have a raw 'tag' column")

    # 1) Compute D so that max_new_tag = tag_target_max
    raw_tag = df["tag"].values
    raw_max = raw_tag.max()
    D = (raw_max + 1.0) / (10 ** args.tag_target_max)
    print(f"🔹 Found raw_tag.max() = {raw_max:.3g}, so D = {D:.3g}")

    # 2) Log‐normalize all other numeric columns (x → log10(x+1))
    numeric = df.select_dtypes(include=[np.number]).columns.tolist()
    numeric.remove("tag")
    print(f"🔹 Log10‐normalizing counters: {numeric}")
    df[numeric] = np.log10(df[numeric] + 1.0)

    # 3) Scale & log‐normalize the tag:
    #    new_tag = log10(raw_tag / D + 1)
    df["tag"] = np.log10(raw_tag / D + 1.0)
    print(f"🔹 tag now ranges {df['tag'].min():.3f} … {df['tag'].max():.3f}")

    # 4) Save
    os.makedirs(os.path.dirname(args.output_csv) or ".", exist_ok=True)
    df.to_csv(args.output_csv, index=False)
    print(f"✅ Wrote {len(df)} rows to {args.output_csv}")

if __name__ == "__main__":
    main()


# python scripts/normalize_counters_log_scaled_tag.py \
#   data/darshan_csv/darshan_parsed_output_6-29-V2.csv \
#   data/darshan_csv_log_scaled/darshan_parsed_output_6-29-V2_norm_log_scaled.csv \
#   --tag_target_max 4.0