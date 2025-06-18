#!/bin/bash

# Simple IOR Installation Script
# Downloads and compiles IOR using the simple conda environment

set -e

echo "=== Installing IOR Benchmark Tool (Simple Version) ==="

# Check if conda environment is activated
if [[ "$CONDA_DEFAULT_ENV" != "ior_env" ]]; then
    echo "Error: Please activate the ior_env conda environment first:"
    echo "  conda activate ior_env"
    echo "  # or"
    echo "  source ./activate_ior_env.sh"
    exit 1
fi

echo "Using conda environment: $CONDA_DEFAULT_ENV"
echo "Conda prefix: $CONDA_PREFIX"

# Configuration
IOR_VERSION="4.0.0"
IOR_URL="https://github.com/hpc/ior/releases/download/${IOR_VERSION}/ior-${IOR_VERSION}.tar.gz"
INSTALL_PREFIX="$CONDA_PREFIX"
SRC_DIR="$HOME/software/src"

# Create directories
mkdir -p "$SRC_DIR"

# Set up compilers and environment
export CC=$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-gcc
export CXX=$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-g++
export MPICC=$CONDA_PREFIX/bin/mpicc
export HDF5_ROOT=$CONDA_PREFIX
export PKG_CONFIG_PATH="$CONDA_PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"

echo "Compilers configured:"
echo "  CC: $CC"
echo "  MPICC: $MPICC"
echo "  HDF5_ROOT: $HDF5_ROOT"

# Download IOR
echo "Downloading IOR version $IOR_VERSION..."
cd "$SRC_DIR"
if [ ! -f "ior-${IOR_VERSION}.tar.gz" ]; then
    wget "$IOR_URL"
fi

# Extract
echo "Extracting IOR..."
if [ -d "ior-${IOR_VERSION}" ]; then
    rm -rf "ior-${IOR_VERSION}"
fi
tar -xzf "ior-${IOR_VERSION}.tar.gz"
cd "ior-${IOR_VERSION}"

# Configure with HDF5 support
echo "Configuring IOR with HDF5 support..."
./configure \
    --prefix="$INSTALL_PREFIX" \
    --with-hdf5="$CONDA_PREFIX" \
    --enable-shared \
    CC="$MPICC" \
    CFLAGS="-O3 -g -I$CONDA_PREFIX/include" \
    LDFLAGS="-L$CONDA_PREFIX/lib" \
    CPPFLAGS="-I$CONDA_PREFIX/include"

# Compile
echo "Compiling IOR..."
make -j$(nproc)

# Install
echo "Installing IOR..."
make install

# Verify installation
echo "Verifying IOR installation..."
if [ -f "$INSTALL_PREFIX/bin/ior" ]; then
    echo "✓ IOR installed successfully at: $INSTALL_PREFIX/bin/ior"
    "$INSTALL_PREFIX/bin/ior" --help | head -10
else
    echo "✗ IOR installation failed"
    exit 1
fi

echo "=== IOR installation completed successfully ==="
echo "IOR binary: $INSTALL_PREFIX/bin/ior"
echo ""
echo "To use IOR:"
echo "  conda activate ior_env"
echo "  ior --help"

