#!/bin/bash

# Simple Darshan Installation Script
# Downloads and compiles Darshan using the simple conda environment

set -e

echo "=== Installing Darshan I/O Profiling Tool (Simple Version) ==="

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
DARSHAN_VERSION="3.4.4"
DARSHAN_URL="https://github.com/darshan-hpc/darshan/archive/refs/tags/darshan-${DARSHAN_VERSION}.tar.gz"
INSTALL_PREFIX="$CONDA_PREFIX"
SRC_DIR="$HOME/software/src"

# Create directories
mkdir -p "$SRC_DIR"
mkdir -p "$HOME/ior-darshan-repo/logs"

# Set up compilers and environment
export CC=$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-gcc
export CXX=$CONDA_PREFIX/bin/x86_64-conda-linux-gnu-g++
export MPICC=$CONDA_PREFIX/bin/mpicc
export PKG_CONFIG_PATH="$CONDA_PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"

echo "Compilers configured:"
echo "  CC: $CC"
echo "  MPICC: $MPICC"

# Download Darshan
echo "Downloading Darshan version $DARSHAN_VERSION..."
cd "$SRC_DIR"
if [ ! -f "darshan-${DARSHAN_VERSION}.tar.gz" ]; then
    wget "$DARSHAN_URL" -O "darshan-${DARSHAN_VERSION}.tar.gz"
fi

# Extract
echo "Extracting Darshan..."
if [ -d "darshan-darshan-${DARSHAN_VERSION}" ]; then
    rm -rf "darshan-darshan-${DARSHAN_VERSION}"
fi
tar -xzf "darshan-${DARSHAN_VERSION}.tar.gz"
cd "darshan-darshan-${DARSHAN_VERSION}"
./prepare.sh

# Install Darshan Runtime
echo "Installing Darshan Runtime..."
cd darshan-runtime
./configure \
    --prefix="$INSTALL_PREFIX" \
    --with-jobid-env=NONE \
    --with-mem-align=8 \
    --with-log-path="$HOME/ior-darshan-repo/logs" \
    --enable-mmap-logs \
    --enable-shared \
    CC="$MPICC" \
    CFLAGS="-O3 -g -I$CONDA_PREFIX/include" \
    LDFLAGS="-L$CONDA_PREFIX/lib"

make -j$(nproc)
make install

# Install Darshan Utilities
echo "Installing Darshan Utilities..."
cd ../darshan-util
./configure \
    --prefix="$INSTALL_PREFIX" \
    --enable-shared \
    CC="$CC" \
    CFLAGS="-O3 -g -I$CONDA_PREFIX/include" \
    LDFLAGS="-L$CONDA_PREFIX/lib"

make -j$(nproc)
make install

# Create Darshan configuration
echo "Creating Darshan configuration..."
mkdir -p "$HOME/ior-darshan-repo/configs"
cat > "$HOME/ior-darshan-repo/configs/darshan.conf" << 'EOF'
# Darshan Configuration for Simple Conda Environment

# Memory allocation for records (16MB)
DARSHAN_MEMORY_ALLOCATION=16777216

# Enable modules
DARSHAN_ENABLE_MODULES=POSIX,MPI-IO,HDF5,STDIO

# Maximum records per module
DARSHAN_MAX_RECORDS=8192

# Log file path
DARSHAN_LOG_PATH=$HOME/ior-darshan-repo/logs
EOF

# Update activation script to include Darshan
echo "Updating activation script with Darshan settings..."
cat >> activate_ior_env.sh << 'EOF'

# Darshan environment setup
export LD_PRELOAD="$CONDA_PREFIX/lib/libdarshan.so"
export DARSHAN_ENABLE_NONMPI=1
export DARSHAN_CONFIG_PATH="$HOME/ior-darshan-repo/configs/darshan.conf"
export DARSHAN_LOG_PATH="$HOME/ior-darshan-repo/logs"

echo "Darshan profiling enabled"
echo "Darshan library: $CONDA_PREFIX/lib/libdarshan.so"
EOF

# Verify installation
echo "Verifying Darshan installation..."
if [ -f "$INSTALL_PREFIX/lib/libdarshan.so" ]; then
    echo "✓ Darshan runtime library installed: $INSTALL_PREFIX/lib/libdarshan.so"
else
    echo "✗ Darshan runtime library not found"
    exit 1
fi

if [ -f "$INSTALL_PREFIX/bin/darshan-parser" ]; then
    echo "✓ Darshan utilities installed: $INSTALL_PREFIX/bin/darshan-parser"
    "$INSTALL_PREFIX/bin/darshan-parser" --help | head -5
else
    echo "✗ Darshan utilities not found"
    exit 1
fi

echo "=== Darshan installation completed successfully ==="
echo "Runtime library: $INSTALL_PREFIX/lib/libdarshan.so"
echo "Utilities: $INSTALL_PREFIX/bin/"
echo "Log directory: $HOME/ior-darshan-repo/logs"
echo ""
echo "To use Darshan:"
echo "  conda activate ior_env"
echo "  # Darshan will automatically profile your applications"

