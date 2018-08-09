#
# Load the 2012 CTPS data and transform it to make it slightly easier to
# work with.  This should all be encapsulated somehow, but I'm not much
# of an R programmer and I found it difficult enough to make even this
# work.
#
boardings.ctps <- read.csv("2012-boardings.csv")
arrival.times.df <- read.csv("2012-arrival-times.csv")
stations <- boardings.ctps$station
rownames(boardings.ctps) <- stations
terminal <- "South Station"

#
# Train times are coded as minutes since midnight local time.
# These arrival times are for the Winter 2012 schedule, relevant to
# the CTPS data.
#
arrival.times <- arrival.times.df$time_minute
trains <- arrival.times.df$train
names(arrival.times) <- trains
boardings.ctps <- boardings.ctps[names(arrival.times)] 

#
# Simulate passengers at _station_.  Returns a vector of times at which
# the passengers embarking from _station_ would like to arrive at the
# terminal station (i.e., South Station).
#
# The model we are simulating here is that there is a pool of passengers
# looking to travel from _station_ to a terminal (half of them will get
# off at a through station in the city, but that doesn't affect the model
# because all trains take the same time to travel through the city).
#
# Passengers are assumed to take the latest train that would get them to
# their destination on time, and this is modeled as a "desired arrival at
# terminal" uniformly distributed over the interval between trains, or
# the next hour, if it's the last train.
#
# We depart from this model slightly, in two important ways.  First,
# we assume that some people on the train would *actually* like to
# arrive a few minutes earlier, and nobody would literally want to arrive
# exactly when the *next* train is scheduled to arrive (because they'd
# just take that train instead), so there is a _desired.offset_, default
# -5 (five minutes early) that shifts the uniform distribution we're
# sampling from to account for this.  Secondly, if _fuzz.counts_ is TRUE
# (the default setting) then we apply a bit of noise to the passenger counts
# in the source data.  The noise is sampled from a normal distribution
# with mean 1 and standard deviation 0.1, and the resulting noise factor
# is multiplied by the net boarding count in the source data.
#
# See the blog post for more commentary on this model.
#
sample.arrivals <- function (trains, boardings, station, desired.offset = -5,
		   	     fuzz.counts = TRUE) {
  # Filter out trains that did not stop at the audited train
  station.boardings <- boardings[station,which(!is.na(boardings[station,]))]
  arrivals <- arrival.times[names(station.boardings)]
  passengers <- c()

  for (i in 1:length(arrivals)) {
    first.arrival <- arrivals[i] + desired.offset
    if (i == length(arrivals)) {
      last.arrival <- first.arrival + 59
    } else {
      last.arrival <- arrivals[i + 1] + desired.offset
    }

    if (fuzz.counts) {
      # apply a gaussian fuzz to the passenger counts
      count <- as.integer(station.boardings[i] * rnorm(1, 1, 0.1))
    } else {
      count <- station.boardings[i]
    }
    if (count > 0) {
      train.pax <- runif(count, first.arrival, last.arrival)
      passengers <- c(passengers, train.pax)
    }
  }
  return (sort(passengers))
}

# stations that existing in 2012 when the CTPS data was
# collected
existing.stations <- c(TRUE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE,
		       TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE,
		       FALSE, TRUE, TRUE, TRUE)
names(existing.stations) <- stations
model.stations <- stations[existing.stations]

# Drop South Station off the list because the end of the line can never
# have any boardings
length(model.stations) <- length(model.stations) - 1

# Read in and transform the schedule, which indicates how much
# time it takes for an inbound train to get to and serve each
# station.
#
# For a local/express configuration would need to generalize this
# to support multiple schedules.
#
schedule <- read.csv('emu-schedule.csv')
schedule <- schedule[c("station", "minute")]
rownames(schedule) <- schedule$station
schedule$minute[1] = 0

# New service pattern: 5 trains per hour arriving at South Station starting
# at 0600 (360 minutes) for 6 hours (last arrival 12:00 noon) for a
# total of 30 trains
#
# For a local/express or a short-turn configuration would need to generalize
# this to indicate which trains operate which schedule.
#
new.arrivals <- 0:29 * 12 + 360
names(new.arrivals) <- paste('X', as.character(new.arrivals), sep="")

# Add each of the trains in the new service pattern to the schedule.
# Because we care about arrival times the arithmetic is a bit more painful.
for (i in 1:length(new.arrivals)) {
  arrival = new.arrivals[i]
  train = names(new.arrivals)[i]
  schedule[train] <- schedule$minute + arrival - schedule$minute[length(schedule$minute)]
}

# Just the times, in minutes since midnight
schedule.times = schedule[names(schedule)[3:length(names(schedule))]]

format.minutes <- function (time.in.minutes) {
  # unclear why we need time.in.minutes %% 60 to be cast to numeric
  paste(time.in.minutes %/% 60, formatC(as.numeric(time.in.minutes %% 60),
  			    		format = "d", width = "2", flag = "0"),
	sep = ":")
} 

# Example: get the arrival times at any given station in human-readable
# format.
#format.minutes(schedule.times["South Station",])

# Initialize data frames for both net boardings at each station
# and cumulative passenger loads at each station.
pax.boarding <- data.frame(station = model.stations)
rownames(pax.boarding) <- pax.boarding$station
pax.cumulative <- data.frame(station = model.stations)
rownames(pax.cumulative) <- pax.cumulative$station

#
# This loop is actually kinda wrong:
# We should be calling sample.arrivals once per station,
# and using the same simulated arrivals array for each train
# (otherwise some pax will be either over- or under-counted).
# Also, we should be running this a hundred times in a loop
# and computing error bars on these estimates.  Should we
# add some Gaussian noise here too?
#
# I'm not very good at R.  I'm sure there's a super-obvious
# way to do this in R that just don't know.
#
for (i in 1:(length(new.arrivals) - 1)) {
  this.train <- names(new.arrivals)[i]
  next.train <- names(new.arrivals)[i + 1]
  pax.boarding[this.train] <- rep(0, length(model.stations))
  pax.cumulative[this.train] <- rep(0, length(model.stations))

  count <- 0
  for (station in model.stations) {
    arrivals <- sample.arrivals(trains, boardings.ctps, station)
    boarding <- length(arrivals[which(arrivals >= schedule[terminal, this.train] & arrivals < schedule[terminal, next.train])])
    pax.boarding[station,this.train] <- boarding
    count <- count + boarding
    pax.cumulative[station,this.train] <- count
  }
}
