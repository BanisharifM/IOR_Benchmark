#!/bin/bash
#SBATCH --job-name=ior_darshan_array
#SBATCH --account=bdau-delta-gpu
#SBATCH --partition=gpuA100x4
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --time=02:00:00
#SBATCH --array=1-4000%20
#SBATCH --output=logs/slurm/ior_array_%A_%a.out
#SBATCH --error=logs/slurm/ior_array_%A_%a.err

# Load modules if needed
# module load darshan

# Darshan setup
LIBDARSHAN="$HOME/.conda/envs/ior_env/lib/libdarshan.so"
LIBSTDCPP=$(find "$HOME/.conda/envs/ior_env/lib/gcc" -name "libstdc++.so.6" | head -n 1)

export LD_PRELOAD="$LIBSTDCPP:$LIBDARSHAN"
export DARSHAN_ENABLE_NONMPI=1

# CSV configuration
CSV_FILE="configs/ior_configurations_targeted.csv"
LINE_NUM=$((SLURM_ARRAY_TASK_ID + 1))  # CSV header is line 1

CONFIG=$(sed -n "${LINE_NUM}p" "$CSV_FILE")
IFS=',' read -r config_id testFile api transferSize blockSize segmentCount numTasks filePerProc useStridedDatatype setAlignment useO_DIRECT fsync LUSTRE_STRIPE_SIZE LUSTRE_STRIPE_WIDTH <<< "$CONFIG"

echo "🚀 Running config $config_id ($testFile)"

# Base IOR command
CMD="mpirun -n ${numTasks} ./ior -a ${api} -t ${transferSize} -b ${blockSize} -s ${segmentCount} -o ${testFile}"

# Explicitly enable write and read
CMD+=" -w -r"

# File per process
if [[ "$filePerProc" -eq 1 ]]; then
    CMD+=" -F"
fi

# Strided datatype
if [[ "$useStridedDatatype" -eq 1 ]]; then
    CMD+=" -S"
fi

# Alignment
if [[ "$setAlignment" == "4K" ]]; then
    CMD+=" -J 4k"
elif [[ "$setAlignment" == "1M" ]]; then
    CMD+=" -J 1m"
fi

# O_DIRECT for POSIX
if [[ "$useO_DIRECT" -eq 1 && "$api" == "POSIX" ]]; then
    CMD+=" --posix.odirect"
fi

# fsync
if [[ "$fsync" -eq 1 ]]; then
    CMD+=" -e"
fi

# Lustre options (POSIX only)
if [[ "$api" == "POSIX" ]]; then
    CMD+=" -O posix.lustre.stripesize=${LUSTRE_STRIPE_SIZE}"
    CMD+=" -O posix.lustre.stripecount=${LUSTRE_STRIPE_WIDTH}"
fi

# Darshan log
export DARSHAN_LOGFILE="logs/tests/2025/6/30/darshan_${testFile}.darshan"

echo "Command: $CMD"
echo "Darshan log: $DARSHAN_LOGFILE"

# Run benchmark
eval "$CMD"

echo "✅ Done — Darshan log: $DARSHAN_LOGFILE"
