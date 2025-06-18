#!/bin/bash

# Conda-based Test Suite for IOR-Darshan Repository
# This script runs comprehensive tests using conda environment

set -e

echo "=== Running IOR-Darshan Repository Test Suite (Conda Version) ==="

# Check if conda environment is activated
if [[ -z "$CONDA_PREFIX" ]]; then
    echo "Error: Conda environment not activated. Please run:"
    echo "source ./activate_ior_env.sh"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$REPO_DIR/logs"

# Create test log directory
mkdir -p "$LOG_DIR/tests"

# Test 1: Check conda environment
echo "Test 1: Checking conda environment..."
echo "✓ Conda environment: $CONDA_DEFAULT_ENV"
echo "✓ Conda prefix: $CONDA_PREFIX"

# Test 2: Check if compilers are available
echo "Test 2: Checking compilers..."
if command -v mpicc >/dev/null 2>&1; then
    echo "✓ MPI compiler found: $(which mpicc)"
else
    echo "✗ MPI compiler not found"
    exit 1
fi

if command -v h5dump >/dev/null 2>&1; then
    echo "✓ HDF5 tools found: $(which h5dump)"
else
    echo "✗ HDF5 tools not found"
    exit 1
fi

# Test 3: Check if IOR is installed
echo "Test 3: Checking IOR installation..."
if [ -f "$CONDA_PREFIX/bin/ior" ]; then
    echo "✓ IOR found at $CONDA_PREFIX/bin/ior"
    "$CONDA_PREFIX/bin/ior" --help >/dev/null 2>&1 && echo "✓ IOR runs successfully"
else
    echo "✗ IOR not found. Run ./scripts/install_ior_conda.sh first"
    exit 1
fi

# Test 4: Check if Darshan is installed
echo "Test 4: Checking Darshan installation..."
if [ -f "$CONDA_PREFIX/lib/libdarshan.so" ]; then
    echo "✓ Darshan runtime library found"
else
    echo "✗ Darshan runtime library not found. Run ./scripts/install_darshan_conda.sh first"
    exit 1
fi

if [ -f "$CONDA_PREFIX/bin/darshan-parser" ]; then
    echo "✓ Darshan utilities found"
    "$CONDA_PREFIX/bin/darshan-parser" --help >/dev/null 2>&1 && echo "✓ Darshan parser runs successfully"
else
    echo "✗ Darshan utilities not found"
    exit 1
fi

# Test 5: Run a small POSIX benchmark
echo "Test 5: Running small POSIX benchmark test..."
export BLOCK_SIZE="1m"
export TRANSFER_SIZE="64k"
export NUM_TASKS="2"
export ITERATIONS="1"
export TEST_FILE="$LOG_DIR/tests/test_posix_file"

if timeout 60 "$SCRIPT_DIR/run_posix_benchmark.sh" >/dev/null 2>&1; then
    echo "✓ POSIX benchmark test completed successfully"
else
    echo "✗ POSIX benchmark test failed"
    exit 1
fi

# Test 6: Run a small HDF5 benchmark
echo "Test 6: Running small HDF5 benchmark test..."
export BLOCK_SIZE="1m"
export TRANSFER_SIZE="64k"
export NUM_TASKS="2"
export ITERATIONS="1"
export TEST_FILE="$LOG_DIR/tests/test_hdf5_file.h5"

if timeout 60 "$SCRIPT_DIR/run_hdf5_benchmark.sh" >/dev/null 2>&1; then
    echo "✓ HDF5 benchmark test completed successfully"
else
    echo "✗ HDF5 benchmark test failed"
    exit 1
fi

# Test 7: Check if Darshan logs were generated
echo "Test 7: Checking Darshan log generation..."
RECENT_LOGS=$(find "$LOG_DIR" -name "*.darshan" -mmin -10 | wc -l)
if [ "$RECENT_LOGS" -gt 0 ]; then
    echo "✓ Darshan logs generated successfully ($RECENT_LOGS logs found)"
else
    echo "✗ No recent Darshan logs found"
    exit 1
fi

# Test 8: Test counter extraction scripts
echo "Test 8: Testing counter extraction scripts..."
LATEST_LOG=$(find "$LOG_DIR" -name "*.darshan" -mmin -10 | head -1)
if [ -n "$LATEST_LOG" ]; then
    if python3 "$SCRIPT_DIR/extract_posix_counters.py" "$LATEST_LOG" "$LOG_DIR/tests/test_counters.csv" >/dev/null 2>&1; then
        echo "✓ Counter extraction script works"
    else
        echo "✗ Counter extraction script failed"
        exit 1
    fi
else
    echo "✗ No Darshan log available for testing counter extraction"
    exit 1
fi

# Clean up test files
echo "Cleaning up test files..."
rm -f "$LOG_DIR/tests/test_posix_file"*
rm -f "$LOG_DIR/tests/test_hdf5_file"*

echo "=== All tests passed successfully! ==="
echo "The IOR-Darshan repository is properly installed and functional in conda environment."
echo ""
echo "You can now run:"
echo "  source ./activate_ior_env.sh"
echo "  ./scripts/run_posix_benchmark.sh  - for POSIX I/O benchmarks"
echo "  ./scripts/run_hdf5_benchmark.sh   - for HDF5 I/O benchmarks"

