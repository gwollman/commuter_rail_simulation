#!/bin/sh

rm U*.dat

# Generate 15 minute headways from 6:11a to 7:26a
for departure in $(seq 371 15 446); do awk -F, -v start=$departure 'NR > 1 && $3 != "" {printf("\"%s\"\t%.1f\t%d:%02d\n", $2, $1, (start + 49 - $3) / 60, (start + 49 - $3) % 60)}' ../ps-schedule.csv > U${departure}.dat; done

# Generate 10 minute headways from 7:41a to 8:31a
for departure in $(seq 461 10 511); do awk -F, -v start=$departure 'NR > 1 && $3 != "" {printf("\"%s\"\t%.1f\t%d:%02d\n", $2, $1, (start + 49 - $3) / 60, (start + 49 - $3) % 60)}' ../ps-schedule.csv > U${departure}.dat; done

# Generate 15 minute headways from 8:41a to 9:26a
for departure in $(seq 521 15 566); do awk -F, -v start=$departure 'NR > 1 && $3 != "" {printf("\"%s\"\t%.1f\t%d:%02d\n", $2, $1, (start + 49 - $3) / 60, (start + 49 - $3) % 60)}' ../ps-schedule.csv > U${departure}.dat; done

# Generate 30 minute headways from 9:41a to 12:11p
for departure in $(seq 581 30 731); do awk -F, -v start=$departure 'NR > 1 && $3 != "" {printf("\"%s\"\t%.1f\t%d:%02d\n", $2, $1, (start + 49 - $3) / 60, (start + 49 - $3) % 60)}' ../ps-schedule.csv > U${departure}.dat; done

# Other conflicts:

