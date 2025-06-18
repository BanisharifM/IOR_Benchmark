#!/bin/bash

# Conda-based Installation Script for HPC Systems
# This script creates a conda environment and installs all dependencies without sudo

set -e

echo "=== Conda-based Installation for IOR-Darshan Repository ==="
echo "This script will create a conda environment with all required dependencies"

# Configuration
ENV_NAME="ior-darshan"
CONDA_FORGE_CHANNEL="conda-forge"

# Check if conda is available
if ! command -v conda &> /dev/null; then
    echo "Error: conda is not available. Please load conda module or install miniconda first."
    echo "On HPC systems, try: module load conda"
    exit 1
fi

echo "Found conda at: $(which conda)"

# Create conda environment
echo "Creating conda environment: $ENV_NAME"
if conda env list | grep -q "^$ENV_NAME "; then
    echo "Environment $ENV_NAME already exists. Removing it..."
    conda env remove -n $ENV_NAME -y
fi

conda create -n $ENV_NAME python=3.9 -y

# Activate environment
echo "Activating conda environment..."
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate $ENV_NAME

# Install build tools and compilers
echo "Installing build tools and compilers..."
conda install -c $CONDA_FORGE_CHANNEL -y \
    gcc_linux-64 \
    gxx_linux-64 \
    gfortran_linux-64 \
    make \
    cmake \
    autoconf \
    automake \
    libtool \
    pkg-config \
    git \
    wget \
    curl

# Install MPI
echo "Installing MPI..."
conda install -c $CONDA_FORGE_CHANNEL -y \
    openmpi \
    mpi4py

# Install HDF5 with MPI support
echo "Installing HDF5..."
conda install -c $CONDA_FORGE_CHANNEL -y \
    hdf5 \
    h5py

# Install Python packages for analysis
echo "Installing Python analysis packages..."
conda install -c $CONDA_FORGE_CHANNEL -y \
    numpy \
    pandas \
    matplotlib \
    seaborn \
    jupyter

# Install additional Python packages via pip
echo "Installing additional Python packages..."
pip install pydarshan

# Install development libraries
echo "Installing development libraries..."
conda install -c $CONDA_FORGE_CHANNEL -y \
    zlib \
    bzip2 \
    openssl \
    libffi \
    readline \
    sqlite \
    ncurses

# Set up environment variables
echo "Setting up environment variables..."
export CC=\$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-gcc
export CXX=\$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-g++
export FC=\$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-gfortran
export MPICC=\$CONDA_PREFIX/bin/mpicc
export MPICXX=\$CONDA_PREFIX/bin/mpicxx

# Create environment activation script
echo "Creating environment activation script..."
cat > activate_ior_env.sh << 'EOF'
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
EOF

chmod +x activate_ior_env.sh

# Verify installations
echo "Verifying installations..."
echo "GCC version: $(gcc --version | head -1)"
echo "MPI compiler: $(which mpicc)"
echo "MPI version: $(mpicc --version | head -1)"
echo "HDF5 tools: $(which h5dump)"
echo "Python version: $(python --version)"

# Test MPI
echo "Testing MPI..."
mpicc --version
mpirun --version

# Test HDF5
echo "Testing HDF5..."
h5dump --version

echo "=== Conda-based dependency installation completed successfully ==="
echo ""
echo "To use this environment in the future:"
echo "  source ./activate_ior_env.sh"
echo ""
echo "Next steps:"
echo "1. source ./activate_ior_env.sh"
echo "2. ./scripts/install_ior_conda.sh"
echo "3. ./scripts/install_darshan_conda.sh"

