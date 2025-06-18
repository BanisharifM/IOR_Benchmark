#!/bin/bash

# Simple Conda Environment Setup with Pip Dependencies
# Creates a basic conda environment and installs dependencies via pip

set -e

echo "=== Creating Simple Conda Environment for IOR-Darshan ==="

# Configuration
ENV_NAME="ior_env"
PYTHON_VERSION="3.9"

# Install basic system packages via conda (minimal set)
echo "Installing basic system packages via conda..."
conda install -c conda-forge -y \
    gcc_linux-64 \
    gxx_linux-64 \
    gfortran_linux-64 \
    make \
    cmake \
    pkg-config \
    openmpi \
    hdf5 \
    zlib

# Install Python packages via pip
echo "Installing Python packages via pip..."
pip install --upgrade pip
pip install \
    numpy \
    pandas \
    matplotlib \
    seaborn \
    h5py \
    mpi4py \
    jupyter \

conda install -c conda-forge -y \
    scipy \
    pydarshan

# Create simple environment activation script
echo "Creating environment activation script..."
cat > activate_ior_env.sh << 'EOF'
#!/bin/bash
# Simple activation script for IOR-Darshan conda environment

# Load conda if it's a module (common on HPC systems)
if command -v module &> /dev/null; then
    module load conda 2>/dev/null || true
fi

# Activate conda environment
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate ior_env

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

echo "IOR-Darshan conda environment 'ior_env' activated"
echo "Python: $(python --version)"
echo "Conda prefix: $CONDA_PREFIX"
echo "MPI compiler: $(which mpicc)"
EOF

chmod +x activate_ior_env.sh

# Verify installations
echo "Verifying installations..."
echo "Python version: $(python --version)"
echo "Pip version: $(pip --version)"
echo "NumPy version: $(python -c 'import numpy; print(f"NumPy {numpy.__version__}")')"
echo "MPI compiler: $(which mpicc)"
echo "HDF5 tools: $(which h5dump)"

# Test basic functionality
echo "Testing basic functionality..."
python -c "import numpy, pandas, matplotlib, h5py, mpi4py; print('✓ All Python packages imported successfully')"
mpicc --version | head -1
h5dump --version

echo "=== Simple conda environment setup completed successfully ==="
echo ""
echo "Environment created: $ENV_NAME"
echo "To use this environment:"
echo "  conda activate $ENV_NAME"
echo "  # or use the activation script:"
echo "  source ./activate_ior_env.sh"
echo ""
echo "Next steps:"
echo "1. conda activate $ENV_NAME  (or source ./activate_ior_env.sh)"
echo "2. ./scripts/install_ior_simple.sh"
echo "3. ./scripts/install_darshan_simple.sh"

