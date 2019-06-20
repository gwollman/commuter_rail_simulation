# -*- r -*-

flirt.75m.seating <- 260
flirt.80m.seating <- 290 # just a guess: add 5m -> 6 rows -> 30 seats

#
# Load the 2018 CTPS data and transform it to make it slightly easier to
# work with.  This should all be encapsulated somehow, but I'm not much
# of an R programmer and I found it difficult enough to make even this
# work.
#
boardings.ctps <- read.csv("ps-boardings.csv", row.names = 2)
arrival.times.df <- read.csv("ps-arrival-times.csv")
stations <- rownames(boardings.ctps)
terminal <- stations[length(stations)]

#
# Train times are coded as minutes since midnight local time.
# These arrival times are for the Fall 2018 schedule, relevant to
# the CTPS data.  Subset the boardings data to just those trains
# whose arrival times we model.
#
arrival.times <- arrival.times.df$time_minutes
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
    if (is.na(time.in.minutes)) {
        return (NA)
    } else {
        return (paste(time.in.minutes %/% 60,
                      formatC(as.numeric(time.in.minutes %% 60),
                              format = "d", width = "2",
                              flag = "0"),
                      sep = ":"))
    }
} 

schedule.in.minutes <- function (schedule) {
    rv <- as.data.frame(lapply(schedule,
                               function (l) {
                                   sapply(l, function (s) { format.minutes(s) })
                               }))
    rownames(rv) <- rownames(schedule)
    return (rv)
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
  schedule <- read.csv('ps-schedule.csv')
  schedule <- schedule[c("station", "providence.local", "providence.diesel", "providence.express", "stoughton.local", "stoughton.900", "stoughton.902", "stoughton.904", "stoughton.906", "stoughton.908")]
  rownames(schedule) <- schedule$station
  schedule$local[1] = 0

  return (schedule)
}

# Generates a service pattern with a single service *service.name*
# repeated *tph* times per hour.  The default service is named 'local'
# but not every line has a service by that name.
make.simple.service <- function (start.time, end.time, tph,
		      	        service.name = 'local',
				train.prefix = 'X') {
  interval <- 60 / tph
  n <- (end.time - start.time) %/% interval
  v <- (0:(n - 1) * interval) + start.time
  names(v) <- paste(train.prefix, as.character(v), sep="")
  return (list(v, rep(service.name, n)))
}

# Generates a service pattern with two services alternating.  The
# parameter *train.prefix* can be a list of prefixes or a single string;
# if a list, the prefixes will be applied to the respective *service.names*.
make.short.service <- function (start.time, end.time, tph,
		      	        service.names = c('short', 'local'),
				train.prefix = c('X', 'Y')) {
  interval <- 60 / tph
  n <- (end.time - start.time) %/% interval
  # Number of trains must be even for this service pattern
  if (n %% 2 == 1) {
    n <- n + 1
  }
  v <- ceiling(0:(n - 1) * interval) + start.time
  names(v) <- paste(train.prefix, as.character(v), sep="")
  return (list(v, rep(service.names, n %/% 2)))
}

run.trials <- function(all.stations, stations.with.data, make.service.pattern,
	      	       filename, ntrials = 250, seating = flirt.75m.seating) {
  # Drop the terminal off the list because the end of the line can never
  # have any boardings
  model.stations <- all.stations[stations.with.data]
  terminal <- tail(all.stations, 1)

  schedule <- make.new.schedule()
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

  write.csv(schedule.in.minutes(schedule[names(new.arrivals)]),
            paste('sched', filename, sep = '-'))

  # Just the times, in minutes since midnight
  #schedule.times = schedule[names(schedule)[3:length(names(schedule))]]

  # Example: get the arrival times at any given station in human-readable
  # format.
  #format.minutes(schedule.times["South Station",])

  monte.carlo.pax(ntrials, sample.pax, new.arrivals, model.stations, terminal,
		  schedule, 
		  result.handler(filename, seating,
		  names(new.arrivals)))
}

doit <- function (filename, pattern, seating = flirt.75m.seating) {
  run.trials(all.stations = stations, 
	     stations.with.data = apply(boardings.ctps, 1,
	   		      	        function (row) !all(is.na(row))),
	     filename = filename, make.service.pattern = pattern,
	     ntrials = 250, seating = seating)
  NA
}

# Code for human-readable schedule display:
# x <- read.csv('sched-8tph-peak-zone-express.csv')
# rownames(x) <- x$X
# x[2:length(x)]

# First, let's resample the existing service.
make.existing.service <- function (providence.service, stoughton.service) {
  return (list(arrival.times,
	       ifelse(grepl("^V", trains), providence.service,
	              stoughton.service)))
}

#doit('existing.csv', function () make.existing.service('providence.diesel', 'stoughton.diesel'))

#doit('final.csv', function () make.short.service(300, 15*60, 8, 'providence.local', 'stoughton.local', c('V', 'T')), seating = flirt.80m.seating)

# This is a hand-hacked custom schedule that assumes current
# Amtrak schedules are fixed and current Stoughton service will
# continue to be provided by diesels (subject to some minor time shifts).
# Thus we can't use the more general mechanisms above to generate the schedule
# automatically based on desired headways.

# This schedule is trains every 15 minutes until 7:30, then every ten minutes
# until 8:30, then every 15 minutes until 9:30, then every half hour.

trans.arrivals <- c(300, 315, 330, 345, 360, 375, 390, 405, 
	            418, # Stoughton train 900
		    420, 435, 
		    443, # Stoughton train 902
		    450,
		    460,
		    470,
	       	    480, 490,
		    493, # express
		    500,
		    508, # Stoughton train 904, shifted 4 minutes earlier
		    510,
		    518, # express 
		    525, 540, 
		    548, # Stoughton train 906
		    555, 570,
		    593, # Stoughton train 908, shifted 3 minutes later
		    600, 630, 660, 690, 720)

names(trans.arrivals) <- c('V300', 'V315', 'V330', 'V345', 'V360', 'V375',
		           'V390', 'V405', 'T418', 'V420', 'V435', 'T443',
			   'V450', 'V460', 'V470', 'V480', 'V490', 'V493X',
			   'V500',
			   'T508', 'V510', 'V518X', 'V525',
			   'V540', 'T548', 'V555', 'V570', 'T593', 'V600',
			   'V630', 'V660', 'V690', 'V720')
trans.services <- c(rep('providence.local', 8), 'stoughton.900',
	            rep('providence.local', 2), 'stoughton.902',
		    rep('providence.local', 5), 'providence.express',
		    'providence.local', 'stoughton.904',
		    'providence.local', 'providence.express',
		    rep('providence.local', 2), 'stoughton.906',
		    rep('providence.local', 2), 'stoughton.908',
		    rep('providence.local', 5))

doit('plus-express.csv', function () list(trans.arrivals, trans.services),
			      seating = flirt.80m.seating)
