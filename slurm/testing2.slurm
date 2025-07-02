#!/bin/bash
#SBATCH --job-name=ior_darshan_diverse
#SBATCH --account=bdau-delta-gpu
#SBATCH --partition=gpuA100x4
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=5:00:00
#SBATCH --output=logs/slurm/ior_diverse_%j.out
#SBATCH --error=logs/slurm/ior_diverse_%j.err

export LD_PRELOAD="$HOME/.conda/envs/ior_env/lib/libdarshan.so"
export DARSHAN_ENABLE_NONMPI=1
export DARSHAN_LOGFILE="darshan_test_diverse.darshan"

# === Parameters to promote non-zero counters ===
# - Moderate block and transfer sizes to hit various buckets
# - Enough segments to generate seeks and access switches
# - Random offset to increase stride and access patterns
# - fsync to force write-out
# - Strided datatype to affect strided counters

mpirun -n 4 ~/.conda/envs/ior_env/bin/ior \
  -a MPIIO \
  -b 64M \             # Block size (moderate, not huge)
  -t 16K \            # Small transfer to increase I/O ops
  -s 64 \             # Enough segments to generate seeks
  -F \               # File per process to reduce lock contention
  -z \              # Random offsets
  -S \             # Strided datatype to hit stride counters
  -e \            # fsync to flush data
  -C \           # Reorder tasks to defeat cache reuse
  -o test_diverse

echo "✅ Finished — Darshan log: $DARSHAN_LOGFILE"
