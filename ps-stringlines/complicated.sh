#!/bin/sh

rm V*.dat

# Generate 15 minute headways from 5:00a to 7:15a
for arrival in $(seq 300 15 435); do awk -F, -v start=$((arrival - 49)) 'NR > 1 && $3 != "" {printf("\"%s\"\t%.1f\t%d:%02d\n", $2, $1, (start + $3) / 60, (start + $3) % 60)}' ../ps-schedule.csv > V${arrival}.dat; done

# Generate 10 minute headways from 7:30a to 8:20a
for arrival in $(seq 450 10 500); do awk -F, -v start=$((arrival - 49)) 'NR > 1 && $3 != "" {printf("\"%s\"\t%.1f\t%d:%02d\n", $2, $1, (start + $3) / 60, (start + $3) % 60)}' ../ps-schedule.csv > V${arrival}.dat; done

# Generate 15 minute headways from 8:30a to 9:15a
for arrival in $(seq 510 15 555); do awk -F, -v start=$((arrival - 49)) 'NR > 1 && $3 != "" {printf("\"%s\"\t%.1f\t%d:%02d\n", $2, $1, (start + $3) / 60, (start + $3) % 60)}' ../ps-schedule.csv > V${arrival}.dat; done

# Generate 30 minute headways from 9:30a to 12n
for arrival in $(seq 570 30 720); do awk -F, -v start=$((arrival - 49)) 'NR > 1 && $3 != "" {printf("\"%s\"\t%.1f\t%d:%02d\n", $2, $1, (start + $3) / 60, (start + $3) % 60)}' ../ps-schedule.csv > V${arrival}.dat; done

# Generate two expresses, arriving at 7:53a and 8:38a, for simulation purposes
awk -F, -v start=$((493 - 36)) 'NR > 1 && $7 != "" { printf("\"%s\"\t%.1f\t%d:%02d\n", $2, $1, (start + $7) / 60, (start + $7) % 60)}' ../ps-schedule.csv > V493X.dat
awk -F, -v start=$((518 - 36)) 'NR > 1 && $7 != "" { printf("\"%s\"\t%.1f\t%d:%02d\n", $2, $1, (start + $7) / 60, (start + $7) % 60)}' ../ps-schedule.csv > V518X.dat
# Note that these expresses are not feasible without passing tracks.

# Other conflicts:

# Stoughton train 904 (arriving 8:32) needs to be shifted a few minutes
# and run express from RTE to BBY (no stop at Ruggles).  Passengers for
# Ruggles can transfer to V510 at Canton Jct. or RTE.

# Stoughton train 908 (arriving 9:43) needs to be shifted a few minutes
# later and make all local stops to avoid conflict with V575 (arriving
# 9:45).

