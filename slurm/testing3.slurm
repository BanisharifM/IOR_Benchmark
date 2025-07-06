#!/bin/bash
#SBATCH --job-name=ior_darshan_diverse16
#SBATCH --account=bdau-delta-gpu
#SBATCH --partition=gpuA100x4-interactive
#SBATCH --nodes=1
#SBATCH --ntasks=16
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=2
#SBATCH --mem=64G
#SBATCH --time=01:00:00
#SBATCH --output=logs/slurm/ior_diverse16_%j.out
#SBATCH --error=logs/slurm/ior_diverse16_%j.err

# Load modules or source your environment if needed
# source ~/.bashrc
# module load ...

export LD_PRELOAD="$HOME/.conda/envs/ior_env/lib/libdarshan.so"
export DARSHAN_ENABLE_NONMPI=1
export DARSHAN_LOGFILE="darshan_test_diverse16_Jul_6.darshan"

mpirun -n 16 ~/.conda/envs/ior_env/bin/ior \
  -a MPIIO \
  -b 32m \
  -t 16k \
  -s 32 \
  -F \
  -z \
  -e \
  -C \
  --mpiio.useStridedDatatype \
  -o testfile_diverse16
