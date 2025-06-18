# IOR-Darshan Integration Repository

This repository provides a complete setup for running IOR (Interleaved Or Random) benchmarks with Darshan I/O profiling to capture detailed I/O performance metrics.

## Quick Start

### For HPC Systems (Simple Conda + Pip Approach)
```bash
# 1. Create simple conda environment
conda create -n ior_env python=3.9 -y
conda activate ior_env

# 2. Set up environment and install tools
./scripts/setup_conda_env.sh
./scripts/install_ior_simple.sh
./scripts/install_darshan_simple.sh

# 3. Create configurations and test
./scripts/create_configs.sh
./scripts/test_simple_setup.sh
```

### For Systems with Sudo Access
```bash
# 1. Install system dependencies
./scripts/install_dependencies.sh

# 2. Install IOR and Darshan
./scripts/install_ior.sh
./scripts/install_darshan.sh

# 3. Create configurations and test
./scripts/create_configs.sh
./scripts/run_tests.sh
```

## Features

### IOR Benchmark Support
- POSIX I/O interface
- HDF5 I/O interface
- Configurable block sizes, transfer sizes, and access patterns
- Support for multiple processes and nodes

### Darshan Integration
- Comprehensive I/O profiling with minimal overhead
- POSIX I/O counters including reads, writes, seeks, and stats
- Access pattern analysis (sequential, random, strided)
- Size distribution tracking
- Alignment analysis
- Lustre filesystem-specific metrics

### Collected I/O Counters
The system captures all counters shown in your CSV data:
- Process counts and file operations
- Lustre stripe configuration
- POSIX I/O operations and byte counts
- Access patterns and size distributions
- Memory and file alignment metrics
- Stride and access pattern analysis

## Requirements

- Linux system (Ubuntu 18.04+ recommended)
- MPI implementation (OpenMPI or MPICH)
- HDF5 library (for HDF5 benchmarks)
- GCC compiler with development tools
- Python 3.6+ (for analysis scripts)

## Installation

See `docs/INSTALLATION.md` for detailed installation instructions.

## Usage

See `docs/USAGE.md` for detailed usage examples and configuration options.

## Testing

Run the test suite to verify installation:
```bash
./scripts/run_tests.sh
```

## Contributing

Please read `docs/CONTRIBUTING.md` for guidelines on contributing to this project.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- IOR benchmark: https://github.com/hpc/ior
- Darshan I/O profiler: https://github.com/darshan-hpc/darshan
- Argonne National Laboratory for Darshan development
- HPC community for IOR development

