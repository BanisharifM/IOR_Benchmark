import pandas as pd
import os

# === CONFIG ===
CSV_FILE = "configs/ior_configurations_llm.csv"
SLURM_TEMPLATE_DIR = "generated_slurms"
IOR_BIN = "~/.conda/envs/ior_env/bin/ior"
DARSHAN_LIB = "$HOME/.conda/envs/ior_env/lib/libdarshan.so"

os.makedirs(SLURM_TEMPLATE_DIR, exist_ok=True)

df = pd.read_csv(CSV_FILE)

for idx, row in df.iterrows():
    config_id = row["config_id"]
    test_file = row["testFile"]
    api = row["api"]
    transfer_size = row["transferSize"]
    block_size = row["blockSize"]
    segment_count = int(row["segmentCount"])
    num_tasks = int(row["numTasks"])
    file_per_proc = "-F" if int(row["filePerProc"]) == 1 else ""
    use_strided = "--mpiio.useStridedDatatype" if int(row["useStridedDatatype"]) == 1 else ""
    set_alignment = row["setAlignment"]
    use_o_direct = "--posix.odirect" if int(row["useO_DIRECT"]) == 1 else ""
    fsync = "-e" if int(row["fsync"]) == 1 else ""

    darshan_log = f"darshan_{test_file}.darshan"

    slurm_file = os.path.join(SLURM_TEMPLATE_DIR, f"ior_config_{config_id}.slurm")

    with open(slurm_file, "w") as f:
        f.write("#!/bin/bash\n")
        f.write(f"#SBATCH --job-name=ior_{config_id}\n")
        f.write("#SBATCH --account=bdau-delta-gpu\n")
        f.write("#SBATCH --partition=gpuA100x4-interactive\n")
        f.write("#SBATCH --nodes=1\n")
        f.write(f"#SBATCH --ntasks={num_tasks}\n")
        f.write("#SBATCH --gres=gpu:1\n")
        f.write("#SBATCH --cpus-per-task=2\n")
        f.write("#SBATCH --mem=64G\n")
        f.write("#SBATCH --time=01:00:00\n")
        f.write(f"#SBATCH --output=logs/slurm/ior_{config_id}_%j.out\n")
        f.write(f"#SBATCH --error=logs/slurm/ior_{config_id}_%j.err\n\n")

        f.write(f"export LD_PRELOAD=\"{DARSHAN_LIB}\"\n")
        f.write("export DARSHAN_ENABLE_NONMPI=1\n")
        f.write(f"export DARSHAN_LOGFILE=\"{darshan_log}\"\n\n")

        f.write(
            f"mpirun -n {num_tasks} {IOR_BIN} "
            f"-a {api} "
            f"-b {block_size} "
            f"-t {transfer_size} "
            f"-s {segment_count} "
            f"{file_per_proc} "
            f"-z "
            f"{fsync} "
            f"-C "
            f"{use_strided} "
            f"{use_o_direct} "
            f"-o {test_file}\n"
        )

        f.write(f"echo \"✅ Finished: {config_id}\"\n")

    print(f"✅ Generated {slurm_file}")

    # Submit job
    os.system(f"sbatch {slurm_file}")

    # Delete after submission
    os.remove(slurm_file)
    print(f"🗑️ Deleted {slurm_file} after submission.")

print("🎉 All jobs submitted and temporary slurm files cleaned up.")
