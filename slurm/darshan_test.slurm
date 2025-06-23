#!/bin/bash
#SBATCH --job-name=darshan_test
#SBATCH --account=bdau-delta-gpu
#SBATCH --partition=gpuA100x4-interactive
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --output=logs/slurm/darshan_test_%j.out
#SBATCH --error=logs/slurm/darshan_test_%j.err

# Paths to binaries and libraries
IOR_BIN="$HOME/.conda/envs/ior_env/bin/ior"
MPIRUN_BIN="$HOME/.conda/envs/ior_env/bin/mpirun"
LIBDARSHAN="$HOME/.conda/envs/ior_env/lib/libdarshan.so"
LIBSTDCPP=$(find "$HOME/.conda/envs/ior_env/lib/gcc" -name "libstdc++.so.6" | head -n 1)

# Set log dir
export DARSHAN_LOGDIR="$PWD/logs/tests"
export DARSHAN_LOGPATH="$DARSHAN_LOGDIR"
export DARSHAN_ENABLE_NONMPI=1
export DARSHAN_JOBID=$RANDOM
export LD_PRELOAD="$LIBSTDCPP:$LIBDARSHAN"

mkdir -p "$DARSHAN_LOGDIR"

mkdir -p "$DARSHAN_LOGDIR/$(date +%Y)/$(date +%-m)/$(date +%-d)"

# Run IOR benchmark
$MPIRUN_BIN --oversubscribe -np 2 $IOR_BIN \
    -a POSIX \
    -b 1m \
    -t 64k \
    -i 1 \
    -o $DARSHAN_LOGDIR/darshan_test_file \
    -w
