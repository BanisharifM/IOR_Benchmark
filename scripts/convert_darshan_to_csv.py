import darshan
import pandas as pd
import os
import sys

def darshan_to_csv(log_path, output_csv):
    # Open the darshan log file
    log = darshan.DarshanReport(log_path)

    # Collect all modules (POSIX, MPI-IO, etc.)
    records = log.records

    all_data = []

    for mod, mod_records in records.items():
        for rec in mod_records:
            rec_dict = {
                "module": mod,
                "rank": rec["rank"],
                "filename": rec["filename"] if "filename" in rec else "N/A"
            }
            # Merge counters and fcounters
            if "counters" in rec:
                rec_dict.update({f"{mod}_CTR_{k}": v for k, v in rec["counters"].items()})
            if "fcounters" in rec:
                rec_dict.update({f"{mod}_FCTR_{k}": v for k, v in rec["fcounters"].items()})
            all_data.append(rec_dict)

    # Convert to DataFrame
    df = pd.DataFrame(all_data)

    # Save to CSV
    df.to_csv(output_csv, index=False)
    print(f"Saved Darshan metrics to: {output_csv}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python convert_darshan_to_csv.py <input.darshan_partial> <output.csv>")
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2]

    darshan_to_csv(input_path, output_path)
