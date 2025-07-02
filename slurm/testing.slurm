#!/bin/bash
#SBATCH --job-name=ior_darshan_scriptfile
#SBATCH --account=bdau-delta-gpu
#SBATCH --partition=gpuA100x4
#SBATCH --nodes=1
#SBATCH --ntasks=4             
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=10:00:00
#SBATCH --output=logs/slurm/ior_direct_%j.out
#SBATCH --error=logs/slurm/ior_direct_%j.err

export LD_PRELOAD="$HOME/.conda/envs/ior_env/lib/libdarshan.so"
export DARSHAN_ENABLE_NONMPI=1
export DARSHAN_LOGFILE="darshan_test_random_offset3.darshan"

mpirun -n 4 ~/.conda/envs/ior_env/bin/ior -a MPIIO -b 256M -t 4K -s 128 -z -e -o test_random_offset
