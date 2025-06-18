# Usage Guide

## Quick Start

### Running a Single Benchmark

To run a POSIX benchmark with default settings:
```bash
./scripts/run_posix_benchmark.sh
```

To run an HDF5 benchmark with default settings:
```bash
./scripts/run_hdf5_benchmark.sh
```

### Using Different Configurations

Load a specific configuration and run a benchmark:
```bash
# Load medium scale configuration
source configs/medium_scale.conf

# Run POSIX benchmark with this configuration
./scripts/run_posix_benchmark.sh
```

### Running Multiple Configurations

Run a benchmark suite with multiple configurations:
```bash
# Run both POSIX and HDF5 benchmarks with small_test and medium_scale configs
./scripts/run_benchmark_suite.sh both small_test,medium_scale
```

## Available Configurations

The repository includes 15 pre-defined configurations:

| Configuration | Description | Block Size | Transfer Size | Processes |
|---------------|-------------|------------|---------------|-----------|
| small_test | Quick validation | 1m | 64k | 2 |
| medium_scale | Typical workloads | 100m | 1m | 4 |
| large_scale | Performance testing | 1g | 4m | 8 |
| high_concurrency | Many processes | 500m | 1m | 16 |
| small_io | Small I/O operations | 10m | 4k | 4 |
| large_io | Large I/O operations | 2g | 16m | 4 |
| sequential | Sequential access | 500m | 2m | 4 |
| random | Random access | 500m | 1m | 4 |
| write_only | Write operations only | 1g | 2m | 4 |
| read_only | Read operations only | 1g | 2m | 4 |
| mixed_rw | Mixed read/write | 1g | 2m | 4 |
| hdf5_optimized | HDF5 specific settings | 1g | 2m | 4 |
| posix_optimized | POSIX specific settings | 1g | 2m | 4 |
| stress_test | Intensive I/O | 2g | 8m | 8 |
| micro_benchmark | Detailed analysis | 10m | 1k | 2 |

## Custom Configurations

### Creating Custom Configurations

Create a new configuration file in the `configs/` directory:

```bash
# configs/my_custom.conf
export BLOCK_SIZE="500m"
export TRANSFER_SIZE="2m"
export NUM_TASKS="6"
export ITERATIONS="5"
export SEGMENT_COUNT="2"
```

### Environment Variables

You can override any configuration parameter using environment variables:

```bash
export BLOCK_SIZE="2g"
export TRANSFER_SIZE="8m"
export NUM_TASKS="12"
./scripts/run_posix_benchmark.sh
```

### Available Parameters

| Parameter | Description | Default | Example Values |
|-----------|-------------|---------|----------------|
| BLOCK_SIZE | Block size per task | 1g | 1m, 100m, 1g, 2g |
| TRANSFER_SIZE | Transfer size | 1m | 4k, 64k, 1m, 4m |
| NUM_TASKS | Number of MPI tasks | 4 | 1, 2, 4, 8, 16 |
| ITERATIONS | Number of iterations | 3 | 1, 3, 5, 10 |
| SEGMENT_COUNT | Number of segments | 1 | 1, 2, 4 |
| TEST_FILE | Output file path | auto | /path/to/testfile |

### HDF5-Specific Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| COLLECTIVE_METADATA | Enable collective metadata | 1 |
| CHUNK_SIZE | HDF5 chunk size | 1048576 |
| HDF5_ALIGNMENT | File alignment | 1m |

## Analyzing Results

### Automatic Analysis

Results are automatically analyzed after each benchmark run. Look for:
- IOR output files (`.out`)
- Darshan log files (`.darshan`)
- Extracted counter files (`.csv`)
- Analysis summaries (`.txt`)

### Manual Analysis

Analyze a specific Darshan log file:
```bash
# Extract POSIX counters
python3 scripts/extract_posix_counters.py logs/my_log.darshan output.csv

# Extract HDF5 counters
python3 scripts/extract_hdf5_counters.py logs/my_log.darshan output.csv

# Analyze CSV data
python3 scripts/analyze_csv_data.py output.csv
```

### Benchmark Suite Analysis

After running a benchmark suite, analyze all results:
```bash
python3 scripts/analyze_benchmark_results.py logs/benchmark_suite_20231217_143022/
```

## Advanced Usage

### Running with Specific MPI Settings

```bash
# Use specific MPI settings
export OMPI_MCA_btl="tcp,self"
./scripts/run_posix_benchmark.sh
```

### Custom Darshan Configuration

Modify the Darshan configuration file:
```bash
# Edit configs/darshan.conf
DARSHAN_MEMORY_ALLOCATION=33554432  # 32MB
DARSHAN_MAX_RECORDS=16384
```

### Debugging

Enable verbose output:
```bash
export DARSHAN_VERBOSE=1
export IOR_VERBOSE=1
./scripts/run_posix_benchmark.sh
```

## Best Practices

### Performance Testing

1. **Warm-up runs**: Run a small test first to warm up the system
2. **Multiple iterations**: Use at least 3 iterations for reliable results
3. **Consistent environment**: Ensure consistent system load during testing
4. **Appropriate scale**: Match benchmark scale to your system capabilities

### Data Collection

1. **Sufficient memory**: Ensure adequate memory for Darshan records
2. **Log storage**: Ensure sufficient disk space for log files
3. **Backup results**: Copy important results to permanent storage
4. **Document configuration**: Keep records of benchmark configurations used

### Troubleshooting

1. **Check logs**: Always check IOR output and Darshan logs for errors
2. **Verify installation**: Run the test suite if you encounter issues
3. **Resource limits**: Ensure adequate system resources for your benchmark scale
4. **File system**: Verify write permissions and available space

## Integration with Batch Systems

### SLURM Example

```bash
#!/bin/bash
#SBATCH --job-name=ior-benchmark
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=4
#SBATCH --time=01:00:00

# Load configuration
source configs/large_scale.conf

# Run benchmark
./scripts/run_posix_benchmark.sh
```

### PBS Example

```bash
#!/bin/bash
#PBS -N ior-benchmark
#PBS -l nodes=2:ppn=4
#PBS -l walltime=01:00:00

cd $PBS_O_WORKDIR
source configs/medium_scale.conf
./scripts/run_hdf5_benchmark.sh
```

## Output Files

### Generated Files

Each benchmark run generates several output files:

- `ior_<type>_<timestamp>.out`: IOR benchmark output
- `<timestamp>.darshan`: Darshan I/O profiling log
- `darshan_<type>_<timestamp>.txt`: Parsed Darshan log
- `<type>_counters_<timestamp>.csv`: Extracted I/O counters
- Configuration files used for the run

### File Locations

All output files are stored in the `logs/` directory with timestamps for easy identification and organization.

