#!/bin/bash
#SBATCH --job-name=darshan_parse
#SBATCH --account=bdau-delta-gpu
#SBATCH --partition=gpuA100x4-interactive
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --output=logs/slurm/parse_darshan_%j.out
#SBATCH --error=logs/slurm/parse_darshan_%j.err

# === Paths to interpreter, parser script, and Darshan libs ===
PYTHON_BIN="$HOME/.conda/envs/ior_env/bin/python"
PARSER_SCRIPT="$HOME/Github/IOR_Benchmark/scripts/parse_darshan_dir.py"
LIBDARSHAN="$HOME/.conda/envs/ior_env/lib/libdarshan.so"
LIBSTDCPP=$(find "$HOME/.conda/envs/ior_env/lib/gcc" -name "libstdc++.so.6" | head -n 1)

# === Darshan environment (so parser can see the logs) ===
export DARSHAN_LOGDIR="$PWD/logs/tests"
export DARSHAN_LOGPATH="$DARSHAN_LOGDIR"
export DARSHAN_ENABLE_NONMPI=1
export DARSHAN_JOBID=$RANDOM
export LD_PRELOAD="$LIBSTDCPP:$LIBDARSHAN"

# === Make sure directories exist ===
mkdir -p "$DARSHAN_LOGDIR/$(date +%Y)/$(date +%-m)/$(date +%-d)"
mkdir -p logs/slurm

# === Invoke the parser over your 6/23 logs ===
$PYTHON_BIN $PARSER_SCRIPT "$DARSHAN_LOGDIR/2025/6/23" "data/darshan_parsed_output_6-23.csv"

echo "✅ Darshan parsing complete, output → data/darshan_parsed_output_6-23.csv"
