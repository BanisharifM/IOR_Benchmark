# IOR-Darshan Integration Repository

This repository provides a complete setup for running IOR (Interleaved Or Random) benchmarks with Darshan I/O profiling to capture detailed I/O performance metrics.

## Overview

This repository enables you to:
- Install and configure IOR benchmark tool (latest version 4.0.0)
- Install and configure Darshan I/O profiling tool (latest version 3.4.7)
- Execute POSIX and HDF5 I/O workloads with comprehensive logging
- Collect and analyze I/O counters including POSIX operations, Lustre filesystem metrics, and access patterns

## Repository Structure

```
ior-darshan-repo/
├── scripts/           # Installation and execution scripts
├── configs/           # Configuration files for IOR and Darshan
├── examples/          # Example workload configurations
├── docs/              # Documentation and guides
├── tests/             # Test scripts and validation
└── logs/              # Generated log files and results
```

## Quick Start

1. **Install Dependencies and Tools**:
   ```bash
   ./scripts/install_dependencies.sh
   ./scripts/install_ior.sh
   ./scripts/install_darshan.sh
   ```

2. **Run POSIX I/O Benchmark**:
   ```bash
   ./scripts/run_posix_benchmark.sh
   ```

3. **Run HDF5 I/O Benchmark**:
   ```bash
   ./scripts/run_hdf5_benchmark.sh
   ```

4. **Analyze Results**:
   ```bash
   ./scripts/analyze_logs.sh
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

