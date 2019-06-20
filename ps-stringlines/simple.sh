#!/bin/sh

# Generate one local train arriving BOS every 15 minutes from 5:00a to 9:45a
for arrival in $(seq 300 15 575); do awk -F, -v start=$((arrival - 49)) 'NR > 1 && $3 != "" {printf("\"%s\"\t%.1f\t%d:%02d\n", $2, $1, (start + $3) / 60, (start + $3) % 60)}' ../ps-schedule.csv > V${arrival}.dat; done

# The 7:45 arrival at BOS conflicts with Amtrak 66 so is not permitted.
rm V465.dat

# Generate one local train arriving BOS every 30 minutes from 10a to 12n
for arrival in $(seq 600 30 720); do awk -F, -v start=$((arrival - 49)) 'NR > 1 && $3 != "" {printf("\"%s\"\t%.1f\t%d:%02d\n", $2, $1, (start + $3) / 60, (start + $3) % 60)}' ../ps-schedule.csv > V${arrival}.dat; done

# Other conflicts:

# Stoughton train 904 (arriving 8:32) needs to be shifted a few minutes
# and run express from RTE to BBY (no stop at Ruggles).  Passengers for
# Ruggles can transfer to V510 at Canton Jct. or RTE.

# Stoughton train 908 (arriving 9:43) needs to be shifted a few minutes
# later and make all local stops to avoid conflict with V575 (arriving
# 9:45).

