#!/bin/bash
#SBATCH --job-name=darshan_test
#SBATCH --account=bdau-delta-gpu
#SBATCH --partition=gpuA40x4-interactive
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=01:00:00
#SBATCH --output=logs/slurm/darshan_test_%j.out
#SBATCH --error=logs/slurm/darshan_test_%j.err

# Paths to binaries
IOR_BIN="$HOME/.conda/envs/ior_env/bin/ior"
LIBDARSHAN="$HOME/.conda/envs/ior_env/lib/libdarshan.so"

# Set Darshan environment variables
export DARSHAN_LOG_DIR="/work/hdd/bdau/mbanisharifdehkordi/GNN_4_IO_5/darshan_log"
export DARSHAN_LOGPATH="$DARSHAN_LOG_DIR"
export DARSHAN_LOGDIR="$DARSHAN_LOG_DIR"
export DARSHAN_LOG_PATH="$DARSHAN_LOG_DIR"
export DARSHAN_DISABLE_SHARED_REDUCTION=1
export DXT_ENABLE_IO_TRACE=1

# Create the log directory with date structure
mkdir -p "$DARSHAN_LOG_DIR/$(date +%Y)/$(date +%-m)/$(date +%-d)"

# Run IOR directly (no mpirun) with Darshan preloaded ONLY for IOR
LD_PRELOAD="$LIBDARSHAN" $IOR_BIN \
    -a POSIX \
    -w \
    -t 1k \
    -b 1m \
    -Y \
    -o /tmp/ior_test_${SLURM_JOB_ID}

# Clean up the test file
rm -f /tmp/ior_test_${SLURM_JOB_ID}

# Find and rename the Darshan log
DARSHAN_FILE=$(find $DARSHAN_LOG_DIR -name "*ior*" -type f -mmin -1 2>/dev/null | head -1)
if [ -n "$DARSHAN_FILE" ]; then
    mv "$DARSHAN_FILE" "$DARSHAN_LOG_DIR/${SLURM_JOB_ID}_w_t1k_b1m_Y.darshan"
    echo "Darshan log saved as: $DARSHAN_LOG_DIR/${SLURM_JOB_ID}_w_t1k_b1m_Y.darshan"
    
    # Parse the log to verify
    echo "Parsing Darshan log..."
    darshan-parser "$DARSHAN_LOG_DIR/${SLURM_JOB_ID}_w_t1k_b1m_Y.darshan" | grep -E "POSIX_OPENS|POSIX_WRITES|POSIX_BYTES_WRITTEN"
else
    echo "No Darshan log found"
fi