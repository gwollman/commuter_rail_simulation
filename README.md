# Simulating Regional Rail on the MBTA Framingham/Worcester Line

This repository contains some R code and data files related to
simulating passenger loads and schedules on the MBTA
Framingham/Worcester Line.  There are *significant* caveats to this;
please read my blog post at

XXX FILL ME IN AFTER POSTING

for more information about the methodology and data sources.

The files in this repository are as follows:

2012-boardings.csv: net inbound Framingham/Worcester boardings at all
stations for all AM departures, taken from the 2012 CTPS ridership
audit

4tph-local.csv: simulated loadings (cumulative net boardings) under a
Regional Rail scenario with four trains per hour, all local trains

5tph-local.csv: same but for five trains per hour

6tph-local.csv: same but for six trains per hour

Framingham-Worcester Inbound.{numbers,pdf}: the spreadsheet I used to
work out the schedule of various local and express configurations as
well as equipment and storage requirements, with a viewable/printable
PDF if you just want to look at the results

emu-schedule.csv: a schedule for an inbound Regional Rail local train,
based on Alon Levy's modeling for North-South Rail Link, with Alon's
proposed infill stations removed

train.sched.r: some very bad R code for simulating passenger counts
based on observed boardings; uses lots of global variables and needs
to be refactored.  See the blog post for additional caveats.

