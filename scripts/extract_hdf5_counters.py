#!/usr/bin/env python3

"""
Extract HDF5 and POSIX I/O Counters from Darshan Log
This script extracts both HDF5 and underlying POSIX I/O counters from a Darshan log file.
"""

import sys
import os
import subprocess
import csv
import re
from collections import defaultdict

def parse_darshan_log(log_file):
    """Parse Darshan log file and extract HDF5 and POSIX counters."""
    
    # Run darshan-parser to get text output
    try:
        result = subprocess.run(['darshan-parser', log_file], 
                              capture_output=True, text=True, check=True)
        log_content = result.stdout
    except subprocess.CalledProcessError as e:
        print(f"Error parsing Darshan log: {e}")
        return None
    
    # Initialize counters dictionary
    counters = {
        'nprocs': 0,
        'POSIX_OPENS': 0,
        'LUSTRE_STRIPE_SIZE': 0,
        'LUSTRE_STRIPE_WIDTH': 0,
        'POSIX_FILENOS': 0,
        'POSIX_MEM_ALIGNMENT': 0,
        'POSIX_FILE_ALIGNMENT': 0,
        'POSIX_READS': 0,
        'POSIX_WRITES': 0,
        'POSIX_SEEKS': 0,
        'POSIX_STATS': 0,
        'POSIX_BYTES_READ': 0,
        'POSIX_BYTES_WRITTEN': 0,
        'POSIX_CONSEC_READS': 0,
        'POSIX_CONSEC_WRITES': 0,
        'POSIX_SEQ_READS': 0,
        'POSIX_SEQ_WRITES': 0,
        'POSIX_RW_SWITCHES': 0,
        'POSIX_MEM_NOT_ALIGNED': 0,
        'POSIX_FILE_NOT_ALIGNED': 0,
        'POSIX_SIZE_READ_0_100': 0,
        'POSIX_SIZE_READ_100_1K': 0,
        'POSIX_SIZE_READ_1K_10K': 0,
        'POSIX_SIZE_READ_100K_1M': 0,
        'POSIX_SIZE_WRITE_0_100': 0,
        'POSIX_SIZE_WRITE_100_1K': 0,
        'POSIX_SIZE_WRITE_1K_10K': 0,
        'POSIX_SIZE_WRITE_10K_100K': 0,
        'POSIX_SIZE_WRITE_100K_1M': 0,
        'POSIX_STRIDE1_STRIDE': 0,
        'POSIX_STRIDE2_STRIDE': 0,
        'POSIX_STRIDE3_STRIDE': 0,
        'POSIX_STRIDE4_STRIDE': 0,
        'POSIX_STRIDE1_COUNT': 0,
        'POSIX_STRIDE2_COUNT': 0,
        'POSIX_STRIDE3_COUNT': 0,
        'POSIX_STRIDE4_COUNT': 0,
        'POSIX_ACCESS1_ACCESS': 0,
        'POSIX_ACCESS2_ACCESS': 0,
        'POSIX_ACCESS3_ACCESS': 0,
        'POSIX_ACCESS4_ACCESS': 0,
        'POSIX_ACCESS1_COUNT': 0,
        'POSIX_ACCESS2_COUNT': 0,
        'POSIX_ACCESS3_COUNT': 0,
        'POSIX_ACCESS4_COUNT': 0,
        'HDF5_OPENS': 0,
        'HDF5_READS': 0,
        'HDF5_WRITES': 0,
        'HDF5_BYTES_READ': 0,
        'HDF5_BYTES_WRITTEN': 0,
        'tag': 'ior_hdf5_benchmark'
    }
    
    # Parse log content
    lines = log_content.split('\n')
    
    # Extract number of processes
    for line in lines:
        if 'nprocs:' in line:
            match = re.search(r'nprocs:\s*(\d+)', line)
            if match:
                counters['nprocs'] = int(match.group(1))
                break
    
    # Extract counters from different modules
    current_module = None
    for line in lines:
        line = line.strip()
        
        # Detect module sections
        if 'POSIX' in line and 'module data' in line:
            current_module = 'POSIX'
            continue
        elif 'HDF5' in line and 'module data' in line:
            current_module = 'HDF5'
            continue
        elif 'module data' in line and current_module:
            current_module = None
            continue
        
        if current_module and line.startswith('#'):
            continue
            
        if current_module and not line:
            continue
        
        if current_module:
            # Parse counter lines
            parts = line.split()
            if len(parts) >= 3:
                counter_name = parts[1]
                try:
                    counter_value = float(parts[2])
                    
                    # Map counter names based on module
                    if current_module == 'POSIX':
                        if counter_name == 'POSIX_OPENS':
                            counters['POSIX_OPENS'] += counter_value
                        elif counter_name == 'POSIX_READS':
                            counters['POSIX_READS'] += counter_value
                        elif counter_name == 'POSIX_WRITES':
                            counters['POSIX_WRITES'] += counter_value
                        elif counter_name == 'POSIX_SEEKS':
                            counters['POSIX_SEEKS'] += counter_value
                        elif counter_name == 'POSIX_STATS':
                            counters['POSIX_STATS'] += counter_value
                        elif counter_name == 'POSIX_BYTES_READ':
                            counters['POSIX_BYTES_READ'] += counter_value
                        elif counter_name == 'POSIX_BYTES_WRITTEN':
                            counters['POSIX_BYTES_WRITTEN'] += counter_value
                        elif counter_name == 'POSIX_CONSEC_READS':
                            counters['POSIX_CONSEC_READS'] += counter_value
                        elif counter_name == 'POSIX_CONSEC_WRITES':
                            counters['POSIX_CONSEC_WRITES'] += counter_value
                        elif counter_name == 'POSIX_SEQ_READS':
                            counters['POSIX_SEQ_READS'] += counter_value
                        elif counter_name == 'POSIX_SEQ_WRITES':
                            counters['POSIX_SEQ_WRITES'] += counter_value
                        elif counter_name == 'POSIX_RW_SWITCHES':
                            counters['POSIX_RW_SWITCHES'] += counter_value
                        elif counter_name == 'POSIX_MEM_NOT_ALIGNED':
                            counters['POSIX_MEM_NOT_ALIGNED'] += counter_value
                        elif counter_name == 'POSIX_FILE_NOT_ALIGNED':
                            counters['POSIX_FILE_NOT_ALIGNED'] += counter_value
                    
                    elif current_module == 'HDF5':
                        if counter_name == 'HDF5_OPENS':
                            counters['HDF5_OPENS'] += counter_value
                        elif counter_name == 'HDF5_READS':
                            counters['HDF5_READS'] += counter_value
                        elif counter_name == 'HDF5_WRITES':
                            counters['HDF5_WRITES'] += counter_value
                        elif counter_name == 'HDF5_BYTES_READ':
                            counters['HDF5_BYTES_READ'] += counter_value
                        elif counter_name == 'HDF5_BYTES_WRITTEN':
                            counters['HDF5_BYTES_WRITTEN'] += counter_value
                    
                except ValueError:
                    continue
    
    # Calculate derived values (using log10 transformation like in the sample data)
    import math
    
    # Apply log10 transformation to non-zero values
    for key, value in counters.items():
        if key not in ['tag'] and value > 0:
            counters[key] = math.log10(value)
        elif key not in ['tag']:
            counters[key] = 0.0
    
    return counters

