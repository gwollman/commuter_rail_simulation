#!/bin/sh

# Generate one local train departing BOS every 15 minutes from 5:05a to 9:50a
for departure in $(seq 305 15 580); do awk -F, -v start=$departure 'NR > 1 && $3 != "" {printf("\"%s\"\t%.1f\t%d:%02d\n", $2, $1, (start + 49 - $3) / 60, (start + 49 - $3) % 60)}' ../ps-schedule.csv | tail -r > U${departure}.dat; done

# The 6:05 departure from BOS conflicts with Amtrak 95 so is not permitted.
rm U365.dat
# The 7:05 departure conflicts with Amtrak 2155.
rm U425.dat
# The 8:50 departure conflicts with Amtrak 2159.
rm U530.dat
# The 9:35 departure conflicts with Amtrak 93.
rm U575.dat

# Generate one local train departing BOS every 30 minutes from 10a to 12:05p
for departure in $(seq 605 30 725); do awk -F, -v start=$departure 'NR > 1 && $3 != "" {printf("\"%s\"\t%.1f\t%d:%02d\n", $2, $1, (start + 49 - $3) / 60, (start + 49 - $3) % 60)}' ../ps-schedule.csv | tail -r > U${departure}.dat; done

# Other conflicts:

# Stoughton train 905 needs to depart slightly later and make local stops.
