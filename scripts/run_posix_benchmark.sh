#!/bin/bash

# POSIX I/O Benchmark Execution Script with Darshan Logging
# This script runs IOR with POSIX interface and Darshan profiling

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$REPO_DIR/logs"
CONFIG_DIR="$REPO_DIR/configs"

# Default parameters (can be overridden)
BLOCK_SIZE="${BLOCK_SIZE:-1g}"
TRANSFER_SIZE="${TRANSFER_SIZE:-1m}"
NUM_TASKS="${NUM_TASKS:-4}"
ITERATIONS="${ITERATIONS:-3}"
TEST_FILE="${TEST_FILE:-$LOG_DIR/ior_posix_testfile}"
SEGMENT_COUNT="${SEGMENT_COUNT:-1}"

# Darshan setup
DARSHAN_PREFIX="$HOME/software/darshan"
IOR_PREFIX="$HOME/software/ior"

echo "=== Running POSIX I/O Benchmark with Darshan Logging ==="

# Check if Darshan and IOR are installed
if [ ! -f "$DARSHAN_PREFIX/lib/libdarshan.so" ]; then
    echo "Error: Darshan not found. Please run ./scripts/install_darshan.sh first"
    exit 1
fi

if [ ! -f "$IOR_PREFIX/bin/ior" ]; then
    echo "Error: IOR not found. Please run ./scripts/install_ior.sh first"
    exit 1
fi

# Create log directory
mkdir -p "$LOG_DIR"

# Setup environment
export PATH="$IOR_PREFIX/bin:$DARSHAN_PREFIX/bin:$PATH"
export LD_LIBRARY_PATH="$DARSHAN_PREFIX/lib:$LD_LIBRARY_PATH"
export LD_PRELOAD="$DARSHAN_PREFIX/lib/libdarshan.so"
export DARSHAN_ENABLE_NONMPI=1
export DARSHAN_LOG_PATH="$LOG_DIR"

# Create timestamp for this run
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RUN_ID="posix_${TIMESTAMP}"

echo "Configuration:"
echo "  Block size: $BLOCK_SIZE"
echo "  Transfer size: $TRANSFER_SIZE"
echo "  Number of tasks: $NUM_TASKS"
echo "  Iterations: $ITERATIONS"
echo "  Test file: $TEST_FILE"
echo "  Log directory: $LOG_DIR"
echo "  Run ID: $RUN_ID"

# Clean up any existing test files
rm -f "$TEST_FILE"*

# Create IOR configuration file for this run
IOR_CONFIG="$CONFIG_DIR/ior_posix_${RUN_ID}.conf"
cat > "$IOR_CONFIG" << EOF
# IOR Configuration for POSIX I/O Test
# Generated on $(date)

# Test parameters
-a POSIX                    # Use POSIX interface
-b $BLOCK_SIZE             # Block size per task
-t $TRANSFER_SIZE          # Transfer size
-s $SEGMENT_COUNT          # Number of segments
-i $ITERATIONS             # Number of iterations

# File settings
-o $TEST_FILE              # Test file name
-F                         # File per process
-e                         # Fsync after each write

# Test operations
-w                         # Write test
-r                         # Read test
-C                         # Reorder tasks randomly

# Output options
-v                         # Verbose output
-V                         # Show version
EOF

echo "Starting IOR benchmark with Darshan profiling..."

# Run IOR with MPI
mpirun -np "$NUM_TASKS" \
    --oversubscribe \
    ior -f "$IOR_CONFIG" \
    2>&1 | tee "$LOG_DIR/ior_posix_${RUN_ID}.out"

echo "IOR benchmark completed."

# Wait a moment for Darshan to finish writing logs
sleep 2

# Find the generated Darshan log file
DARSHAN_LOG=$(find "$LOG_DIR" -name "*${RUN_ID}*darshan" -o -name "*$(date +%Y_%m_%d)*darshan" | head -1)

if [ -z "$DARSHAN_LOG" ]; then
    # Look for any recent Darshan log
    DARSHAN_LOG=$(find "$LOG_DIR" -name "*.darshan" -mmin -5 | head -1)
fi

if [ -n "$DARSHAN_LOG" ] && [ -f "$DARSHAN_LOG" ]; then
    echo "Darshan log generated: $DARSHAN_LOG"
    
    # Parse Darshan log
    echo "Parsing Darshan log..."
    darshan-parser "$DARSHAN_LOG" > "$LOG_DIR/darshan_posix_${RUN_ID}.txt"
    
    # Generate summary
    echo "Generating Darshan summary..."
    darshan-job-summary.pl "$DARSHAN_LOG" --output "$LOG_DIR/darshan_posix_${RUN_ID}_summary.pdf" 2>/dev/null || echo "Note: PDF summary generation requires additional dependencies"
    
    # Extract POSIX counters
    echo "Extracting POSIX I/O counters..."
    python3 "$SCRIPT_DIR/extract_posix_counters.py" "$DARSHAN_LOG" "$LOG_DIR/posix_counters_${RUN_ID}.csv"
    
else
    echo "Warning: Darshan log file not found. Check Darshan configuration."
    echo "Looking for logs in: $LOG_DIR"
    ls -la "$LOG_DIR"/*.darshan 2>/dev/null || echo "No .darshan files found"
fi

# Clean up test files
echo "Cleaning up test files..."
rm -f "$TEST_FILE"*

echo "=== POSIX I/O Benchmark completed ==="
echo "Results saved to:"
echo "  IOR output: $LOG_DIR/ior_posix_${RUN_ID}.out"
if [ -n "$DARSHAN_LOG" ] && [ -f "$DARSHAN_LOG" ]; then
    echo "  Darshan log: $DARSHAN_LOG"
    echo "  Parsed log: $LOG_DIR/darshan_posix_${RUN_ID}.txt"
    echo "  POSIX counters: $LOG_DIR/posix_counters_${RUN_ID}.csv"
fi

