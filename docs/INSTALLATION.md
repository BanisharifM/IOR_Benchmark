# Installation Guide

## Prerequisites

Before installing the IOR-Darshan repository, ensure your system meets the following requirements:

- Linux operating system (Ubuntu 18.04+ recommended)
- Sudo privileges for package installation
- At least 2GB of free disk space
- Internet connectivity for downloading packages and source code

## Quick Installation

For a complete installation, run the following commands in order:

```bash
# 1. Install system dependencies
./scripts/install_dependencies.sh

# 2. Install IOR benchmark tool
./scripts/install_ior.sh

# 3. Install Darshan I/O profiler
./scripts/install_darshan.sh

# 4. Create benchmark configurations
./scripts/create_configs.sh

# 5. Run tests to verify installation
./scripts/run_tests.sh
```

## Detailed Installation Steps

### Step 1: System Dependencies

The dependency installation script installs:
- Build tools (gcc, make, autotools)
- MPI implementation (OpenMPI)
- HDF5 libraries
- Python packages for analysis

```bash
./scripts/install_dependencies.sh
```

### Step 2: IOR Installation

Downloads and compiles IOR version 4.0.0 with HDF5 support:

```bash
./scripts/install_ior.sh
```

Installation location: `$HOME/software/ior`

### Step 3: Darshan Installation

Downloads and compiles Darshan version 3.4.7:

```bash
./scripts/install_darshan.sh
```

Installation location: `$HOME/software/darshan`

### Step 4: Configuration Setup

Creates 15 pre-defined benchmark configurations:

```bash
./scripts/create_configs.sh
```

### Step 5: Verification

Runs comprehensive tests to verify the installation:

```bash
./scripts/run_tests.sh
```

## Troubleshooting

### Common Issues

**MPI not found**: Ensure OpenMPI is properly installed and in your PATH.

**HDF5 compilation errors**: Install HDF5 development packages:
```bash
sudo apt-get install libhdf5-dev libhdf5-openmpi-dev
```

**Permission errors**: Ensure you have write permissions to `$HOME/software/`

**Darshan logs not generated**: Check that LD_PRELOAD is set correctly and log directory exists.

### Manual Installation

If automatic installation fails, you can install components manually:

1. Download IOR from https://github.com/hpc/ior/releases
2. Download Darshan from https://github.com/darshan-hpc/darshan
3. Follow the compilation instructions in each project's documentation

## Environment Setup

After installation, you may need to update your environment:

```bash
# Add to ~/.bashrc
export PATH="$HOME/software/ior/bin:$HOME/software/darshan/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/software/darshan/lib:$LD_LIBRARY_PATH"
```

## Next Steps

After successful installation:
1. Review available configurations in `configs/`
2. Run your first benchmark with `./scripts/run_posix_benchmark.sh`
3. Explore the analysis tools in `scripts/`

