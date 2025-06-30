import itertools
import csv

# 1) Define your parameter levels
apis                  = ["POSIX", "HDF5"]
transfer_sizes        = ["4K", "64K", "1M"]
block_sizes           = ["1M", "4M", "16M"]
segment_counts        = [1, 16, 256]
num_tasks_list        = [4, 16, 64]
file_per_proc_vals    = [0, 1]
use_strided_vals      = [0, 1]
set_alignment_vals    = ["4K", "1M"]
use_odirect_vals      = [0, 1]
fsync_vals            = [0, 1]
lustre_stripe_sizes   = ["1M", "4M"]
lustre_stripe_widths  = [1, 4]

# 2) Compute total combinations and padding width
total = (
    len(apis)
  * len(transfer_sizes)
  * len(block_sizes)
  * len(segment_counts)
  * len(num_tasks_list)
  * len(file_per_proc_vals)
  * len(use_strided_vals)
  * len(set_alignment_vals)
  * len(use_odirect_vals)
  * len(fsync_vals)
  * len(lustre_stripe_sizes)
  * len(lustre_stripe_widths)
)
pad_width = len(str(total))

# 3) Open CSV and write header
with open("ior_configurations.csv", "w", newline="") as csvfile:
    writer = csv.writer(csvfile)
    header = [
        "config_id", "testFile",
        "api", "transferSize", "blockSize", "segmentCount", "numTasks",
        "filePerProc", "useStridedDatatype", "setAlignment",
        "useO_DIRECT", "fsync",
        "LUSTRE_STRIPE_SIZE", "LUSTRE_STRIPE_WIDTH"
    ]
    writer.writerow(header)

    # 4) Enumerate and write each row
    config_id = 1
    for combo in itertools.product(
        apis,
        transfer_sizes,
        block_sizes,
        segment_counts,
        num_tasks_list,
        file_per_proc_vals,
        use_strided_vals,
        set_alignment_vals,
        use_odirect_vals,
        fsync_vals,
        lustre_stripe_sizes,
        lustre_stripe_widths,
    ):
        api, ts, bs, sc, nt, fpp, usd, sa, od, fs, lss, lsw = combo

        cfg_str = str(config_id).zfill(pad_width)
        test_file = f"test{cfg_str}"

        row = [
            cfg_str,
            test_file,
            api, ts, bs, sc, nt,
            fpp, usd, sa,
            od, fs,
            lss, lsw
        ]
        writer.writerow(row)
        config_id += 1

print(f"Done! Generated {total} configurations in 'ior_configurations.csv'")
