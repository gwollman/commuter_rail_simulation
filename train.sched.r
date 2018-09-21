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
		   	     fuzz.counts = TRUE, fuzz.sigma = 0.05) {
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
      count <- as.integer(station.boardings[i] * rnorm(1, 1, fuzz.sigma))
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
  return (sample.arrivals(trains, boardings.ctps, station,
  	 		  desired.offset = runif(1, -5, 0)))
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
    schedule.here <- schedule[names(new.arrivals)][station,]
    stopping.here <- which(!is.na(schedule.here))
    trains.stopping.here <- names(schedule.here[stopping.here])

    for (i in 1:length(new.arrivals)) {
      this.train <- names(new.arrivals[i])
      # Only compute boardings if this train actually stops at this station
      j <- match(this.train, trains.stopping.here)
      if (is.na(j)) next

      # Find the next train that actually stops here.
      next.train <- trains.stopping.here[j + 1]

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
    
format.minutes <- function (time.in.minutes) {
  # unclear why we need time.in.minutes %% 60 to be cast to numeric
  paste(time.in.minutes %/% 60, formatC(as.numeric(time.in.minutes %% 60),
  			    		format = "d", width = "2", flag = "0"),
	sep = ":")
} 

result.handler <- function (filename, capacity, trains, want.median = FALSE) {
  return (function (med, pct90) {
    if (want.median) {
      message("Median passenger loads:")
      print(ceiling(med[trains]))
      write.csv(ceiling(med[trains]), paste("median", filename, sep = "-"))
      message("")
    }

    message("90th percentile passenger loads:")
    print(ceiling(pct90[trains]))
    write.csv(ceiling(pct90[trains]), paste("90pct", filename, sep = "-"))
    message("")

    if (want.median) {
      message("Difference between median and 90th %ile")
      print(pct90[trains] - med[trains])
      message("")
    }

    message("Units required:")
    units <- required.units(trains, pct90, capacity)
    print(units)
    write.csv(units, paste("units", filename, sep = "-"))
    return (units)
  })
}

make.new.schedule <- function () {
  # Read in and transform the schedule, which indicates how much
  # time it takes for an inbound train to get to and serve each
  # station.
  #
  # For a local/express configuration would need to generalize this
  # to support multiple schedules.
  #
  schedule <- read.csv('emu-schedule.csv')
  schedule <- schedule[c("station", "local", "short", "express")]
  rownames(schedule) <- schedule$station
  schedule$local[1] = 0

  return (schedule)
}

# Generates a service pattern with all local service.
make.local.service <- function (start.time, end.time, tph) {
  interval <- 60 / tph
  n <- (end.time - start.time) %/% interval
  v <- (0:(n - 1) * interval) + start.time
  names(v) <- paste('X', as.character(v), sep="")
  return (list(v, rep('local', n)))
}

# Generates a service pattern with all local service, but
# alternating short-turn and full-length trains.
make.short.service <- function (start.time, end.time, tph) {
  interval <- 60 / tph
  n <- (end.time - start.time) %/% interval
  # Number of trains must be even for this service pattern
  if (n %% 2 == 1) {
    n <- n + 1
  }
  v <- (0:(n - 1) * interval) + start.time
  names(v) <- paste('X', as.character(v), sep="")
  return (list(v, rep(c('short', 'local'), n %/% 2)))
}

# Same as make.short.service but reverses the order.
make.short.service.2 <- function (start.time, end.time, tph) {
  interval <- 60 / tph
  n <- (end.time - start.time) %/% interval
  # Number of trains must be even for this service pattern
  if (n %% 2 == 1) {
    n <- n + 1
  }
  v <- (0:(n - 1) * interval) + start.time
  names(v) <- paste('X', as.character(v), sep="")
  return (list(v, rep(c('local', 'short'), n %/% 2)))
}

run.trials <- function(all.stations, stations.with.data, make.service.pattern,
	      	       filename, ntrials = 250) {
  # Drop the terminal off the list because the end of the line can never
  # have any boardings
  model.stations <- all.stations[stations.with.data]
  terminal <- tail(all.stations, 1)

  schedule <- make.new.schedule()

  # New service pattern: 5 trains per hour arriving at South Station starting
  # at 0600 (360 minutes) for 6 hours (last arrival 12:00 noon) for a
  # total of 30 trains
  service.pattern <- make.service.pattern()
  new.arrivals <- service.pattern[[1]]
  train.types <- service.pattern[[2]]

  # Add each of the trains in the new service pattern to the schedule.
  # Because we care about arrival times the arithmetic is a bit more painful.
  for (i in 1:length(new.arrivals)) {
    arrival <- new.arrivals[i]
    train <- names(new.arrivals)[i]
    train.type <- train.types[i]
    schedule[train] <- schedule[train.type] + arrival - schedule[terminal, train.type]
  }

  write.csv(schedule[names(new.arrivals)], paste('sched', filename, sep = '-'))

  # Just the times, in minutes since midnight
  #schedule.times = schedule[names(schedule)[3:length(names(schedule))]]

  # Example: get the arrival times at any given station in human-readable
  # format.
  #format.minutes(schedule.times["South Station",])

  monte.carlo.pax(ntrials, sample.pax, new.arrivals, model.stations, terminal,
		  schedule, 
		  result.handler(filename, 232, names(new.arrivals)))
}

doit <- function (filename, pattern) {
  run.trials(all.stations = stations, 
	     stations.with.data = apply(boardings.ctps, 1,
	   		      	        function (row) !all(is.na(row))),
	     filename = filename, make.service.pattern = pattern,
	     ntrials = 250)
}

# message("4 tph, all local")
# message("")
# doit("4tph-local.csv", function () make.local.service(360, 720, 4))

# message("4 tph, alternating short and local")
# message("")
# doit("4tph-short.csv", function () make.short.service(360, 720, 4))

# message("5 tph, all local")
# message("")
# doit("5tph-local.csv", function () make.local.service(360, 720, 5))

# message("5 tph, alternating short and local")
# message("")
# doit("5tph-short.csv", function () make.short.service(360, 720, 5))

# message("6 tph, all local")
# message("")
# doit("6tph-local.csv", function () make.local.service(360, 720, 6))

# message("6 tph, alternative short and local")
# message("")
# doit("6tph-short.csv", function () make.short.service(360, 720, 6))

# Here's a more complicated service pattern:
#  alternating short turns and local service, 4 tph, during low-demand periods
#  (arbitrarily, 6a-7a and 10a-12n)
#  6 tph all-local service during peak (7a-10a)
# complicated.service <- function () {
#   early.t <- c(360,     375,     390,     405,     420)
#   early.s <- c('local', 'short', 'local', 'short', 'local')
#   rush.t <- (0:16 * 10) + 430
#   rush.s <- rep('local', length(rush.t))
#   late.t <- c(600,     615,     630,     645,     660,     675,     690,     705,     720)
#   late.s <- c('local', 'short', 'local', 'short', 'local', 'short', 'local', 'short', 'local')
#   t <- c(early.t, rush.t, late.t)
#   s <- c(early.s, rush.s, late.s)
#   names(t) <- paste('X', as.character(t), sep="")
#   return (list(t, s))
# }

# message("complicated service")
# message("")
# doit("complicated.csv", complicated.service)

# The biggest capacity crunch seems to be during rush right around
# 9:00, so let's try this service (all trains local):
#
# 6 tph 6:00-8:30 (16 trains)
# every 8 minutes from 8:40 to 9:12 (5 trains)
# 6 tph 9:20-10:00 (5 trains)
# 3 tph 10:20-12:00 (6 trains) and the rest of midday
#
rush.hour.push <- function () {
  rush.t <- (0:15 * 10) + 360
  rush.plus.t <- (0:4 * 8) + 520
  shoulder.t <- (0:4 * 10) + 560
  midday.t <- (0:5 * 20) + 620

  t <- c(rush.t, rush.plus.t, shoulder.t, midday.t)
  s <- rep('local', length(t))
  names(t) <- paste('X', as.character(t), sep="")
  return (list(t, s))
}

# message("rush-hour push")
# message("")
# doit("rush-hour-push.csv", rush.hour.push)

# message("crazy 12 tph all morning")
# message("")
# doit("12tph-local.csv", function () make.local.service(360,720,12))

# message("less crazy 12 tph local/short service")
# message("")
# doit("12tph-short.csv", function () make.short.service(360,720,12))

# message("10 tph all local")
# message("")
# doit("10tph-local.csv", function () make.local.service(360,720,10))

# message("7.5 tph (8-minute headways) all local")
# message("")
# doit("7.5tph-local.csv", function () make.local.service(360,720,7.5))

# Here's another somewhat complicated service pattern, although easier
# than the "rush-hour push", it tries to implement many of the same ideas
# in a form that's more implementable given current limitations.
#
# The base level of service is 4 trains per hour (15-minute headways).
# We add an additional 4 tph, for alternating 7- and 8-minute headways,
# between 7:00 and 9:30, then back to base level for the rest of the day.
# We're going to simulate two different versions of this service, as
# usual, one with all local service and one with short turns.  In
# addition, the first hour of service is always "short", because we
# want to start trains from Framingham to reduce cycle time (and
# those trains would be useful anyway, relative to operating costs,
# unlike a 4:02 departure from Worcester before the station is even open.
# This doesn't affect the simulation (because we have no early-morning
# passenger data) but makes the writeup easier.
#
#mixed.4.and.8.tph.local <- function () {
#  early.t <- (0:3 * 15) + 300
#  early.s <- rep('short', length(early.t))
#  shoulder.t <- (0:3 * 15) + 360
#  shoulder.s <- rep('local', length(shoulder.t))
#  rush.basic <- c(0, 8, 15, 22)
#  rush.t <- (rush.basic + c(rep(0, 4), rep(30, 4), rep(60, 4), rep(90, 4), rep(120, 4))) + 420
#  rush.s <- rep('local', length(rush.t))
#  late.t <- (0:11 * 15) + 570
#  late.s <- rep('local', length(late.t))
#
#  t <- c(early.t, shoulder.t, rush.t, late.t)
#  s <- c(early.s, shoulder.s, rush.s, late.s)
#  names(t) <- paste('X', as.character(t), sep="")
#  return (list(t, s))
#}
#
#doit("4+8tph-local.csv", mixed.4.and.8.tph.local)
#
#mixed.4.and.8.tph.short <- function () {
#  early.t <- (0:3 * 15) + 300
#  early.s <- rep('short', length(early.t))
#  shoulder.t <- (0:3 * 15) + 360
#  shoulder.s <- rep('local', length(shoulder.t))
#  rush.basic <- c(0, 8, 15, 22)
#  rush.t <- (rush.basic + c(rep(0, 4), rep(30, 4), rep(60, 4), rep(90, 4), rep(120, 4))) + 420
#  rush.s <- rep(c('local', 'short'), length(rush.t) %/% 2)
#  late.t <- (0:11 * 15) + 570
#  late.s <- rep('local', length(late.t))
#
#  t <- c(early.t, shoulder.t, rush.t, late.t)
#  s <- c(early.s, shoulder.s, rush.s, late.s)
#  names(t) <- paste('X', as.character(t), sep="")
#  return (list(t, s))
#}
#
#doit("4+8tph-short.csv", mixed.4.and.8.tph.short)
#
#mixed.4.and.8.tph.short.2 <- function () {
#  early.t <- (0:3 * 15) + 300
#  early.s <- rep('short', length(early.t))
#  shoulder.t <- (0:3 * 15) + 360
#  shoulder.s <- rep('local', length(shoulder.t))
#  rush.basic <- c(0, 8, 15, 22)
#  rush.t <- (rush.basic + c(rep(0, 4), rep(30, 4), rep(60, 4), rep(90, 4), rep(120, 4))) + 420
#  rush.s <- rep(c('short', 'local'), length(rush.t) %/% 2)
#  late.t <- (0:11 * 15) + 570
#  late.s <- rep('local', length(late.t))
#
#  t <- c(early.t, shoulder.t, rush.t, late.t)
#  s <- c(early.s, shoulder.s, rush.s, late.s)
#  names(t) <- paste('X', as.character(t), sep="")
#  return (list(t, s))
#}
#
#doit("4+8tph-short2.csv", mixed.4.and.8.tph.short.2)

# Generates a service pattern with alternating short-turn and
# zone express trains.  express.offset is the time offset between
# local and express trains -- must ensure conflict-free travel for
# both local and express (with either block gap maintenance or separate
# tracks).
make.zone.service <- function (start.time, end.time, local.tph, express.tph,
				express.offset) {
  builder <- function (tph) {
    interval <- 60 / tph
    n <- (end.time - start.time) %/% interval
    result <- (0:(n - 1) * interval) + start.time
    return (result)
  }
  v.local <- builder(local.tph)
  v.express <- builder(express.tph) + express.offset
  v <- sort(c(v.local, v.express))
  names(v) <- paste('X', as.character(v), sep="")
  return (list(v, rep(c('short', 'express'), length(v) %/% 2)))
}

zone.express.4.plus.2 <- function () make.zone.service(300, 720, 4, 2, 3)
zone.express.4.plus.4 <- function () make.zone.service(300, 720, 4, 4, 3)
message("4 local, 2 express")
doit("4+2tph-zone-express.csv", zone.express.4.plus.2)
message("4 local, 4 express")
doit("4+4tph-zone-express.csv", zone.express.4.plus.4)
