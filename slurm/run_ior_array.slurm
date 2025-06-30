#!/bin/bash
#SBATCH --job-name=ior_darshan_array
#SBATCH --account=bdau-delta-gpu
#SBATCH --partition=gpuA100x4-interactive
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1          # We dynamically control inside
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --array=1-5000%20
#SBATCH --output=logs/slurm/ior_array_%A_%a.out
#SBATCH --error=logs/slurm/ior_array_%A_%a.err

# ————————————————————————————
# Paths to Darshan library (adjust if needed)
LIBDARSHAN="$HOME/.conda/envs/ior_env/lib/libdarshan.so"
LIBSTDCPP=$(find "$HOME/.conda/envs/ior_env/lib/gcc" -name "libstdc++.so.6" | head -n 1)

export LD_PRELOAD="$LIBSTDCPP:$LIBDARSHAN"
export DARSHAN_ENABLE_NONMPI=1

# ————————————————————————————
# CSV configuration
CSV_FILE="configs/ior_configuration_test.csv"
LINE_NUM=$((SLURM_ARRAY_TASK_ID + 1))  # CSV header is line 1

CONFIG=$(sed -n "${LINE_NUM}p" "$CSV_FILE")
IFS=',' read -r config_id testFile api transferSize blockSize segmentCount numTasks filePerProc useStridedDatatype setAlignment useO_DIRECT fsync LUSTRE_STRIPE_SIZE LUSTRE_STRIPE_WIDTH <<< "$CONFIG"

echo "🚀 Running config: $config_id ($testFile)"
echo "API: $api | transferSize: $transferSize | blockSize: $blockSize | segmentCount: $segmentCount | numTasks: $numTasks"

# ————————————————————————————
# Build IOR command
CMD="mpirun -n ${numTasks} ./ior -a ${api} -t ${transferSize} -b ${blockSize} -s ${segmentCount}"

if [[ "$filePerProc" -eq 1 ]]; then
    CMD+=" -F"
fi

if [[ "$useStridedDatatype" -eq 1 ]]; then
    CMD+=" -S"
fi

CMD+=" -J ${setAlignment}"

# Only add POSIX-specific options if api == POSIX
if [[ "$api" == "POSIX" ]]; then
    if [[ "$useO_DIRECT" -eq 1 ]]; then
        CMD+=" --posix.odirect"
    fi

    CMD+=" -O POSIX.lustre.stripesize=${LUSTRE_STRIPE_SIZE}"
    CMD+=" -O POSIX.lustre.stripecount=${LUSTRE_STRIPE_WIDTH}"
fi

if [[ "$fsync" -eq 1 ]]; then
    CMD+=" -e"
fi

CMD+=" -o ${testFile}"

# ————————————————————————————
# Specify Darshan log file explicitly
export DARSHAN_LOGFILE="darshan_${testFile}.darshan"

echo "Command: $CMD"
echo "Darshan log: $DARSHAN_LOGFILE"

# ————————————————————————————
# Run benchmark
eval "$CMD"

echo "✅ Done — Darshan log: $DARSHAN_LOGFILE"
