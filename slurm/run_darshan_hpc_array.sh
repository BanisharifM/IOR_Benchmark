#!/bin/bash
#SBATCH --job-name=darshan_hpc
#SBATCH --account=bdau-delta-gpu
#SBATCH --partition=gpuA100x4-interactive
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --array=1-100%10
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --export=ALL,LD_PRELOAD
#SBATCH --output=logs/slurm/darshan_hpc_%A_%a.out
#SBATCH --error=logs/slurm/darshan_hpc_%A_%a.err

# ——————————————————————————————  
# Paths to Darshan & stdc++  
LIBDARSHAN="$HOME/.conda/envs/ior_env/lib/libdarshan.so"
LIBSTDCPP=$(find "$HOME/.conda/envs/ior_env/lib/gcc" -name "libstdc++.so.6" | head -n 1)

# ——————————————————————————————  
# Build out the per‐day log directory
DATE_DIR="$(date +%Y)/$(date +%-m)/$(date +%-d)"
LOGDIR="$PWD/logs/tests/$DATE_DIR"
mkdir -p "$LOGDIR"

# Where Darshan will write this run’s file:
DARSHAN_FILE="$LOGDIR/run_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.darshan"

# ——————————————————————————————  
# Pull the Nth command from your list…
COMMAND=$(sed -n "${SLURM_ARRAY_TASK_ID}q;d" hpc_commands.txt)
if [[ -z "$COMMAND" ]]; then
  echo "[ERROR] no command found for task $SLURM_ARRAY_TASK_ID" >&2
  exit 1
fi

echo "⏳ [${SLURM_ARRAY_TASK_ID}/100] $COMMAND"

# ——————————————————————————————  
# Wrap **only** the application in Darshan instrumentation:
(
  export DARSHAN_LOGDIR="$LOGDIR"
  export DARSHAN_LOGPATH="$LOGDIR"
  export DARSHAN_ENABLE_NONMPI=1
  export DARSHAN_JOBID=$RANDOM
  export LD_PRELOAD="$LIBSTDCPP:$LIBDARSHAN"

  # run the user’s command line
  eval "$COMMAND"
)

echo "✅ job ${SLURM_ARRAY_TASK_ID} done → $DARSHAN_FILE"
