#!/bin/bash

# Darshan Installation Script
# Downloads, compiles, and installs Darshan I/O profiling tool

set -e

echo "=== Installing Darshan I/O Profiling Tool ==="

# Configuration
DARSHAN_VERSION="3.4.7"
DARSHAN_URL="https://github.com/darshan-hpc/darshan/archive/refs/tags/darshan-${DARSHAN_VERSION}.tar.gz"
INSTALL_PREFIX="$HOME/software/darshan"
SRC_DIR="$HOME/software/src"

# Create directories
mkdir -p "$SRC_DIR" "$INSTALL_PREFIX"

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

# Install Darshan Runtime
echo "Installing Darshan Runtime..."
cd darshan-runtime
./prepare.sh
./configure \
    --prefix="$INSTALL_PREFIX" \
    --with-mem-align=8 \
    --with-log-path="$HOME/ior-darshan-repo/logs" \
    --enable-mmap-logs \
    --enable-shared \
    CC=mpicc

make -j$(nproc)
make install

# Install Darshan Utilities
echo "Installing Darshan Utilities..."
cd ../darshan-util
./prepare.sh
./configure \
    --prefix="$INSTALL_PREFIX" \
    --enable-shared

make -j$(nproc)
make install

# Create Darshan configuration file
echo "Creating Darshan configuration file..."
mkdir -p "$HOME/ior-darshan-repo/configs"
cat > "$HOME/ior-darshan-repo/configs/darshan.conf" << 'EOF'
# Darshan Configuration File
# This file configures Darshan runtime behavior

# Increase memory allocation for records (default is 2MB)
DARSHAN_MEMORY_ALLOCATION=16777216

# Enable specific modules
DARSHAN_ENABLE_MODULES=POSIX,MPI-IO,HDF5,STDIO

# Set maximum number of records per module
DARSHAN_MAX_RECORDS=8192

# Enable detailed tracing (optional, increases overhead)
# DARSHAN_ENABLE_DXT=1

# Log file naming pattern
DARSHAN_LOG_PATH=$HOME/ior-darshan-repo/logs
EOF

# Create environment setup script
echo "Creating environment setup script..."
cat > "$INSTALL_PREFIX/setup_darshan_env.sh" << EOF
#!/bin/bash
# Darshan Environment Setup Script

export DARSHAN_PREFIX="$INSTALL_PREFIX"
export PATH="\$DARSHAN_PREFIX/bin:\$PATH"
export LD_LIBRARY_PATH="\$DARSHAN_PREFIX/lib:\$LD_LIBRARY_PATH"

# For runtime instrumentation
export LD_PRELOAD="\$DARSHAN_PREFIX/lib/libdarshan.so"

# Enable non-MPI mode if needed
export DARSHAN_ENABLE_NONMPI=1

# Configuration file
export DARSHAN_CONFIG_PATH="$HOME/ior-darshan-repo/configs/darshan.conf"

echo "Darshan environment configured"
echo "Darshan prefix: \$DARSHAN_PREFIX"
echo "LD_PRELOAD: \$LD_PRELOAD"
EOF

chmod +x "$INSTALL_PREFIX/setup_darshan_env.sh"

# Verify installation
echo "Verifying Darshan installation..."
"$INSTALL_PREFIX/bin/darshan-parser" --help | head -5

echo "=== Darshan installation completed successfully ==="
echo "Darshan installed to: $INSTALL_PREFIX"
echo "Runtime library: $INSTALL_PREFIX/lib/libdarshan.so"
echo "Utilities: $INSTALL_PREFIX/bin/"
echo ""
echo "To use Darshan, source the environment setup:"
echo "source $INSTALL_PREFIX/setup_darshan_env.sh"

