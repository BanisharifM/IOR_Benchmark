#!/bin/bash

# IOR Installation Script
# Downloads, compiles, and installs IOR benchmark tool

set -e

echo "=== Installing IOR Benchmark Tool ==="

# Configuration
IOR_VERSION="4.0.0"
IOR_URL="https://github.com/hpc/ior/releases/download/${IOR_VERSION}/ior-${IOR_VERSION}.tar.gz"
INSTALL_PREFIX="$HOME/software/ior"
SRC_DIR="$HOME/software/src"

# Create directories
mkdir -p "$SRC_DIR" "$INSTALL_PREFIX"

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
    --with-hdf5 \
    --enable-shared \
    CC=mpicc \
    CFLAGS="-O3 -g" \
    LDFLAGS="-L/usr/lib/x86_64-linux-gnu/hdf5/openmpi"

# Compile
echo "Compiling IOR..."
make -j$(nproc)

# Install
echo "Installing IOR..."
make install

# Verify installation
echo "Verifying IOR installation..."
"$INSTALL_PREFIX/bin/ior" --help | head -10

# Add to PATH in bashrc if not already there
if ! grep -q "$INSTALL_PREFIX/bin" ~/.bashrc; then
    echo "Adding IOR to PATH..."
    echo "export PATH=\"$INSTALL_PREFIX/bin:\$PATH\"" >> ~/.bashrc
fi

echo "=== IOR installation completed successfully ==="
echo "IOR installed to: $INSTALL_PREFIX"
echo "Binary location: $INSTALL_PREFIX/bin/ior"
echo "To use IOR immediately, run: export PATH=\"$INSTALL_PREFIX/bin:\$PATH\""
echo "Or restart your shell to pick up the PATH changes."

