import pandas as pd
import sys
from collections import defaultdict

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
    "POSIX_F_META_TIME"
]

# Parse file
rank_data = defaultdict(lambda: defaultdict(float))

with open(sys.argv[1], 'r') as f:
    for line in f:
        if not (line.startswith("POSIX") or line.startswith("LUSTRE")):
            continue

        parts = line.strip().split("\t")
        if len(parts) < 5:
            continue

        module, rank_str, _, counter, value_str = parts[:5]
        try:
            rank = int(rank_str)
            value = float(value_str)
        except ValueError:
            continue

        if counter in TARGET_COUNTERS:
            rank_data[rank][counter] += value

# Process rows
records = []

for rank, counters in rank_data.items():
    row = {"nprocs": rank}
    for counter in TARGET_COUNTERS:
        row[counter] = counters.get(counter, 0.0)

    # Calculate tag = total bytes / slowest time
    total_bytes = row["POSIX_BYTES_READ"] + row["POSIX_BYTES_WRITTEN"]
    time = row["POSIX_F_META_TIME"]
    if time <= 0:
        time = 1e-9  # Avoid divide-by-zero
    row["tag"] = total_bytes / time

    del row["POSIX_F_META_TIME"]  # Remove helper
    records.append(row)

# Save
output_csv = sys.argv[2] if len(sys.argv) > 2 else "darshan_parsed_output.csv"
df = pd.DataFrame(records)
df.sort_values("nprocs", inplace=True)
df.to_csv(output_csv, index=False)
print(f"Saved {len(df)} ranks to {output_csv}")
