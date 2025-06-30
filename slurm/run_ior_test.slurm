#!/bin/bash
#SBATCH --job-name=ior_darshan_test
#SBATCH --account=bdau-delta-gpu
#SBATCH --partition=gpuA100x4-interactive
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4      # Will be updated per config
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --output=logs/slurm/ior_darshan_test_%j.out
#SBATCH --error=logs/slurm/ior_darshan_test_%j.err

# Load modules if needed
# module load mpi

# Paths to Darshan library (adjust if needed)
LIBDARSHAN="$HOME/.conda/envs/ior_env/lib/libdarshan.so"
LIBSTDCPP=$(find "$HOME/.conda/envs/ior_env/lib/gcc" -name "libstdc++.so.6" | head -n 1)

export LD_PRELOAD="$LIBSTDCPP:$LIBDARSHAN"
export DARSHAN_ENABLE_NONMPI=1

# ————————————————————————————————
# === Read first config from CSV ===
CSV_FILE="configs/ior_configuration_test.csv"
LINE_NUM=2  # Line 2 = first data row

CONFIG=$(sed -n "${LINE_NUM}p" "$CSV_FILE")
IFS=',' read -r config_id testFile api transferSize blockSize segmentCount numTasks filePerProc useStridedDatatype setAlignment useO_DIRECT fsync LUSTRE_STRIPE_SIZE LUSTRE_STRIPE_WIDTH <<< "$CONFIG"

echo "Running config: $config_id ($testFile)"
echo "API: $api | transferSize: $transferSize | blockSize: $blockSize | segmentCount: $segmentCount | numTasks: $numTasks"

# ————————————————————————————————
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

# ————————————————————————————————
# Specify Darshan log file explicitly
export DARSHAN_LOGFILE="darshan_${testFile}.darshan"

echo "Command: $CMD"
echo "Darshan log: $DARSHAN_LOGFILE"

# ————————————————————————————————
# Run benchmark
eval "$CMD"

echo "✅ Done — check $DARSHAN_LOGFILE"
