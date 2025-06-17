#!/bin/bash

# Configuration Manager for IOR Benchmarks
# This script provides different benchmark configurations for various testing scenarios

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$REPO_DIR/configs"

echo "=== IOR Benchmark Configuration Manager ==="

# Create configs directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Function to create configuration files
create_config() {
    local config_name="$1"
    local description="$2"
    local block_size="$3"
    local transfer_size="$4"
    local num_tasks="$5"
    local iterations="$6"
    local additional_params="$7"
    
    cat > "$CONFIG_DIR/${config_name}.conf" << EOF
# IOR Benchmark Configuration: $config_name
# Description: $description
# Generated on $(date)

export BLOCK_SIZE="$block_size"
export TRANSFER_SIZE="$transfer_size"
export NUM_TASKS="$num_tasks"
export ITERATIONS="$iterations"
export SEGMENT_COUNT="1"
$additional_params
EOF
    
    echo "Created configuration: $config_name"
}

# Create different benchmark configurations

echo "Creating benchmark configurations..."

# 1. Small Scale Test Configuration
create_config "small_test" \
    "Small scale test for quick validation" \
    "1m" "64k" "2" "1" \
    "export TEST_DURATION=\"short\""

# 2. Medium Scale Configuration
create_config "medium_scale" \
    "Medium scale benchmark for typical workloads" \
    "100m" "1m" "4" "3" \
    "export TEST_DURATION=\"medium\""

# 3. Large Scale Configuration
create_config "large_scale" \
    "Large scale benchmark for performance testing" \
    "1g" "4m" "8" "5" \
    "export TEST_DURATION=\"long\""

# 4. High Concurrency Configuration
create_config "high_concurrency" \
    "High concurrency test with many processes" \
    "500m" "1m" "16" "3" \
    "export TEST_DURATION=\"medium\""

# 5. Small I/O Configuration
create_config "small_io" \
    "Small I/O operations test" \
    "10m" "4k" "4" "3" \
    "export TEST_DURATION=\"medium\""

# 6. Large I/O Configuration
create_config "large_io" \
    "Large I/O operations test" \
    "2g" "16m" "4" "3" \
    "export TEST_DURATION=\"long\""

# 7. Sequential Access Pattern
create_config "sequential" \
    "Sequential access pattern test" \
    "500m" "2m" "4" "3" \
    "export ACCESS_PATTERN=\"sequential\""

# 8. Random Access Pattern
create_config "random" \
    "Random access pattern test" \
    "500m" "1m" "4" "3" \
    "export ACCESS_PATTERN=\"random\""

# 9. Write-Only Configuration
create_config "write_only" \
    "Write-only benchmark" \
    "1g" "2m" "4" "3" \
    "export OPERATION_TYPE=\"write\""

# 10. Read-Only Configuration
create_config "read_only" \
    "Read-only benchmark" \
    "1g" "2m" "4" "3" \
    "export OPERATION_TYPE=\"read\""

# 11. Mixed Read/Write Configuration
create_config "mixed_rw" \
    "Mixed read/write benchmark" \
    "1g" "2m" "4" "3" \
    "export OPERATION_TYPE=\"mixed\""

# 12. HDF5 Specific Configuration
create_config "hdf5_optimized" \
    "HDF5 optimized configuration" \
    "1g" "2m" "4" "3" \
    "export COLLECTIVE_METADATA=\"1\"
export CHUNK_SIZE=\"1048576\"
export HDF5_ALIGNMENT=\"1m\""

# 13. POSIX Specific Configuration
create_config "posix_optimized" \
    "POSIX optimized configuration" \
    "1g" "2m" "4" "3" \
    "export POSIX_DIRECT_IO=\"1\"
export POSIX_SYNC=\"1\""

# 14. Stress Test Configuration
create_config "stress_test" \
    "Stress test with intensive I/O" \
    "2g" "8m" "8" "10" \
    "export TEST_DURATION=\"stress\""

# 15. Micro Benchmark Configuration
create_config "micro_benchmark" \
    "Micro benchmark for detailed analysis" \
    "10m" "1k" "2" "10" \
    "export TEST_DURATION=\"micro\""

echo ""
echo "Available configurations:"
ls -1 "$CONFIG_DIR"/*.conf | sed 's/.*\///' | sed 's/\.conf$//' | sort

echo ""
echo "Usage examples:"
echo "  # Load a configuration and run POSIX benchmark:"
echo "  source configs/medium_scale.conf && ./scripts/run_posix_benchmark.sh"
echo ""
echo "  # Load a configuration and run HDF5 benchmark:"
echo "  source configs/hdf5_optimized.conf && ./scripts/run_hdf5_benchmark.sh"
echo ""
echo "  # Run multiple configurations:"
echo "  ./scripts/run_benchmark_suite.sh"

