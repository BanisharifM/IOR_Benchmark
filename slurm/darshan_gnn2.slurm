#!/bin/bash
#SBATCH --job-name=ior_sweep
#SBATCH --account=bdau-delta-gpu
#SBATCH --partition=gpuA100x4-interactive
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --time=01:00:00
#SBATCH --output=logs/slurm/darshan/ior_sweep_%j.out
#SBATCH --error=logs/slurm/darshan/ior_sweep_%j.err

# Save as: slurm/ior_parameter_sweep.sh

# Setup paths (same as before)
IOR_BIN="$HOME/.conda/envs/ior_env/bin/ior"
MPIRUN_BIN="$HOME/.conda/envs/ior_env/bin/mpirun"
LIBDARSHAN="$HOME/.conda/envs/ior_env/lib/libdarshan.so"
LIBSTDCPP=$(find "$HOME/.conda/envs/ior_env/lib/gcc" -name "libstdc++.so.6" | head -n 1)

# Darshan setup
export DARSHAN_LOGDIR="$HOME/ior-darshan-repo/logs"
mkdir -p "$DARSHAN_LOGDIR/$(date +%Y)/$(date +%-m)/$(date +%-d)"
export DARSHAN_LOG_PATH="$DARSHAN_LOGDIR"
export DARSHAN_ENABLE_NONMPI=1
export LD_PRELOAD="$LIBSTDCPP:$LIBDARSHAN"

# Create output directories
WORK_DIR="$PWD/ior_sweep_output"
RESULTS_DIR="$PWD/ior_sweep_results"
mkdir -p "$WORK_DIR" "$RESULTS_DIR"

echo "Starting IOR parameter sweep..."
echo "================================"

# Parameter arrays for sweep
TRANSFER_SIZES=("64k" "256k" "1m" "4m")
BLOCK_SIZES=("8m" "16m" "32m" "64m" "128m")
NUM_PROCS=(2 4 8)
PATTERNS=("sequential" "random" "strided")

# Counter for runs
RUN_NUM=0

# Loop through all combinations
for NP in "${NUM_PROCS[@]}"; do
    for TSIZE in "${TRANSFER_SIZES[@]}"; do
        for BSIZE in "${BLOCK_SIZES[@]}"; do
            for PATTERN in "${PATTERNS[@]}"; do
                
                RUN_NUM=$((RUN_NUM + 1))
                echo ""
                echo "Run $RUN_NUM: np=$NP, transfer=$TSIZE, block=$BSIZE, pattern=$PATTERN"
                echo "--------------------------------------------------------------"
                
                # Build IOR command based on pattern
                BASE_CMD="$MPIRUN_BIN -np $NP $IOR_BIN -a POSIX -t $TSIZE -b $BSIZE -F"
                
                case $PATTERN in
                    "sequential")
                        IOR_CMD="$BASE_CMD -w -r -k"
                        ;;
                    "random")
                        IOR_CMD="$BASE_CMD -w -r -z -k"
                        ;;
                    "strided")
                        IOR_CMD="$BASE_CMD -w -r -s 3 -k"
                        ;;
                esac
                
                # Add common flags
                IOR_CMD="$IOR_CMD -o $WORK_DIR/ior_${RUN_NUM}_${NP}p_${TSIZE}_${BSIZE}_${PATTERN}"
                
                # Set unique job ID for Darshan
                export DARSHAN_JOBID="${SLURM_JOB_ID}_run${RUN_NUM}"
                
                # Run IOR
                echo "Command: $IOR_CMD"
                eval $IOR_CMD
                
                # Small delay between runs
                sleep 2
                
                # Find and save the Darshan log
                DARSHAN_LOG=$(find "$DARSHAN_LOGDIR" -name "*${DARSHAN_JOBID}*.darshan" -type f -mmin -1 2>/dev/null | head -1)
                
                if [ -n "$DARSHAN_LOG" ]; then
                    echo "Found Darshan log: $DARSHAN_LOG"
                    # Copy to results directory with descriptive name
                    cp "$DARSHAN_LOG" "$RESULTS_DIR/ior_${RUN_NUM}_${NP}p_${TSIZE}_${BSIZE}_${PATTERN}.darshan"
                fi
                
                # Clean up IOR output files to save space
                rm -f $WORK_DIR/ior_${RUN_NUM}_*
                
            done
        done
    done
done

echo ""
echo "================================"
echo "IOR parameter sweep complete!"
echo "Generated $RUN_NUM different IOR configurations"
echo "Darshan logs saved in: $RESULTS_DIR"

# List all collected Darshan logs
echo ""
echo "Collected Darshan logs:"
ls -lh "$RESULTS_DIR"/*.darshan 2>/dev/null | wc -l