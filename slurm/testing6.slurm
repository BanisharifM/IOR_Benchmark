#!/bin/bash
#SBATCH --job-name=ior_test_nof
#SBATCH --account=bdau-delta-gpu
#SBATCH --partition=gpuA100x4-interactive
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=2
#SBATCH --mem=32G
#SBATCH --time=01:00:00
#SBATCH --output=logs/slurm/ior_test_nof_%j.out
#SBATCH --error=logs/slurm/ior_test_nof_%j.err

export LD_PRELOAD="$HOME/.conda/envs/ior_env/lib/libdarshan.so"
export DARSHAN_ENABLE_NONMPI=1
export DARSHAN_LOGFILE="$SLURM_SUBMIT_DIR/darshan_test_nof.darshan_%h_%p"

IOR_BIN="/u/mbanisharifdehkordi/software/src/ior-4.0.0/src/ior"

mpirun -n 4 $IOR_BIN \
  -a POSIX \
  -b 1M \
  -t 4K \
  -s 1 \
  -z \
  -o test00019_old

echo "✅ Finished test with shared file (no -F, no -C)"