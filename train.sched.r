#
# Load the 2012 CTPS data and transform it to make it slightly easier to
# work with.  This should all be encapsulated somehow, but I'm not much
# of an R programmer and I found it difficult enough to make even this
# work.
#
boardings.ctps <- read.csv("2012-boardings.csv", row.names = 2)
arrival.times.df <- read.csv("2012-arrival-times.csv")
stations <- rownames(boardings.ctps)
terminal <- stations[length(stations)]

#
# Train times are coded as minutes since midnight local time.
# These arrival times are for the Winter 2012 schedule, relevant to
# the CTPS data.  Subset the boardings data to just those trains
# whose arrival times we model.
#
arrival.times <- arrival.times.df$time_minute
trains <- arrival.times.df$train
names(arrival.times) <- trains
# for some reason, we can't say boardings.ctps[trains] here, idk why
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

#
# Sample function, uses the global variables
#
sample.pax <- function (station) {
  return (sample.arrivals(trains, boardings.ctps, station))
}

#
# Simulate the new schedule given a source of desired arrival time samples
# and the new schedule.
#
simulate.pax <- function (sampler, new.arrivals, model.stations, terminal,
	     		  schedule) {
  # initialize data frame
  pax.cumulative <- data.frame(station = model.stations)
  rownames(pax.cumulative) <- pax.cumulative$station

  for (train in names(new.arrivals)) {
    pax.cumulative[train] <- rep(0, length(model.stations))
  }

  last.sums <- rep(0, length(new.arrivals))
  for (station in model.stations) {
    arrivals <- sampler(station)
    for (i in 1:(length(new.arrivals))) {
      this.train <- names(new.arrivals)[i]
      next.train <- names(new.arrivals)[i + 1]
      if (is.na(next.train)) {
        boarding <- arrivals[which(arrivals >= schedule[terminal, this.train])]
      } else {
        boarding <- arrivals[which(arrivals >= schedule[terminal, this.train] &
      	       	  		   arrivals < schedule[terminal, next.train])]
      }
      last.sums[i] <- last.sums[i] + length(boarding)
      pax.cumulative[station,this.train] <- last.sums[i]
    }
  }

  return (pax.cumulative)
}

# Compute units required -- a property of the train, not of individual
# stations, so compute the max loading (NA's excluded) for each train.
required.units <- function (trains, loading, capacity) {
  units <- rep(NA, length(trains))
  names(units) <- trains

  for (train in trains) {
    units[train] <- ceiling(max(loading[train], na.rm = TRUE) / capacity)
  }
  return (units)
}

monte.carlo.pax <- function (n, sampler, new.arrivals, model.stations, terminal,
		   	     schedule, handler) {
  med.pax <- data.frame(station = model.stations, row.names = model.stations)
  pct90.pax <- data.frame(station = model.stations, row.names = model.stations)
  res <- list()
  trains <- names(new.arrivals)

  for (i in 1:n) {
    res[[i]] <- simulate.pax(sampler, new.arrivals, model.stations, terminal, 
    	   		     schedule)
  }
  for (station in model.stations) {
    for (train in trains) {
      v <- rep(NA, length(trains))
      for (i in 1:n) {
        v[[i]] <- res[[i]][station,train]
      }
      q <- quantile(v, probs = c(0.5, 0.9), na.rm = TRUE)
      med.pax[station, train] <- q[1]
      pct90.pax[station, train] <- q[2]
    }
  }

  return (handler(med.pax, pct90.pax))
}
    
result.handler <- function (filename, capacity, trains, want.median = FALSE) {
  return (function (med, pct90) {
    if (want.median) {
      message("Median passenger loads:")
      print(ceiling(med[trains]))
      write.csv(ceiling(med[trains]), paste("median-", filename, sep = ""))
      message("")
    }

    message("90th percentile passenger loads:")
    print(ceiling(pct90[trains]))
    write.csv(ceiling(pct90[trains]), paste("90pct-", filename, sep = ""))
    message("")

    if (want.median) {
      message("Difference between median and 90th %ile")
      print(pct90[trains] - med[trains])
      message("")
    }

    message("Units required:")
    units <- required.units(trains, pct90, capacity)
    print(units)
    return (units)
  })
}

run.trials <- function(ntrials = 250) {
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

  monte.carlo.pax(ntrials, sample.pax, new.arrivals, model.stations, terminal,
		  schedule, 
		  result.handler("5tph-local.csv", 232, names(new.arrivals)))
}

run.trials()
