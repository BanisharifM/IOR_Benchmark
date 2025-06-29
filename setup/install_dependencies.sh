#!/bin/bash

# IOR-Darshan Repository - Dependency Installation Script
# This script installs all required dependencies for IOR and Darshan

set -e

echo "=== Installing Dependencies for IOR-Darshan Repository ==="

# Update package lists
echo "Updating package lists..."
sudo apt-get update

# Install essential build tools
echo "Installing build tools..."
sudo apt-get install -y \
    build-essential \
    autoconf \
    automake \
    libtool \
    pkg-config \
    git \
    wget \
    curl \
    cmake \
    zlib1g-dev

# Install MPI
echo "Installing MPI..."
sudo apt-get install -y \
    openmpi-bin \
    openmpi-common \
    libopenmpi-dev \
    mpi-default-bin \
    mpi-default-dev

# Install HDF5
echo "Installing HDF5..."
sudo apt-get install -y \
    libhdf5-dev \
    libhdf5-openmpi-dev \
    hdf5-tools

# Install Python and analysis tools
echo "Installing Python and analysis tools..."
sudo apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    python3-numpy \
    python3-matplotlib \
    python3-pandas

# Install additional Python packages for Darshan analysis
echo "Installing Python packages for Darshan analysis..."
pip3 install --user \
    pydarshan \
    seaborn \
    jupyter

# Install additional libraries that might be needed
echo "Installing additional libraries..."
sudo apt-get install -y \
    libbz2-dev \
    libssl-dev \
    libffi-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev

# Verify MPI installation
echo "Verifying MPI installation..."
mpicc --version
mpirun --version

# Verify HDF5 installation
echo "Verifying HDF5 installation..."
h5dump --version

# Create directories for installations
echo "Creating installation directories..."
mkdir -p $HOME/software/{ior,darshan}
mkdir -p $HOME/software/src

echo "=== Dependency installation completed successfully ==="
echo "Next steps:"
echo "1. Run ./scripts/install_ior.sh to install IOR"
echo "2. Run ./scripts/install_darshan.sh to install Darshan"

