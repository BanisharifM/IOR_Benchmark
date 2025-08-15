#!/bin/bash
#SBATCH --job-name=ior_optimization_test
#SBATCH --account=bdau-delta-gpu
#SBATCH --partition=gpuA40x4-interactive
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=01:00:00
#SBATCH --output=logs/slurm/ior_optimization_%j.out
#SBATCH --error=logs/slurm/ior_optimization_%j.err

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
echo "IOR PERFORMANCE OPTIMIZATION COMPARISON"
echo "Based on GNN Interpretability Analysis"
echo "======================================================================="

# Test 1: BASELINE (Your Original - Expected ~5 MB/s)
echo ""
echo "TEST 1: BASELINE (Original Configuration)"
echo "-----------------------------------------------------------------------"
echo "Config: -t 1k -b 1m (1KB transfers, 1MB block)"
LD_PRELOAD="$LIBDARSHAN" $IOR_BIN \
    -a POSIX \
    -w \
    -t 1k \
    -b 1m \
    -Y \
    -o /tmp/ior_baseline_${SLURM_JOB_ID}

# Clean up and save Darshan log
rm -f /tmp/ior_baseline_${SLURM_JOB_ID}
DARSHAN_FILE=$(find $DARSHAN_LOG_DIR -name "*ior*" -type f -mmin -1 2>/dev/null | head -1)
if [ -n "$DARSHAN_FILE" ]; then
    mv "$DARSHAN_FILE" "$DARSHAN_LOG_DIR/${SLURM_JOB_ID}_baseline.darshan"
fi
sleep 2

# Test 2: AIIO SUGGESTION (Expected ~160 MB/s)
echo ""
echo "TEST 2: AIIO SUGGESTION"
echo "-----------------------------------------------------------------------"
echo "Config: -t 1m -b 1m (1MB transfers, 1MB block)"
LD_PRELOAD="$LIBDARSHAN" $IOR_BIN \
    -a POSIX \
    -w \
    -t 1m \
    -b 1m \
    -Y \
    -o /tmp/ior_aiio_${SLURM_JOB_ID}

# Clean up and save Darshan log
rm -f /tmp/ior_aiio_${SLURM_JOB_ID}
DARSHAN_FILE=$(find $DARSHAN_LOG_DIR -name "*ior*" -type f -mmin -1 2>/dev/null | head -1)
if [ -n "$DARSHAN_FILE" ]; then
    mv "$DARSHAN_FILE" "$DARSHAN_LOG_DIR/${SLURM_JOB_ID}_aiio.darshan"
fi
sleep 2

# Test 3: GNN-OPTIMIZED (Addressing all 5 bottlenecks - Expected 800+ MB/s)
echo ""
echo "TEST 3: GNN-OPTIMIZED (Multi-Bottleneck Solution)"
echo "-----------------------------------------------------------------------"
echo "Config: -t 1M -b 64M -s 1 -C -Q 1 (1MB transfers, 64MB block, aligned)"
echo "Addresses: POSIX_SIZE_WRITE_100_1K, POSIX_BYTES_WRITTEN, POSIX_WRITES,"
echo "          POSIX_FILE_ALIGNMENT, POSIX_CONSEC_WRITES"
LD_PRELOAD="$LIBDARSHAN" $IOR_BIN \
    -a POSIX \
    -w \
    -t 1M \
    -b 64M \
    -s 1 \
    -C \
    -Q 1 \
    -Y \
    -o /tmp/ior_gnn_optimized_${SLURM_JOB_ID}

# Clean up and save Darshan log
rm -f /tmp/ior_gnn_optimized_${SLURM_JOB_ID}
DARSHAN_FILE=$(find $DARSHAN_LOG_DIR -name "*ior*" -type f -mmin -1 2>/dev/null | head -1)
if [ -n "$DARSHAN_FILE" ]; then
    mv "$DARSHAN_FILE" "$DARSHAN_LOG_DIR/${SLURM_JOB_ID}_gnn_optimized.darshan"
fi
sleep 2

# Test 4: ULTRA-OPTIMIZED (Maximum performance - Expected 1000+ MB/s)
echo ""
echo "TEST 4: ULTRA-OPTIMIZED (GNN + Additional Optimizations)"
echo "-----------------------------------------------------------------------"
echo "Config: -t 4M -b 256M -s 1 -F -C (4MB transfers, 256MB block, file-per-process)"
LD_PRELOAD="$LIBDARSHAN" $IOR_BIN \
    -a POSIX \
    -w \
    -t 4M \
    -b 256M \
    -s 1 \
    -F \
    -C \
    -Y \
    -o /tmp/ior_ultra_${SLURM_JOB_ID}

# Clean up and save Darshan log
rm -f /tmp/ior_ultra_${SLURM_JOB_ID}
DARSHAN_FILE=$(find $DARSHAN_LOG_DIR -name "*ior*" -type f -mmin -1 2>/dev/null | head -1)
if [ -n "$DARSHAN_FILE" ]; then
    mv "$DARSHAN_FILE" "$DARSHAN_LOG_DIR/${SLURM_JOB_ID}_ultra.darshan"
fi

echo ""
echo "======================================================================="
echo "PERFORMANCE COMPARISON SUMMARY"
echo "======================================================================="
echo ""
echo "All tests completed. Darshan logs saved in: $DARSHAN_LOG_DIR"
echo ""
echo "To analyze the results, run:"
echo "  darshan-parser $DARSHAN_LOG_DIR/${SLURM_JOB_ID}_baseline.darshan | grep \"agg_perf_by_slowest\""
echo "  darshan-parser $DARSHAN_LOG_DIR/${SLURM_JOB_ID}_aiio.darshan | grep \"agg_perf_by_slowest\""
echo "  darshan-parser $DARSHAN_LOG_DIR/${SLURM_JOB_ID}_gnn_optimized.darshan | grep \"agg_perf_by_slowest\""
echo "  darshan-parser $DARSHAN_LOG_DIR/${SLURM_JOB_ID}_ultra.darshan | grep \"agg_perf_by_slowest\""
echo ""
echo "Expected Performance Improvements:"
echo "  Baseline:       ~5 MB/s     (1x)"
echo "  AIIO:           ~160 MB/s   (32x)"
echo "  GNN-Optimized:  ~800 MB/s   (160x)"
echo "  Ultra:          ~1000+ MB/s (200x+)"
echo "======================================================================="

# Quick performance extraction
echo ""
echo "Extracting key bottleneck metrics from each test:"
echo ""
for test in baseline aiio gnn_optimized ultra; do
    log_file="$DARSHAN_LOG_DIR/${SLURM_JOB_ID}_${test}.darshan"
    if [ -f "$log_file" ]; then
        echo "=== $test ==="
        darshan-parser "$log_file" | grep -E "POSIX_SIZE_WRITE_0_100|POSIX_SIZE_WRITE_100_1K|POSIX_WRITES:|POSIX_BYTES_WRITTEN:|agg_perf_by_slowest" | head -10
        echo ""
    fi
done