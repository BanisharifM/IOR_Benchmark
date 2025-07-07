#!/bin/bash
#SBATCH --job-name=ior_hdf5_test
#SBATCH --account=bdau-delta-gpu
#SBATCH --partition=gpuA100x4-interactive
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=2
#SBATCH --mem=32G
#SBATCH --time=01:00:00
#SBATCH --output=logs/slurm/ior_hdf5_test_%j.out
#SBATCH --error=logs/slurm/ior_hdf5_test_%j.err

export LD_PRELOAD="$HOME/.conda/envs/ior_env/lib/libdarshan.so"
export DARSHAN_ENABLE_NONMPI=1
export DARSHAN_LOGFILE="$SLURM_SUBMIT_DIR/darshan_hdf5_test.darshan_%h_%p"

# Adjust this to your rebuilt IOR binary with HDF5 support
IOR_BIN="/u/mbanisharifdehkordi/software/src/ior-4.0.0/src/ior"

mpirun -n 4 $IOR_BIN \
  -a HDF5 \
  -b 4M \
  -t 1M \
  -s 4 \
  -F \
  -z \
  -C \
  -o hdf5_test_file

echo "✅ Finished HDF5 manual test"
