#!/bin/bash
#SBATCH --job-name=ior_launcher
#SBATCH --account=bdau-delta-gpu
#SBATCH --partition=gpuA100x4-interactive
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:30:00
#SBATCH --output=logs/slurm/ior_launcher_%j.out
#SBATCH --error=logs/slurm/ior_launcher_%j.err

module load python

/u/mbanisharifdehkordi/.conda/envs/ior_env/bin/python scripts/generate_and_submit_slurms.py
