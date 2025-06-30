#!/bin/bash
#SBATCH --job-name=darshan_array
#SBATCH --account=bdau-delta-gpu
#SBATCH --partition=gpuA100x4-interactive
#SBATCH --nodes=1
#SBATCH --ntasks=1                     # we launch MPI inside the script
#SBATCH --cpus-per-task=4
#SBATCH --gres=gpu:1
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --array=1-100                  # 100 jobs
#SBATCH --export=ALL,LD_PRELOAD
#SBATCH --output=logs/slurm/darshan_array_%A_%a.out
#SBATCH --error=logs/slurm/darshan_array_%A_%a.err

# === Paths to binaries and Darshan ===
IOR_BIN="$HOME/.conda/envs/ior_env/bin/ior"
MPIRUN_BIN="$HOME/.conda/envs/ior_env/bin/mpirun"
LIBDARSHAN="$HOME/.conda/envs/ior_env/lib/libdarshan.so"
LIBSTDCPP=$(find "$HOME/.conda/envs/ior_env/lib/gcc" -name "libstdc++.so.6" | head -n 1)

# === Darshan env (exported to all ranks) ===
export DARSHAN_LOGDIR="$PWD/logs/tests"
export DARSHAN_LOGPATH="$DARSHAN_LOGDIR"
export DARSHAN_ENABLE_NONMPI=1
export DARSHAN_JOBID=$RANDOM
export LD_PRELOAD="$LIBSTDCPP:$LIBDARSHAN"

# === Create output dirs ===
mkdir -p "$DARSHAN_LOGDIR"/{$(date +%Y)/$(date +%-m)/$(date +%-d),slurm}

# === Parameter arrays to sample from ===
PROCS=(1 2 4 8 16 32 64 128)
APIS=(POSIX MPIIO HDF5)
BSIZES=(4k 16m 64m 256m)
TSIZES=(1k 1m 16m)
READMODES=("" "-C" "-e" "-C -e")

# helper to pick “round‐robin” from each array
pick() {
  local -n arr=$1   # name‐reference to array
  local idx=$(( (SLURM_ARRAY_TASK_ID - 1) % ${#arr[@]} ))
  echo "${arr[$idx]}"
}

# choose parameters for this array‐task
NTASKS=$(pick PROCS)
API=$(pick APIS)
BSIZE=$(pick BSIZES)
TSIZE=$(pick TSIZES)
READMODE=$(pick READMODES)

# unique names per job
DARSHAN_FILE="$DARSHAN_LOGDIR/job_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.darshan"
IOR_OUT="$DARSHAN_LOGDIR/ior_${SLURM_ARRAY_TASK_ID}.txt"

echo "▶️ Job $SLURM_ARRAY_TASK_ID: ntasks=$NTASKS api=$API bs=$BSIZE ts=$TSIZE readmode='$READMODE'"

# === Run IOR under Darshan ===
mpirun --oversubscribe -x LD_PRELOAD -np $NTASKS $IOR_BIN \
      -a $API \
      -b $BSIZE \
      -t $TSIZE \
      -i 5 \
      -F \
      $READMODE \
      -o "$DARSHAN_FILE" \
      -w > "$IOR_OUT" 2>&1

echo "✅ Completed job $SLURM_ARRAY_TASK_ID → $DARSHAN_FILE"
