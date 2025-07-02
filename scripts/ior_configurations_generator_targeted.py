import csv
import random

# You can adjust this per group
NUM_SAMPLES_PER_GROUP = 500

# Common options
apis = ["POSIX", "MPIIO"]
transfer_sizes = ["4K", "10K", "64K", "100K", "1M"]
block_sizes = ["1M", "4M", "16M", "256M", "1G"]
segment_counts = [1, 16, 64, 256]
num_tasks_list = [4, 16, 64]
set_alignment_vals = ["4K", "1M"]
lustre_stripe_sizes = ["1M", "4M"]
lustre_stripe_widths = [1, 4]

# Base groups (original)
groups = [
    # Group 1: Sequential writes, large blocks
    {"filePerProc": [1], "useStridedDatatype": [0], "useO_DIRECT": [0], "fsync": [0]},
    # Group 2: Strided access
    {"filePerProc": [1], "useStridedDatatype": [1], "useO_DIRECT": [0], "fsync": [0]},
    # Group 3: Shared file, O_DIRECT
    {"filePerProc": [0], "useStridedDatatype": [0], "useO_DIRECT": [1], "fsync": [1]},
    # Group 4: Mixed alignment, fsync
    {"filePerProc": [1, 0], "useStridedDatatype": [0], "useO_DIRECT": [1], "fsync": [1]},
]

# Additional explicit edge-case groups
edge_case_groups = [
    # Group 5: Purely sequential, huge blocks (to force POSIX_SEQ_WRITES high)
    {"filePerProc": [1], "useStridedDatatype": [0], "useO_DIRECT": [0], "fsync": [0],
     "transferSize": ["1M"], "blockSize": ["1G"], "segmentCount": [4], "numTasks": [16]},
    # Group 6: Multi-level strided writes (to hit all stride counters)
    {"filePerProc": [1], "useStridedDatatype": [1], "useO_DIRECT": [0], "fsync": [0],
     "transferSize": ["64K"], "blockSize": ["4M"], "segmentCount": [64], "numTasks": [16]},
    # Group 7: Medium-size transfers for bucket coverage (10K–100K)
    {"filePerProc": [1], "useStridedDatatype": [0], "useO_DIRECT": [0], "fsync": [0],
     "transferSize": ["10K", "64K", "100K"], "blockSize": ["1M"], "segmentCount": [16], "numTasks": [16]},
    # Group 8: Many small random-like writes (tiny buckets)
    {"filePerProc": [1], "useStridedDatatype": [1], "useO_DIRECT": [0], "fsync": [1],
     "transferSize": ["4K"], "blockSize": ["1M"], "segmentCount": [256], "numTasks": [16]},
]

# Combine all groups
all_groups = groups + edge_case_groups

header = [
    "config_id", "testFile",
    "api", "transferSize", "blockSize", "segmentCount", "numTasks",
    "filePerProc", "useStridedDatatype", "setAlignment",
    "useO_DIRECT", "fsync",
    "LUSTRE_STRIPE_SIZE", "LUSTRE_STRIPE_WIDTH"
]

rows = []
config_id = 1

for group in all_groups:
    samples = 0
    while samples < NUM_SAMPLES_PER_GROUP:
        api = random.choice(apis)
        ts = random.choice(group.get("transferSize", transfer_sizes))
        bs = random.choice(group.get("blockSize", block_sizes))
        sc = random.choice(group.get("segmentCount", segment_counts))
        nt = random.choice(group.get("numTasks", num_tasks_list))
        fpp = random.choice(group["filePerProc"])
        usd = random.choice(group["useStridedDatatype"])
        sa = random.choice(set_alignment_vals)
        od = random.choice(group["useO_DIRECT"])
        fs = random.choice(group["fsync"])
        lss = random.choice(lustre_stripe_sizes)
        lsw = random.choice(lustre_stripe_widths)

        cfg_str = str(config_id).zfill(5)
        test_file = f"test{cfg_str}"

        row = [
            cfg_str, test_file,
            api, ts, bs, sc, nt,
            fpp, usd, sa,
            od, fs,
            lss, lsw
        ]
        rows.append(row)
        config_id += 1
        samples += 1

# Write to CSV
with open("ior_configurations_targeted.csv", "w", newline="") as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(header)
    writer.writerows(rows)

print(f"✅ Done! Generated {len(rows)} configurations in 'ior_configurations_targeted.csv'")
