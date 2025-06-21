#!/bin/bash
# Activation script for IOR-Darshan conda environment

# Load conda if it's a module (common on HPC systems)
if command -v module &> /dev/null; then
    module load conda 2>/dev/null || true
fi

# Activate conda environment
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate ior-darshan

# Set up compilers
export CC=$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-gcc
export CXX=$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-g++
export FC=$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-gfortran
export MPICC=$CONDA_PREFIX/bin/mpicc
export MPICXX=$CONDA_PREFIX/bin/mpicxx

# Set up paths
export PATH="$CONDA_PREFIX/bin:$PATH"
export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$CONDA_PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"

# HDF5 settings
export HDF5_ROOT=$CONDA_PREFIX
export HDF5_DIR=$CONDA_PREFIX

echo "IOR-Darshan conda environment activated"
echo "Conda prefix: $CONDA_PREFIX"
echo "MPI compiler: $(which mpicc)"
echo "HDF5 location: $HDF5_ROOT"
