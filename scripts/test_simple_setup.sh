#!/bin/bash

# Simple Test Suite for IOR-Darshan Repository
# Tests the simple conda environment setup

set -e

echo "=== Running Simple IOR-Darshan Test Suite ==="

# Check if conda environment is activated
if [[ "$CONDA_DEFAULT_ENV" != "ior_env" ]]; then
    echo "Error: Please activate the ior_env conda environment first:"
    echo "  conda activate ior_env"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$REPO_DIR/logs"

# Create test log directory
mkdir -p "$LOG_DIR/tests"

echo "Using conda environment: $CONDA_DEFAULT_ENV"
echo "Conda prefix: $CONDA_PREFIX"

# Test 1: Check Python packages
echo "Test 1: Checking Python packages..."
python -c "
import sys
packages = ['numpy', 'pandas', 'matplotlib', 'h5py', 'mpi4py']
for pkg in packages:
    try:
        __import__(pkg)
        print(f'✓ {pkg} imported successfully')
    except ImportError:
        print(f'✗ {pkg} import failed')
        sys.exit(1)
"

# Test 2: Check compilers
echo "Test 2: Checking compilers..."
if command -v mpicc >/dev/null 2>&1; then
    echo "✓ MPI compiler found: $(which mpicc)"
    mpicc --version | head -1
else
    echo "✗ MPI compiler not found"
    exit 1
fi

# Test 3: Check HDF5
echo "Test 3: Checking HDF5..."
if command -v h5dump >/dev/null 2>&1; then
    echo "✓ HDF5 tools found: $(which h5dump)"
    h5dump --version
else
    echo "✗ HDF5 tools not found"
    exit 1
fi

# Test 4: Check IOR installation
echo "Test 4: Checking IOR installation..."
if [ -f "$CONDA_PREFIX/bin/ior" ]; then
    echo "✓ IOR found at $CONDA_PREFIX/bin/ior"
    if "$CONDA_PREFIX/bin/ior" --help >/dev/null 2>&1; then
        echo "✓ IOR runs successfully"
    else
        echo "✗ IOR execution failed"
        exit 1
    fi
else
    echo "✗ IOR not found. Run ./scripts/install_ior_simple.sh first"
    exit 1
fi

# Test 5: Check Darshan installation
echo "Test 5: Checking Darshan installation..."
if [ -f "$CONDA_PREFIX/lib/libdarshan.so" ]; then
    echo "✓ Darshan runtime library found"
else
    echo "✗ Darshan runtime library not found. Run ./scripts/install_darshan_simple.sh first"
    exit 1
fi

if [ -f "$CONDA_PREFIX/bin/darshan-parser" ]; then
    echo "✓ Darshan utilities found"
    if "$CONDA_PREFIX/bin/darshan-parser" --help >/dev/null 2>&1; then
        echo "✓ Darshan parser runs successfully"
    else
        echo "✗ Darshan parser execution failed"
        exit 1
    fi
else
    echo "✗ Darshan utilities not found"
    exit 1
fi

# Test 6: Run a small POSIX benchmark
echo "Test 6: Running small POSIX benchmark test..."
export BLOCK_SIZE="1m"
export TRANSFER_SIZE="64k"
export NUM_TASKS="2"
export ITERATIONS="1"
export TEST_FILE="$LOG_DIR/tests/test_posix_file"

# Temporarily disable Darshan for this test to avoid issues
unset LD_PRELOAD

if timeout 60 mpirun -np 2 "$CONDA_PREFIX/bin/ior" \
    -a POSIX \
    -b "$BLOCK_SIZE" \
    -t "$TRANSFER_SIZE" \
    -i "$ITERATIONS" \
    -o "$TEST_FILE" \
    -w -r >/dev/null 2>&1; then
    echo "✓ POSIX benchmark test completed successfully"
    rm -f "$TEST_FILE"*
else
    echo "✗ POSIX benchmark test failed"
    exit 1
fi

# Test 7: Run a small HDF5 benchmark
echo "Test 7: Running small HDF5 benchmark test..."
export TEST_FILE="$LOG_DIR/tests/test_hdf5_file.h5"

if timeout 60 mpirun -np 2 "$CONDA_PREFIX/bin/ior" \
    -a HDF5 \
    -b "$BLOCK_SIZE" \
    -t "$TRANSFER_SIZE" \
    -i "$ITERATIONS" \
    -o "$TEST_FILE" \
    -w -r >/dev/null 2>&1; then
    echo "✓ HDF5 benchmark test completed successfully"
    rm -f "$TEST_FILE"*
else
    echo "✗ HDF5 benchmark test failed"
    exit 1
fi

# Test 8: Test Darshan profiling
echo "Test 8: Testing Darshan profiling..."
export LD_PRELOAD="$CONDA_PREFIX/lib/libdarshan.so"
export DARSHAN_LOG_PATH="$LOG_DIR/tests"

if timeout 30 mpirun -np 1 "$CONDA_PREFIX/bin/ior" \
    -a POSIX \
    -b "1m" \
    -t "64k" \
    -i 1 \
    -o "$LOG_DIR/tests/darshan_test_file" \
    -w >/dev/null 2>&1; then
    
    # Check if Darshan log was created
    sleep 2
    DARSHAN_LOGS=$(find "$LOG_DIR/tests" -name "*.darshan" -mmin -2 | wc -l)
    if [ "$DARSHAN_LOGS" -gt 0 ]; then
        echo "✓ Darshan profiling test completed successfully"
        rm -f "$LOG_DIR/tests/darshan_test_file"*
    else
        echo "✗ Darshan log not generated"
        exit 1
    fi
else
    echo "✗ Darshan profiling test failed"
    exit 1
fi

echo "=== All tests passed successfully! ==="
echo "The simple IOR-Darshan setup is working correctly."
echo ""
echo "You can now run:"
echo "  conda activate ior_env"
echo "  ./scripts/run_posix_benchmark.sh"
echo "  ./scripts/run_hdf5_benchmark.sh"