def main():
    if len(sys.argv) != 3:
        print("Usage: python3 extract_hdf5_counters.py <darshan_log_file> <output_csv_file>")
        sys.exit(1)
    
    log_file = sys.argv[1]
    output_file = sys.argv[2]
    
    if not os.path.exists(log_file):
        print(f"Error: Darshan log file not found: {log_file}")
        sys.exit(1)
    
    print(f"Extracting HDF5 and POSIX counters from: {log_file}")
    
    # Parse the log file
    counters = parse_darshan_log(log_file)
    
    if counters is None:
        print("Error: Failed to parse Darshan log file")
        sys.exit(1)
    
    # Write to CSV file
    fieldnames = [
        'nprocs', 'POSIX_OPENS', 'LUSTRE_STRIPE_SIZE', 'LUSTRE_STRIPE_WIDTH',
        'POSIX_FILENOS', 'POSIX_MEM_ALIGNMENT', 'POSIX_FILE_ALIGNMENT',
        'POSIX_READS', 'POSIX_WRITES', 'POSIX_SEEKS', 'POSIX_STATS',
        'POSIX_BYTES_READ', 'POSIX_BYTES_WRITTEN', 'POSIX_CONSEC_READS',
        'POSIX_CONSEC_WRITES', 'POSIX_SEQ_READS', 'POSIX_SEQ_WRITES',
        'POSIX_RW_SWITCHES', 'POSIX_MEM_NOT_ALIGNED', 'POSIX_FILE_NOT_ALIGNED',
        'POSIX_SIZE_READ_0_100', 'POSIX_SIZE_READ_100_1K', 'POSIX_SIZE_READ_1K_10K',
        'POSIX_SIZE_READ_100K_1M', 'POSIX_SIZE_WRITE_0_100', 'POSIX_SIZE_WRITE_100_1K',
        'POSIX_SIZE_WRITE_1K_10K', 'POSIX_SIZE_WRITE_10K_100K', 'POSIX_SIZE_WRITE_100K_1M',
        'POSIX_STRIDE1_STRIDE', 'POSIX_STRIDE2_STRIDE', 'POSIX_STRIDE3_STRIDE',
        'POSIX_STRIDE4_STRIDE', 'POSIX_STRIDE1_COUNT', 'POSIX_STRIDE2_COUNT',
        'POSIX_STRIDE3_COUNT', 'POSIX_STRIDE4_COUNT', 'POSIX_ACCESS1_ACCESS',
        'POSIX_ACCESS2_ACCESS', 'POSIX_ACCESS3_ACCESS', 'POSIX_ACCESS4_ACCESS',
        'POSIX_ACCESS1_COUNT', 'POSIX_ACCESS2_COUNT', 'POSIX_ACCESS3_COUNT',
        'POSIX_ACCESS4_COUNT', 'HDF5_OPENS', 'HDF5_READS', 'HDF5_WRITES',
        'HDF5_BYTES_READ', 'HDF5_BYTES_WRITTEN', 'tag'
    ]
    
    with open(output_file, 'w', newline='') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerow(counters)
    
    print(f"HDF5 and POSIX counters extracted to: {output_file}")
    print(f"Number of processes: {counters['nprocs']}")
    print(f"HDF5 opens: {counters['HDF5_OPENS']}")
    print(f"HDF5 reads: {counters['HDF5_READS']}")
    print(f"HDF5 writes: {counters['HDF5_WRITES']}")
    print(f"POSIX reads: {counters['POSIX_READS']}")
    print(f"POSIX writes: {counters['POSIX_WRITES']}")

if __name__ == "__main__":
    main()

