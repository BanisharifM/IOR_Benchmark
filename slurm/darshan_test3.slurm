#!/bin/bash
#SBATCH --job-name=darshan_test
#SBATCH --account=bdau-delta-gpu
#SBATCH --partition=gpuA100x4-interactive
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --output=logs/slurm/darshan_test_%j.out
#SBATCH --error=logs/slurm/darshan_test_%j.err

# === Paths to binaries and libraries ===
IOR_BIN="$HOME/.conda/envs/ior_env/bin/ior"
MPIRUN_BIN="$HOME/.conda/envs/ior_env/bin/mpirun"
LIBDARSHAN="$HOME/.conda/envs/ior_env/lib/libdarshan.so"
LIBSTDCPP=$(find "$HOME/.conda/envs/ior_env/lib/gcc" -name "libstdc++.so.6" | head -n 1)

# === Create required log directories (unwrapped) ===
mkdir -p "$PWD/logs/tests"
mkdir -p "$PWD/logs/tests/$(date +%Y)/$(date +%-m)/$(date +%-d)"

# === Define output paths ===
DARSHAN_FILE="$PWD/logs/tests/darshan_test_file.darshan"
CSV_OUTPUT="data/IOR/Test/output_1.csv"

# === Run IOR under Darshan (wrapped) ===
(
  export DARSHAN_LOGDIR="$PWD/logs/tests"
  export DARSHAN_LOGPATH="$DARSHAN_LOGDIR"
  export DARSHAN_ENABLE_NONMPI=1
  export DARSHAN_JOBID=$RANDOM
  export LD_PRELOAD="$LIBSTDCPP:$LIBDARSHAN"

  $MPIRUN_BIN --oversubscribe -np 8 $IOR_BIN \
    -a POSIX \
    -b 16m \
    -t 1m \
    -i 5 \
    -F \
    -o "$DARSHAN_FILE" \
    -w > "$PWD/logs/tests/ior_output.txt" 2>&1
)

echo "✅ IOR + Darshan run complete."
