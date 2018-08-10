# Simulating Regional Rail on the MBTA Framingham/Worcester Line

This repository contains some R code and data files related to
simulating passenger loads and schedules on the MBTA
Framingham/Worcester Line.  There are *significant* caveats to this;
please read my [blog post](https://blog.bimajority.org/2018/08/05/in-which-i-waste-an-entire-weekend-modeling-one-line-of-regional-rail-in-am-peak/)
for more information about the methodology and data sources.
Patches and improvements gladly accepted.

The following changes have been made since the initial blog post:
* Use of global variables has been substantially reduced, to allow for
the model to be generalized and eventually applied to other lines and
other scenarios.
* Other places where values were hardcoded have been replaced with
code to deduce or generate the required data.
* We now run 250 Monte Carlo trials and output the 90th percentile
loadings rather than just running the simulation once and outputting
the exact simulated loadings from that one run.
* The unit requirements are computed, based on the results of the
simulation and a parameter which is the number of passengers per unit.
* Improvements have been made to the schedule calculations, in
preparation for adding the ability to handle more complex service
patterns like short turns and expresses.

The files in this repository are as follows:

* `2012-boardings.csv`: net inbound Framingham/Worcester boardings at all
stations for all AM departures, taken from the 2012 CTPS ridership
audit

* `4tph-local.csv`: simulated loadings (cumulative net boardings) under a
Regional Rail scenario with four trains per hour, all local trains

* `5tph-local.csv`: same but for five trains per hour

* `6tph-local.csv`: same but for six trains per hour

* `Framingham-Worcester Inbound.{numbers,pdf}`: the spreadsheet I used to
work out the schedule of various local and express configurations as
well as equipment and storage requirements, with a viewable/printable
PDF if you just want to look at the results

* `emu-schedule.csv`: a schedule for an inbound Regional Rail local train,
based on Alon Levy's modeling for North-South Rail Link, with Alon's
proposed infill stations removed

* `train.sched.r`: some very bad R code for simulating passenger counts
based on observed boardings; uses lots of global variables and needs
to be refactored.  See the blog post for additional caveats.

