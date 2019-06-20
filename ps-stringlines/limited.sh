#!/bin/sh

rm V*.dat

# Generate 15 minute headways from 5:00a to 9:15a
for arrival in $(seq 300 15 555); do awk -F, -v start=$((arrival - 49)) 'NR > 1 && $3 != "" {printf("\"%s\"\t%.1f\t%d:%02d\n", $2, $1, (start + $3) / 60, (start + $3) % 60)}' ../ps-schedule.csv > V${arrival}.dat; done

# Generate 30 minute headways from 9:30a to 12n
for arrival in $(seq 570 30 720); do awk -F, -v start=$((arrival - 49)) 'NR > 1 && $3 != "" {printf("\"%s\"\t%.1f\t%d:%02d\n", $2, $1, (start + $3) / 60, (start + $3) % 60)}' ../ps-schedule.csv > V${arrival}.dat; done

# Generate extra limited-stop runs at 15-minute headways from 7:30a
# to 9:00a
for arrival in $(seq 452 15 527); do awk -F, -v start=$((arrival - 38)) 'NR > 1 && $15 != "" {printf("\"%s\"\t%.1f\t%d:%02d\n", $2, $1, (start + $15) / 60, (start + $15) % 60)}' ../ps-schedule.csv > V${arrival}L.dat; done

# Other conflicts:


