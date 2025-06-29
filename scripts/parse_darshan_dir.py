#!/usr/bin/env python3
import os
import sys
import subprocess
import argparse
import pandas as pd
from collections import defaultdict

# List of all counters to extract
TARGET_COUNTERS = [
    "POSIX_OPENS", "LUSTRE_STRIPE_SIZE", "LUSTRE_STRIPE_WIDTH", "POSIX_FILENOS",
    "POSIX_MEM_ALIGNMENT", "POSIX_FILE_ALIGNMENT", "POSIX_READS", "POSIX_WRITES",
    "POSIX_SEEKS", "POSIX_STATS", "POSIX_BYTES_READ", "POSIX_BYTES_WRITTEN",
    "POSIX_CONSEC_READS", "POSIX_CONSEC_WRITES", "POSIX_SEQ_READS", "POSIX_SEQ_WRITES",
    "POSIX_RW_SWITCHES", "POSIX_MEM_NOT_ALIGNED", "POSIX_FILE_NOT_ALIGNED",
    "POSIX_SIZE_READ_0_100", "POSIX_SIZE_READ_100_1K", "POSIX_SIZE_READ_1K_10K",
    "POSIX_SIZE_READ_100K_1M", "POSIX_SIZE_WRITE_0_100", "POSIX_SIZE_WRITE_100_1K",
    "POSIX_SIZE_WRITE_1K_10K", "POSIX_SIZE_WRITE_10K_100K", "POSIX_SIZE_WRITE_100K_1M",
    "POSIX_STRIDE1_STRIDE", "POSIX_STRIDE2_STRIDE", "POSIX_STRIDE3_STRIDE", "POSIX_STRIDE4_STRIDE",
    "POSIX_STRIDE1_COUNT", "POSIX_STRIDE2_COUNT", "POSIX_STRIDE3_COUNT", "POSIX_STRIDE4_COUNT",
    "POSIX_ACCESS1_ACCESS", "POSIX_ACCESS2_ACCESS", "POSIX_ACCESS3_ACCESS", "POSIX_ACCESS4_ACCESS",
    "POSIX_ACCESS1_COUNT", "POSIX_ACCESS2_COUNT", "POSIX_ACCESS3_COUNT", "POSIX_ACCESS4_COUNT",
    # helper counter for time
    "POSIX_F_META_TIME"
]


def parse_file(darshan_file: str, parser_cmd: str):
    """Run darshan-parser on a file and extract TARGET_COUNTERS per rank."""
    try:
        raw = subprocess.check_output([parser_cmd, darshan_file], text=True)
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] parsing {darshan_file}: {e}", file=sys.stderr)
        return []

    # accumulate per-rank sums
    rank_data = defaultdict(lambda: defaultdict(float))
    for line in raw.splitlines():
        if not (line.startswith("POSIX") or line.startswith("LUSTRE")):
            continue
        parts = line.split("\t")
        if len(parts) < 5:
            continue
        _, rank_str, _, counter, value_str = parts[:5]
        try:
            rank = int(rank_str)
            value = float(value_str)
        except ValueError:
            continue
        if counter in TARGET_COUNTERS:
            rank_data[rank][counter] += value

    records = []
    for rank, counters in rank_data.items():
        # start row with rank only
        row = {"nprocs": rank}
        # fill in all counters (missing→0)
        for cnt in TARGET_COUNTERS:
            row[cnt] = counters.get(cnt, 0.0)

        # compute tag = total bytes / meta-time
        total_bytes = row["POSIX_BYTES_READ"] + row["POSIX_BYTES_WRITTEN"]
        t = row["POSIX_F_META_TIME"]
        if t <= 0.0:
            t = 1e-9
        row["tag"] = total_bytes / t
        # drop helper counter
        del row["POSIX_F_META_TIME"]

        records.append(row)
    return records


def main():
    parser = argparse.ArgumentParser(
        description="Parse .darshan files under a directory into one CSV of counters + tag"
    )
    parser.add_argument("input_dir", help="Directory containing .darshan files")
    parser.add_argument("output_csv", nargs="?", default="darshan_parsed_output.csv",
                        help="Output CSV path")
    parser.add_argument("--parser-cmd", default="darshan-parser",
                        help="darshan-parser executable path")
    args = parser.parse_args()

    all_records = []
    for root, _, files in os.walk(args.input_dir):
        for fn in files:
            if not fn.endswith(".darshan"):
                continue
            fp = os.path.join(root, fn)
            print(f"[INFO] processing {fp}")
            recs = parse_file(fp, args.parser_cmd)
            all_records.extend(recs)

    if not all_records:
        print("[WARN] no records found; exiting.")
        sys.exit(1)

    # build DataFrame with only nprocs, counters, and tag
    df = pd.DataFrame(all_records)
    # order columns: nprocs, all TARGET_COUNTERS (minus meta-time), then tag
    cols = ["nprocs"] + [c for c in TARGET_COUNTERS if c != "POSIX_F_META_TIME"] + ["tag"]
    df = df[cols]

    # sort by rank
    df.sort_values("nprocs", inplace=True)
    df.to_csv(args.output_csv, index=False)
    print(f"[OK] wrote {len(df)} rows to {args.output_csv}")


if __name__ == "__main__":
    main()
