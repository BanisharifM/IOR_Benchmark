#!/usr/bin/env python3

"""
Analyze CSV Data for I/O Counter Coverage
This script analyzes the provided CSV data to determine how many entries have the required I/O counters.
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from collections import Counter
import sys
import os

def analyze_csv_data(csv_file):
    """Analyze the CSV data for I/O counter coverage."""
    
    print(f"Loading CSV data from: {csv_file}")
    
    # Load the CSV data
    try:
        df = pd.read_csv(csv_file)
        print(f"Successfully loaded {len(df)} rows and {len(df.columns)} columns")
    except Exception as e:
        print(f"Error loading CSV file: {e}")
        return None
    
    # Display basic information about the dataset
    print("\n=== Dataset Overview ===")
    print(f"Shape: {df.shape}")
    print(f"Columns: {list(df.columns)}")
    
    # Check for missing values
    print("\n=== Missing Values Analysis ===")
    missing_counts = df.isnull().sum()
    missing_percentages = (missing_counts / len(df)) * 100
    
    print("Missing values per column:")
    for col in df.columns:
        if missing_counts[col] > 0:
            print(f"  {col}: {missing_counts[col]} ({missing_percentages[col]:.1f}%)")
    
    total_missing = missing_counts.sum()
    print(f"Total missing values: {total_missing}")
    
    # Analyze I/O counter coverage
    print("\n=== I/O Counter Coverage Analysis ===")
    
    # Define the key I/O counters from the CSV header
    posix_counters = [col for col in df.columns if col.startswith('POSIX_')]
    lustre_counters = [col for col in df.columns if col.startswith('LUSTRE_')]
    
    print(f"POSIX counters found: {len(posix_counters)}")
    print(f"Lustre counters found: {len(lustre_counters)}")
    
    # Count entries with non-zero values for each counter type
    posix_coverage = {}
    for counter in posix_counters:
        non_zero_count = (df[counter] != 0).sum()
        coverage_percentage = (non_zero_count / len(df)) * 100
        posix_coverage[counter] = {
            'non_zero_count': non_zero_count,
            'coverage_percentage': coverage_percentage
        }
    
    # Display coverage statistics
    print("\n=== POSIX Counter Coverage ===")
    for counter, stats in posix_coverage.items():
        print(f"{counter}: {stats['non_zero_count']}/{len(df)} ({stats['coverage_percentage']:.1f}%)")
    
    # Analyze entries with complete I/O counter data
    print("\n=== Complete Data Analysis ===")
    
    # Count entries with all required counters having non-zero values
    required_counters = [
        'POSIX_OPENS', 'POSIX_READS', 'POSIX_WRITES', 'POSIX_BYTES_READ', 
        'POSIX_BYTES_WRITTEN', 'POSIX_SEEKS', 'POSIX_STATS'
    ]
    
    complete_entries = 0
    for idx, row in df.iterrows():
        has_all_counters = all(row[counter] != 0 for counter in required_counters if counter in df.columns)
        if has_all_counters:
            complete_entries += 1
    
    complete_percentage = (complete_entries / len(df)) * 100
    print(f"Entries with all required POSIX counters: {complete_entries}/{len(df)} ({complete_percentage:.1f}%)")
    
    # Analyze data distribution
    print("\n=== Data Distribution Analysis ===")
    
    # Basic statistics for key counters
    key_counters = ['nprocs', 'POSIX_OPENS', 'POSIX_READS', 'POSIX_WRITES', 
                   'POSIX_BYTES_READ', 'POSIX_BYTES_WRITTEN']
    
    for counter in key_counters:
        if counter in df.columns:
            print(f"\n{counter}:")
            print(f"  Min: {df[counter].min():.3f}")
            print(f"  Max: {df[counter].max():.3f}")
            print(f"  Mean: {df[counter].mean():.3f}")
            print(f"  Std: {df[counter].std():.3f}")
    
    # Create visualizations
    create_visualizations(df, posix_counters)
    
    return {
        'total_entries': len(df),
        'complete_entries': complete_entries,
        'complete_percentage': complete_percentage,
        'posix_coverage': posix_coverage,
        'missing_values': total_missing
    }

def create_visualizations(df, posix_counters):
    """Create visualizations for the I/O counter data."""
    
    print("\n=== Creating Visualizations ===")
    
    # Set up the plotting style
    plt.style.use('default')
    sns.set_palette("husl")
    
    # Figure 1: Coverage heatmap for key POSIX counters
    key_posix_counters = [col for col in posix_counters if any(x in col for x in 
                         ['OPENS', 'READS', 'WRITES', 'BYTES', 'SEEKS', 'STATS'])][:15]
    
    if key_posix_counters:
        fig, ax = plt.subplots(figsize=(12, 8))
        
        # Create binary matrix (1 for non-zero, 0 for zero)
        binary_data = (df[key_posix_counters] != 0).astype(int)
        
        # Create heatmap
        sns.heatmap(binary_data.T, cmap='RdYlBu_r', cbar_kws={'label': 'Has Data (1) / No Data (0)'}, ax=ax)
        ax.set_title('I/O Counter Data Coverage Heatmap\n(Rows: Counters, Columns: Entries)', fontsize=14)
        ax.set_xlabel('Entry Index', fontsize=12)
        ax.set_ylabel('POSIX Counters', fontsize=12)
        
        plt.tight_layout()
        plt.savefig('/home/ubuntu/ior-darshan-repo/logs/io_counter_coverage_heatmap.png', dpi=300, bbox_inches='tight')
        plt.close()
        print("✓ Coverage heatmap saved")
    
    # Figure 2: Distribution of key metrics
    fig, axes = plt.subplots(2, 3, figsize=(15, 10))
    axes = axes.flatten()
    
    key_metrics = ['nprocs', 'POSIX_OPENS', 'POSIX_READS', 'POSIX_WRITES', 
                  'POSIX_BYTES_READ', 'POSIX_BYTES_WRITTEN']
    
    for i, metric in enumerate(key_metrics):
        if metric in df.columns and i < len(axes):
            # Filter out zero values for better visualization
            non_zero_data = df[df[metric] != 0][metric]
            if len(non_zero_data) > 0:
                axes[i].hist(non_zero_data, bins=30, alpha=0.7, edgecolor='black')
                axes[i].set_title(f'{metric} Distribution\n(Non-zero values only)', fontsize=10)
                axes[i].set_xlabel('Value', fontsize=9)
                axes[i].set_ylabel('Frequency', fontsize=9)
                axes[i].grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('/home/ubuntu/ior-darshan-repo/logs/io_counter_distributions.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("✓ Distribution plots saved")
    
    # Figure 3: Coverage summary bar chart
    coverage_data = []
    coverage_labels = []
    
    key_counters = ['POSIX_OPENS', 'POSIX_READS', 'POSIX_WRITES', 'POSIX_BYTES_READ', 
                   'POSIX_BYTES_WRITTEN', 'POSIX_SEEKS', 'POSIX_STATS']
    
    for counter in key_counters:
        if counter in df.columns:
            coverage_pct = ((df[counter] != 0).sum() / len(df)) * 100
            coverage_data.append(coverage_pct)
            coverage_labels.append(counter.replace('POSIX_', ''))
    
    if coverage_data:
        fig, ax = plt.subplots(figsize=(12, 6))
        bars = ax.bar(coverage_labels, coverage_data, color='skyblue', edgecolor='navy', alpha=0.7)
        
        # Add value labels on bars
        for bar, value in zip(bars, coverage_data):
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height + 1,
                   f'{value:.1f}%', ha='center', va='bottom', fontsize=10)
        
        ax.set_title('I/O Counter Coverage Percentage', fontsize=14)
        ax.set_xlabel('POSIX Counters', fontsize=12)
        ax.set_ylabel('Coverage Percentage (%)', fontsize=12)
        ax.set_ylim(0, 105)
        ax.grid(True, alpha=0.3, axis='y')
        
        plt.xticks(rotation=45, ha='right')
        plt.tight_layout()
        plt.savefig('/home/ubuntu/ior-darshan-repo/logs/io_counter_coverage_summary.png', dpi=300, bbox_inches='tight')
        plt.close()
        print("✓ Coverage summary chart saved")

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 analyze_csv_data.py <csv_file>")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    
    if not os.path.exists(csv_file):
        print(f"Error: CSV file not found: {csv_file}")
        sys.exit(1)
    
    # Analyze the data
    results = analyze_csv_data(csv_file)
    
    if results:
        print("\n=== Summary Report ===")
        print(f"Total entries analyzed: {results['total_entries']}")
        print(f"Entries with complete I/O counter data: {results['complete_entries']}")
        print(f"Percentage with complete data: {results['complete_percentage']:.1f}%")
        print(f"Total missing values: {results['missing_values']}")
        
        # Save summary to file
        summary_file = '/home/ubuntu/ior-darshan-repo/logs/csv_analysis_summary.txt'
        with open(summary_file, 'w') as f:
            f.write("CSV Data Analysis Summary\n")
            f.write("=" * 50 + "\n\n")
            f.write(f"Total entries: {results['total_entries']}\n")
            f.write(f"Complete entries: {results['complete_entries']}\n")
            f.write(f"Complete percentage: {results['complete_percentage']:.1f}%\n")
            f.write(f"Missing values: {results['missing_values']}\n\n")
            
            f.write("POSIX Counter Coverage:\n")
            for counter, stats in results['posix_coverage'].items():
                f.write(f"  {counter}: {stats['coverage_percentage']:.1f}%\n")
        
        print(f"\nDetailed summary saved to: {summary_file}")
        print("Visualizations saved to /home/ubuntu/ior-darshan-repo/logs/")

if __name__ == "__main__":
    main()

