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

# === Paths to interpreter and parser script ===
PYTHON_BIN="$HOME/.conda/envs/ior_env/bin/python"
PARSER_SCRIPT="$HOME/Github/IOR_Benchmark/scripts/parse_darshan_dir.py"

# === Now clear Darshan before parsing ===
unset DARSHAN_LOGDIR
unset DARSHAN_LOGPATH
unset DARSHAN_ENABLE_NONMPI
unset DARSHAN_JOBID
unset LD_PRELOAD

# === Parse existing .darshan logs into CSV ===
$PYTHON_BIN $PARSER_SCRIPT logs/tests/2025/7/7 data/darshan_csv/darshan_parsed_output_7-7-V1.csv

echo "✅ Darshan parsing complete, output → data/darshan_csv/darshan_parsed_output_7-7-V1.csv"
