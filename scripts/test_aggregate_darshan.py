# test_aggregate_darshan.py
import sys
sys.path.append('/u/mbanisharifdehkordi/work/hdd/bdau/mbanisharifdehkordi/GNN_4_IO_5')

from src.darshan import process_multiple_logs

# All 4 IOR process logs
log_files = [
    "/u/mbanisharifdehkordi/ior-darshan-repo/logs/2025/8/14/mbanisha_ior_id311810-311810_8-14-76121-17188222232049623171_1.darshan",
    "/u/mbanisharifdehkordi/ior-darshan-repo/logs/2025/8/14/mbanisha_ior_id311811-311811_8-14-76121-12129391993060542129_1.darshan",
    "/u/mbanisharifdehkordi/ior-darshan-repo/logs/2025/8/14/mbanisha_ior_id311812-311812_8-14-76121-11600146204377663224_1.darshan",
    "/u/mbanisharifdehkordi/ior-darshan-repo/logs/2025/8/14/mbanisha_ior_id311813-311813_8-14-76121-7504921136711006361_1.darshan"
]

# Process all logs
results = process_multiple_logs(log_files, output_csv="ior_all_ranks_features.csv")

print(f"Processed {len(results)} logs")
for i, result in enumerate(results):
    print(f"Rank {i}: Performance = {result['performance_raw']:.2f} MB/s")