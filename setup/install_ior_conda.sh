#!/bin/bash

# IOR Installation Script for Conda Environment
# Downloads, compiles, and installs IOR benchmark tool using conda dependencies

set -e

echo "=== Installing IOR Benchmark Tool (Conda Version) ==="

# Check if conda environment is activated
if [[ -z "$CONDA_PREFIX" ]]; then
    echo "Error: Conda environment not activated. Please run:"
    echo "source ./activate_ior_env.sh"
    exit 1
fi

echo "Using conda environment: $CONDA_PREFIX"

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

# Configure with HDF5 support using conda dependencies
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
"$INSTALL_PREFIX/bin/ior" --help | head -10

echo "=== IOR installation completed successfully ==="
echo "IOR installed to: $INSTALL_PREFIX/bin/ior"
echo "To use IOR, make sure the conda environment is activated:"
echo "source ./activate_ior_env.sh"

