#!/bin/bash

# Benchmark Suite Runner
# This script runs multiple benchmark configurations automatically

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$REPO_DIR/configs"
LOG_DIR="$REPO_DIR/logs"

echo "=== IOR Benchmark Suite Runner ==="

# Configuration
BENCHMARK_TYPE="${1:-both}"  # posix, hdf5, or both
SELECTED_CONFIGS="${2:-small_test,medium_scale}"  # comma-separated list

# Parse selected configurations
IFS=',' read -ra CONFIGS <<< "$SELECTED_CONFIGS"

echo "Benchmark type: $BENCHMARK_TYPE"
echo "Selected configurations: ${CONFIGS[*]}"
echo ""

# Create results directory
RESULTS_DIR="$LOG_DIR/benchmark_suite_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULTS_DIR"

# Function to run a single benchmark configuration
run_benchmark_config() {
    local config_name="$1"
    local benchmark_type="$2"
    
    echo "=== Running $config_name with $benchmark_type ==="
    
    # Check if config file exists
    if [ ! -f "$CONFIG_DIR/${config_name}.conf" ]; then
        echo "Error: Configuration file not found: $CONFIG_DIR/${config_name}.conf"
        return 1
    fi
    
    # Source the configuration
    source "$CONFIG_DIR/${config_name}.conf"
    
    # Set unique test file for this configuration
    export TEST_FILE="$RESULTS_DIR/${config_name}_${benchmark_type}_testfile"
    
    # Run the appropriate benchmark
    case "$benchmark_type" in
        "posix")
            if timeout 300 "$SCRIPT_DIR/run_posix_benchmark.sh"; then
                echo "✓ POSIX benchmark completed for $config_name"
            else
                echo "✗ POSIX benchmark failed for $config_name"
                return 1
            fi
            ;;
        "hdf5")
            export TEST_FILE="${TEST_FILE}.h5"
            if timeout 300 "$SCRIPT_DIR/run_hdf5_benchmark.sh"; then
                echo "✓ HDF5 benchmark completed for $config_name"
            else
                echo "✗ HDF5 benchmark failed for $config_name"
                return 1
            fi
            ;;
        *)
            echo "Error: Unknown benchmark type: $benchmark_type"
            return 1
            ;;
    esac
    
    echo ""
}

# Function to generate summary report
generate_summary() {
    echo "=== Generating Benchmark Suite Summary ==="
    
    local summary_file="$RESULTS_DIR/benchmark_suite_summary.txt"
    
    cat > "$summary_file" << EOF
IOR Benchmark Suite Summary
===========================
Date: $(date)
Benchmark Type: $BENCHMARK_TYPE
Configurations: ${CONFIGS[*]}
Results Directory: $RESULTS_DIR

Configuration Details:
EOF
    
    # Add configuration details
    for config in "${CONFIGS[@]}"; do
        if [ -f "$CONFIG_DIR/${config}.conf" ]; then
            echo "" >> "$summary_file"
            echo "$config Configuration:" >> "$summary_file"
            echo "$(grep -E '^export|^#' "$CONFIG_DIR/${config}.conf" | head -10)" >> "$summary_file"
        fi
    done
    
    # Add log file summary
    echo "" >> "$summary_file"
    echo "Generated Log Files:" >> "$summary_file"
    find "$RESULTS_DIR" -name "*.out" -o -name "*.darshan" -o -name "*.csv" | sort >> "$summary_file"
    
    echo "Summary report saved to: $summary_file"
}

# Main execution
echo "Starting benchmark suite execution..."
echo "Results will be saved to: $RESULTS_DIR"
echo ""

# Track success/failure
TOTAL_RUNS=0
SUCCESSFUL_RUNS=0

# Run benchmarks for each configuration
for config in "${CONFIGS[@]}"; do
    case "$BENCHMARK_TYPE" in
        "posix")
            TOTAL_RUNS=$((TOTAL_RUNS + 1))
            if run_benchmark_config "$config" "posix"; then
                SUCCESSFUL_RUNS=$((SUCCESSFUL_RUNS + 1))
            fi
            ;;
        "hdf5")
            TOTAL_RUNS=$((TOTAL_RUNS + 1))
            if run_benchmark_config "$config" "hdf5"; then
                SUCCESSFUL_RUNS=$((SUCCESSFUL_RUNS + 1))
            fi
            ;;
        "both")
            TOTAL_RUNS=$((TOTAL_RUNS + 2))
            if run_benchmark_config "$config" "posix"; then
                SUCCESSFUL_RUNS=$((SUCCESSFUL_RUNS + 1))
            fi
            if run_benchmark_config "$config" "hdf5"; then
                SUCCESSFUL_RUNS=$((SUCCESSFUL_RUNS + 1))
            fi
            ;;
    esac
done

# Generate summary
generate_summary

# Final report
echo "=== Benchmark Suite Completed ==="
echo "Total runs: $TOTAL_RUNS"
echo "Successful runs: $SUCCESSFUL_RUNS"
echo "Failed runs: $((TOTAL_RUNS - SUCCESSFUL_RUNS))"
echo "Success rate: $(( (SUCCESSFUL_RUNS * 100) / TOTAL_RUNS ))%"
echo ""
echo "Results saved to: $RESULTS_DIR"
echo "Summary report: $RESULTS_DIR/benchmark_suite_summary.txt"

# Analyze collected data if Python script exists
if [ -f "$SCRIPT_DIR/analyze_benchmark_results.py" ]; then
    echo ""
    echo "Running analysis on collected data..."
    python3 "$SCRIPT_DIR/analyze_benchmark_results.py" "$RESULTS_DIR"
fi

