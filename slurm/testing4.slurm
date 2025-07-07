#!/bin/bash
#SBATCH --job-name=ior_test_64
#SBATCH --account=bdau-delta-gpu
#SBATCH --partition=gpuA100x4-interactive
#SBATCH --nodes=4
#SBATCH --ntasks=64
#SBATCH --ntasks-per-node=16
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=2
#SBATCH --mem=64G
#SBATCH --time=01:00:00
#SBATCH --output=logs/slurm/ior_test_64_%j.out
#SBATCH --error=logs/slurm/ior_test_64_%j.err

export LD_PRELOAD="$HOME/.conda/envs/ior_env/lib/libdarshan.so"
export DARSHAN_ENABLE_NONMPI=1
export DARSHAN_LOGFILE="$SLURM_SUBMIT_DIR/darshan_test_64.darshan"

mpirun -n 64 ~/.conda/envs/ior_env/bin/ior \
  -a MPIIO \
  -b 4M \
  -t 1M \
  -s 16 \
  -F \
  -z \
  -C \
  --mpiio.useStridedDatatype \
  -o testfile_64

echo "✅ Finished 64-task example test"
