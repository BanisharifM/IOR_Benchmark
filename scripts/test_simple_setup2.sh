#!/bin/bash

# Simple Test Suite for IOR-Darshan Repository
set -e

echo "=== Running Simple IOR-Darshan Test Suite ==="

# Ensure correct conda env
if [[ "$CONDA_DEFAULT_ENV" != "ior_env" ]]; then
    echo "Error: Please activate the ior_env conda environment first:"
    echo "  conda activate ior_env"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$REPO_DIR/logs"
mkdir -p "$LOG_DIR/tests"

echo "Using conda environment: $CONDA_DEFAULT_ENV"
echo "Conda prefix: $CONDA_PREFIX"

# Test 1: Python packages
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

# Test 2: Compilers
echo "Test 2: Checking compilers..."
if command -v mpicc >/dev/null 2>&1; then
    echo "✓ MPI compiler found: $(which mpicc)"
    mpicc --version | head -1
else
    echo "✗ MPI compiler not found"
    exit 1
fi

# Test 3: HDF5 tools
echo "Test 3: Checking HDF5..."
if command -v h5dump >/dev/null 2>&1; then
    echo "✓ HDF5 tools found: $(which h5dump)"
    h5dump --version
else
    echo "✗ HDF5 tools not found"
    exit 1
fi

# Test 4: IOR
echo "Test 4: Checking IOR installation..."
IOR_BIN="$CONDA_PREFIX/bin/ior"
if [ -f "$IOR_BIN" ]; then
    echo "✓ IOR found at $IOR_BIN"
    STDCPP_PATH=$(find "$CONDA_PREFIX/lib/gcc" -name "libstdc++.so.6" | head -n1)
    export STDCPP_PATH

    if LD_PRELOAD="$STDCPP_PATH" "$IOR_BIN" --help 2>&1 | grep -q "Synopsis"; then
        echo "✓ IOR runs successfully (direct)"
    elif LD_PRELOAD="$STDCPP_PATH" mpirun -np 1 "$IOR_BIN" --help 2>&1 | grep -q "Synopsis"; then
        echo "✓ IOR runs successfully (with mpirun)"
    else
        echo "✗ IOR execution failed"
        exit 1
    fi
else
    echo "✗ IOR not found. Run ./scripts/install_ior_simple.sh first"
    exit 1
fi

# Test 5: Darshan
echo "Test 5: Checking Darshan installation..."
DARSHAN_LIB="$CONDA_PREFIX/lib/libdarshan.so"
if [ -f "$DARSHAN_LIB" ]; then
    echo "✓ Darshan runtime library found"
else
    echo "✗ Darshan runtime library not found. Run ./scripts/install_darshan_simple.sh first"
    exit 1
fi

DARSHAN_PARSER=$(which darshan-parser)
if [ -x "$DARSHAN_PARSER" ]; then
    echo "✓ Darshan utilities found at $DARSHAN_PARSER"
    if "$DARSHAN_PARSER" --help 2>&1 | grep -q "Usage:"; then
        echo "✓ Darshan parser runs successfully"
    else
        echo "✗ Darshan parser execution failed"
        exit 1
    fi
else
    echo "✗ Darshan parser not found"
    exit 1
fi

export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:$LD_LIBRARY_PATH"

# Test 6: POSIX benchmark
echo "Test 6: Running small POSIX benchmark test..."
BLOCK_SIZE="1m"
TRANSFER_SIZE="64k"
ITERATIONS="1"
TEST_FILE="./test_posix_file"

if timeout 60 env LD_PRELOAD="$STDCPP_PATH" mpirun -np 2 "$IOR_BIN" \
  -a POSIX -b "$BLOCK_SIZE" -t "$TRANSFER_SIZE" -i "$ITERATIONS" \
  -o "$TEST_FILE" -w -r -v; then
    echo "✓ POSIX benchmark test completed successfully"
    rm -f "$TEST_FILE"*
else
    echo "✗ POSIX benchmark test failed"
    exit 1
fi

# Test 7: HDF5 benchmark (FIXED)
echo "Test 7: Running small HDF5 benchmark test..."
TEST_FILE="$LOG_DIR/tests/test_hdf5_file.h5"
HDF5_LOG="$LOG_DIR/tests/hdf5_benchmark.log"

if [ ! -f "$STDCPP_PATH" ]; then
    echo "✗ libstdc++.so.6 not found at $STDCPP_PATH"
    exit 1
fi

if timeout 60 bash -c "LD_PRELOAD=$STDCPP_PATH mpirun -np 2 $IOR_BIN \
    -a HDF5 -b $BLOCK_SIZE -t $TRANSFER_SIZE -i $ITERATIONS -o $TEST_FILE \
    -w -r -v -c --hdf5.collectiveMetadata" 2>&1 | tee "$HDF5_LOG"; then
    echo "✓ HDF5 benchmark test completed successfully"
    rm -f "$TEST_FILE"*
else
    echo "✗ HDF5 benchmark test failed (see $HDF5_LOG for details)"
    exit 1
fi

# Test 8: Darshan profiling (FIXED)
echo "Test 8: Testing Darshan profiling..."
DARSHAN_LOG_PATH="$LOG_DIR/tests"
DARSHAN_LOGDIR="$DARSHAN_LOG_PATH"
DARSHAN_JOBID=$RANDOM
export DARSHAN_LOGDIR DARSHAN_ENABLE_NONMPI=1 DARSHAN_JOBID
export LD_PRELOAD="$STDCPP_PATH:$DARSHAN_LIB"

if timeout 30 mpirun -np 2 "$IOR_BIN" \
  -a POSIX -b 1m -t 64k -i 1 \
  -o "$DARSHAN_LOG_PATH/darshan_test_file" -w >/dev/null 2>&1; then
    sleep 2
    DARSHAN_LOGS=$(find "$DARSHAN_LOG_PATH" -name "*.darshan" -mmin -2 | wc -l)
    if [ "$DARSHAN_LOGS" -gt 0 ]; then
        echo "✓ Darshan profiling test completed successfully"
        rm -f "$DARSHAN_LOG_PATH/darshan_test_file"*
    else
        echo "✗ Darshan log not generated"
        ls -l "$DARSHAN_LOG_PATH"
        exit 1
    fi
else
    echo "✗ Darshan profiling test failed"
    echo "DEBUG: LD_PRELOAD=$LD_PRELOAD"
    echo "DEBUG: mpirun: $(which mpirun)"
    echo "DEBUG: Darshan log path: $DARSHAN_LOG_PATH"
    ls -l "$DARSHAN_LOG_PATH"
    exit 1
fi

echo ""
echo "=== All tests passed successfully! ==="
echo "The simple IOR-Darshan setup is working correctly."
