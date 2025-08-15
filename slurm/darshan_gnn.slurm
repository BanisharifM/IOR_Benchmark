#!/bin/bash
#SBATCH --job-name=darshan_test
#SBATCH --account=bdau-delta-gpu
#SBATCH --partition=gpuA100x4-interactive
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --output=logs/slurm/darshan/darshan_gnn_%j.out
#SBATCH --error=logs/slurm/darshan/darshan_gnn_%j.err

# Paths to binaries and libraries
IOR_BIN="$HOME/.conda/envs/ior_env/bin/ior"
MPIRUN_BIN="$HOME/.conda/envs/ior_env/bin/mpirun"
LIBDARSHAN="$HOME/.conda/envs/ior_env/lib/libdarshan.so"
LIBSTDCPP=$(find "$HOME/.conda/envs/ior_env/lib/gcc" -name "libstdc++.so.6" | head -n 1)

# CRITICAL FIX: Create the directory Darshan expects
export DARSHAN_LOGDIR="$HOME/ior-darshan-repo/logs"
mkdir -p "$DARSHAN_LOGDIR/$(date +%Y)/$(date +%-m)/$(date +%-d)"

# Set Darshan environment variables
export DARSHAN_LOG_PATH="$DARSHAN_LOGDIR"
export DARSHAN_LOG_DIR="$DARSHAN_LOGDIR"  # Some versions use this
export DARSHAN_LOGPATH="$DARSHAN_LOGDIR"  # Try both variants
export DARSHAN_ENABLE_NONMPI=1
export DARSHAN_JOBID=$SLURM_JOB_ID
export LD_PRELOAD="$LIBSTDCPP:$LIBDARSHAN"

# Additional settings
export DXT_ENABLE_IO_TRACE=1
export DARSHAN_DISABLE_SHARED_REDUCTION=0  # Enable shared reduction

echo "Starting IOR benchmark with Darshan instrumentation..."
echo "Darshan log directory: $DARSHAN_LOGDIR"
echo "Creating required directories..."
ls -la "$DARSHAN_LOGDIR/$(date +%Y)/$(date +%-m)/$(date +%-d)/"

# Create a temporary working directory for IOR output files
WORK_DIR="$PWD/ior_output"
mkdir -p "$WORK_DIR"

# Run IOR benchmark
echo "Running IOR..."
$MPIRUN_BIN -np 4 $IOR_BIN \
    -a POSIX \
    -t 64k 
    -b 16m 
    -F 
    -w 
    -r
    -o $WORK_DIR/ior_test_file \

echo "IOR completed."

# Wait for Darshan to finalize
sleep 5

# Find the generated Darshan log
echo "Looking for Darshan logs in $DARSHAN_LOGDIR..."
find "$DARSHAN_LOGDIR" -name "*.darshan*" -type f -mmin -5 -ls

# Also check the date-based subdirectory
TODAY_DIR="$DARSHAN_LOGDIR/$(date +%Y)/$(date +%-m)/$(date +%-d)"
echo "Checking today's directory: $TODAY_DIR"
ls -la "$TODAY_DIR/" 2>/dev/null

# Find any Darshan logs
DARSHAN_LOG=$(find "$DARSHAN_LOGDIR" -name "*.darshan" -o -name "*.darshan_partial" -type f -mmin -5 2>/dev/null | head -1)

if [ -n "$DARSHAN_LOG" ]; then
    echo "Found Darshan log: $DARSHAN_LOG"
    
    # Check if it's a complete log (not partial)
    if [[ "$DARSHAN_LOG" == *"partial"* ]]; then
        echo "Warning: Found partial log. Waiting for completion..."
        sleep 5
        # Try to find complete log
        DARSHAN_LOG=$(find "$DARSHAN_LOGDIR" -name "*.darshan" -type f -mmin -5 2>/dev/null | head -1)
    fi
    
    # Parse the log
    DARSHAN_PARSER="$HOME/.conda/envs/ior_env/bin/darshan-parser"
    
    if [ -f "$DARSHAN_PARSER" ] && [ -n "$DARSHAN_LOG" ]; then
        JSON_OUTPUT="${DARSHAN_LOG%.darshan}.json"
        echo "Converting to JSON..."
        $DARSHAN_PARSER --json "$DARSHAN_LOG" > "$JSON_OUTPUT" 2>/dev/null
        
        if [ -s "$JSON_OUTPUT" ]; then
            echo "JSON output saved to: $JSON_OUTPUT"
            echo "Preview of JSON structure:"
            head -100 "$JSON_OUTPUT"
        else
            echo "Failed to parse Darshan log to JSON"
        fi
    fi
else
    echo "No Darshan log found!"
    echo "Checking all possible locations..."
    find "$HOME" -name "*${SLURM_JOB_ID}*.darshan*" -type f 2>/dev/null
fi

echo "Job complete!"