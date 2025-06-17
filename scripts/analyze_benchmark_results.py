#!/usr/bin/env python3

"""
Analyze Benchmark Results
This script analyzes the results from multiple benchmark runs and generates comparative reports.
"""

import os
import sys
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import glob
import re
from pathlib import Path

def analyze_benchmark_results(results_dir):
    """Analyze benchmark results from a suite run."""
    
    print(f"Analyzing benchmark results in: {results_dir}")
    
    # Find all CSV files with counter data
    csv_files = glob.glob(os.path.join(results_dir, "*_counters_*.csv"))
    
    if not csv_files:
        print("No counter CSV files found in results directory")
        return
    
    print(f"Found {len(csv_files)} counter files")
    
    # Load and combine all CSV data
    all_data = []
    
    for csv_file in csv_files:
        try:
            df = pd.read_csv(csv_file)
            
            # Extract configuration and benchmark type from filename
            filename = os.path.basename(csv_file)
            
            # Parse filename pattern: configname_benchmarktype_timestamp_counters.csv
            parts = filename.replace('_counters_', '_SPLIT_').split('_SPLIT_')[0].split('_')
            
            if len(parts) >= 2:
                config_name = parts[0]
                benchmark_type = parts[1] if parts[1] in ['posix', 'hdf5'] else 'unknown'
            else:
                config_name = 'unknown'
                benchmark_type = 'unknown'
            
            df['config_name'] = config_name
            df['benchmark_type'] = benchmark_type
            df['source_file'] = filename
            
            all_data.append(df)
            
        except Exception as e:
            print(f"Error loading {csv_file}: {e}")
    
    if not all_data:
        print("No valid data found")
        return
    
    # Combine all data
    combined_df = pd.concat(all_data, ignore_index=True)
    
    print(f"Combined data shape: {combined_df.shape}")
    print(f"Configurations: {combined_df['config_name'].unique()}")
    print(f"Benchmark types: {combined_df['benchmark_type'].unique()}")
    
    # Generate comparative analysis
    generate_comparative_analysis(combined_df, results_dir)
    
    # Save combined data
    combined_file = os.path.join(results_dir, "combined_benchmark_results.csv")
    combined_df.to_csv(combined_file, index=False)
    print(f"Combined results saved to: {combined_file}")

def generate_comparative_analysis(df, results_dir):
    """Generate comparative analysis visualizations."""
    
    print("Generating comparative analysis...")
    
    # Set up plotting style
    plt.style.use('default')
    sns.set_palette("husl")
    
    # Key metrics to compare
    key_metrics = ['nprocs', 'POSIX_OPENS', 'POSIX_READS', 'POSIX_WRITES', 
                  'POSIX_BYTES_READ', 'POSIX_BYTES_WRITTEN']
    
    # 1. Performance comparison across configurations
    fig, axes = plt.subplots(2, 3, figsize=(18, 12))
    axes = axes.flatten()
    
    for i, metric in enumerate(key_metrics):
        if metric in df.columns and i < len(axes):
            # Create box plot comparing configurations
            data_for_plot = []
            labels_for_plot = []
            
            for config in df['config_name'].unique():
                config_data = df[df['config_name'] == config][metric]
                if len(config_data) > 0 and config_data.sum() != 0:
                    data_for_plot.append(config_data)
                    labels_for_plot.append(config)
            
            if data_for_plot:
                axes[i].boxplot(data_for_plot, labels=labels_for_plot)
                axes[i].set_title(f'{metric} by Configuration', fontsize=12)
                axes[i].set_ylabel('Value (log10)', fontsize=10)
                axes[i].tick_params(axis='x', rotation=45)
                axes[i].grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(os.path.join(results_dir, 'configuration_comparison.png'), 
                dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Configuration comparison chart saved")
    
    # 2. Benchmark type comparison (POSIX vs HDF5)
    if len(df['benchmark_type'].unique()) > 1:
        fig, axes = plt.subplots(2, 3, figsize=(18, 12))
        axes = axes.flatten()
        
        for i, metric in enumerate(key_metrics):
            if metric in df.columns and i < len(axes):
                # Compare POSIX vs HDF5
                posix_data = df[df['benchmark_type'] == 'posix'][metric]
                hdf5_data = df[df['benchmark_type'] == 'hdf5'][metric]
                
                data_to_plot = []
                labels_to_plot = []
                
                if len(posix_data) > 0 and posix_data.sum() != 0:
                    data_to_plot.append(posix_data)
                    labels_to_plot.append('POSIX')
                
                if len(hdf5_data) > 0 and hdf5_data.sum() != 0:
                    data_to_plot.append(hdf5_data)
                    labels_to_plot.append('HDF5')
                
                if data_to_plot:
                    axes[i].boxplot(data_to_plot, labels=labels_to_plot)
                    axes[i].set_title(f'{metric}: POSIX vs HDF5', fontsize=12)
                    axes[i].set_ylabel('Value (log10)', fontsize=10)
                    axes[i].grid(True, alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(os.path.join(results_dir, 'benchmark_type_comparison.png'), 
                    dpi=300, bbox_inches='tight')
        plt.close()
        print("✓ Benchmark type comparison chart saved")
    
    # 3. Performance summary table
    summary_data = []
    
    for config in df['config_name'].unique():
        for bench_type in df['benchmark_type'].unique():
            subset = df[(df['config_name'] == config) & (df['benchmark_type'] == bench_type)]
            
            if len(subset) > 0:
                row = {
                    'Configuration': config,
                    'Benchmark Type': bench_type,
                    'Processes': subset['nprocs'].mean() if 'nprocs' in subset.columns else 0,
                    'POSIX Opens': subset['POSIX_OPENS'].mean() if 'POSIX_OPENS' in subset.columns else 0,
                    'POSIX Reads': subset['POSIX_READS'].mean() if 'POSIX_READS' in subset.columns else 0,
                    'POSIX Writes': subset['POSIX_WRITES'].mean() if 'POSIX_WRITES' in subset.columns else 0,
                    'Bytes Read': subset['POSIX_BYTES_READ'].mean() if 'POSIX_BYTES_READ' in subset.columns else 0,
                    'Bytes Written': subset['POSIX_BYTES_WRITTEN'].mean() if 'POSIX_BYTES_WRITTEN' in subset.columns else 0
                }
                summary_data.append(row)
    
    if summary_data:
        summary_df = pd.DataFrame(summary_data)
        summary_file = os.path.join(results_dir, 'performance_summary.csv')
        summary_df.to_csv(summary_file, index=False)
        print(f"✓ Performance summary saved to: {summary_file}")
        
        # Display summary
        print("\nPerformance Summary:")
        print(summary_df.to_string(index=False))

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 analyze_benchmark_results.py <results_directory>")
        sys.exit(1)
    
    results_dir = sys.argv[1]
    
    if not os.path.exists(results_dir):
        print(f"Error: Results directory not found: {results_dir}")
        sys.exit(1)
    
    analyze_benchmark_results(results_dir)

if __name__ == "__main__":
    main()

