#!/bin/bash
#SBATCH --job-name=ior_gnn_optimized
#SBATCH --account=bdau-delta-gpu
#SBATCH --partition=gpuA40x4-interactive
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:30:00
#SBATCH --output=logs/slurm/ior_gnn_optimized_%j.out
#SBATCH --error=logs/slurm/ior_gnn_optimized_%j.err

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

echo "======================================================================="
echo "GNN-OPTIMIZED IOR TEST"
echo "Based on GNN Interpretability Analysis Bottleneck Detection"
echo "======================================================================="

# GNN-OPTIMIZED Configuration (Fair comparison - same 1MB total data)
echo ""
echo "GNN-OPTIMIZED CONFIGURATION (Fair Comparison)"
echo "-----------------------------------------------------------------------"
echo "Config: -t 1M -b 1M -C -Q 1 (1MB transfer, 1MB block, with alignment)"
echo ""
echo "This configuration addresses the bottlenecks identified by GNN consensus:"
echo "  1. POSIX_BYTES_WRITTEN (Rank #1, z-score: +3.163)"
echo "  2. POSIX_SIZE_WRITE_100_1K (Rank #2, z-score: +1.364) - Fixed by 1MB transfer"
echo "  3. POSIX_WRITES (Rank #3) - Reduced from 1024 to 1"
echo "  4. POSIX_FILE_ALIGNMENT (Rank #4) - Fixed with -C -Q 1 flags"
echo "  5. POSIX_CONSEC_WRITES (Rank #7) - Improved with single large write"
echo "-----------------------------------------------------------------------"

LD_PRELOAD="$LIBDARSHAN" $IOR_BIN \
    -a POSIX \
    -w \
    -t 1M \
    -b 1M \
    -C \
    -Q 1 \
    -Y \
    -o /tmp/ior_gnn_optimized_${SLURM_JOB_ID}

# Capture performance from IOR output
PERF_LINE=$(tail -n 20 logs/slurm/ior_gnn_optimized_${SLURM_JOB_ID}.out | grep -E "write.*MiB/sec" | tail -1)
echo ""
echo "IOR Performance Result:"
echo "$PERF_LINE"

# Clean up and save Darshan log
rm -f /tmp/ior_gnn_optimized_${SLURM_JOB_ID}
DARSHAN_FILE=$(find $DARSHAN_LOG_DIR -name "*ior*" -type f -mmin -1 2>/dev/null | head -1)
if [ -n "$DARSHAN_FILE" ]; then
    mv "$DARSHAN_FILE" "$DARSHAN_LOG_DIR/${SLURM_JOB_ID}_gnn_optimized.darshan"
    echo ""
    echo "Darshan log saved as: $DARSHAN_LOG_DIR/${SLURM_JOB_ID}_gnn_optimized.darshan"
fi