# coding: utf-8
#
# This is a very simple physics simulator for trains.
#
# We model only straight-line continuous acceleration, with no
# consideration of drag or friction losses, nor curvature.  We
# do not consider braking -- depending on whether you're doing
# regenerative or dynamic or friction the parameters may be
# substantially similar or quite different.
#
# Trains are modeled as having a fixed power output P and mass m, with
# a maximum acceleration a_max (this can be deduced from the tractive
# effort by dividing by the mass of an unloaded train).  For
# convenience, all units are metric; output acceleration is in m/s^2,
# speed in m/s, and distance in m.  Power and mass are related; either
# kilowatts and tonnes or watts and kilograms can be used, but we use
# the former because the latter implies greater precision than we
# actually have.
#
# The model assumes that the train will accelerate at a constant rate
# from start until it reaches its peak output power, at which point
# the acceleration is P/mv as a consequence of the law of conservation
# of energy.  The actual acceleration curve is more complex: a diesel
# locomotive may have a very high starting tractive effort, but the
# continuous effort is typically much lower (and at a much lower rated
# speed).
#
# Conversion factors:
#   m to ft: divide by 0.3048
#   m to mi: divide by 1609.3
#   m/s to mi/h: multiply by 2.2369
#   m/s/s to ft/s/s: divide by 0.3048
#   lbf to N: multiply by 4.4482
#   lbm to kg: 0.4359
#   short ton to t: multiply by 0.9072
#   hp to kW: multiply by 0.7457
#

PASSENGER_MASS = 0.075          # t: 75 kg ~ 165 lb

class TrainPhysics
  def initialize(mass, power, a_max)

    # These are fixed parameters of the train
    @m = mass
    @p = power
    @k = power / mass
    @a_max = a_max
    @v_a_max = @k / a_max
    @t_a_max = @v_a_max / a_max

    # These are dynamic parameters of the accelerating train system
    @t = 0
    @v = 0
    @s = 0
  end

  #
  # Run the simulator
  # Specify a speed limit for the train (this will normally be
  # limited by track condition and stop spacing rather than the
  # motive power) 
  def simulate(v_max, s_max = nil, step = 1)
    while (@v < v_max and (s_max.nil? or @s < s_max))
      @t += step
      @s += @v * step
      a = if (@v <= @v_a_max)
            @a_max
          else
            (@k / @v)
          end
      @v += a * step
      yield @t, @s, @v, a
    end

    # No longer accelerating -- we have reached the speed limit
    unless s_max.nil?
      while (@s < s_max)
        @t += step
        @s += @v * step
        yield @t, @s, @v, 0
      end
    end
  end

  # Assumes that the deceleration curve is exactly symmetric
  # with the acceleration curve, which is not true in reality.
  # A better model would consider the type of braking system,
  # thermal limits that might cause one to switch from regen to friction,
  # leaves on the line, etc.
  def simulate_stop(step = 1)
    while (@v > 0)
      @t += step
      @s += @v * step
      a = if (@v <= @v_a_max)
            @a_max
          else
            @k / @v
          end

      # The train is going to stop, not reverse.
      if (a * step > @v)
        a = @v / step
        @v = 0
      else
        @v -= a * step
      end
      yield @t, @s, @v, -a
    end
  end

  def simulate_dwell(how_long)
    unless @v == 0
      raise RuntimeError, "can't dwell at speed"
    end

    @t += how_long
  end

  # Yes, I know this is a huge DRY failure, so sue me.
  def simulate_startstop(v_max, s_max, step = 1)
    s0 = @s
    next_stop = s0 + s_max

    yield @t, @s, @v, 0
    while @v < v_max and (@s + @s - s0) < next_stop
      @t += step
      @s += @v * step
      a = if (@v <= @v_a_max)
            @a_max
          else
            (@k / @v)
          end
      if (@v += a * step) > v_max
        @v = v_max
      end
      yield @t, @s, @v, a
    end

    if (@s + @s - s0) < next_stop
      puts "reached v_max at s = #{@s}, t = #{@t}, v = #{@v}"
    end
    decel_distance = @s - s0

    while (@s + decel_distance) < next_stop
      @t += step
      @s += @v * step
      yield @t, @s, @v, 0
    end

    simulate_stop {|*args| yield *args }
  end

  def show(fh = STDOUT)
    fh.puts "Mass: #{@m} tonnes"
    fh.puts "Power: #{@p} kW"
    fh.puts "Max continuous acceleration (a_max): #{@a_max} m/s/s"
    fh.puts "Max speed at a_max (v_a_max): #{@v_a_max} m/s"
    fh.puts "Time to reach v_a_max: #{@t_a_max} s"
  end

  attr_reader :t, :s, :v
end

class EMU < TrainPhysics
end

class DMU < TrainPhysics
end

class LocoHauled < TrainPhysics
end

# JKOY Class Sm5 data sheet:
# https://wwwstadlerrailcom-live-01e96f7.s3-eu-central-1.amazonaws.com/filer_public/01/79/0179dc1a-031a-4c65-98e7-0573f6c1e99b/fjoy0908e.pdf
#
# Using the "Maximum power at wheel" figure rather than continuous power
# here; whatever the duty cycle is, Alon Levy suggests that it's long
# enough not to affect the flat-land acceleration from a standing stop
# to reasonable speed limits, which is what we're modeling here.
# This version of the FLIRT is specified for 160 km/h ≅ 99 mi/h service
# speed.
#
# Vehicle mass is from Wikipedia, since the Stadler data sheet doesn't
# include it.
#
class ClassSm5 < EMU
  FLIRT_MASS  = 170.0           # t
  FLIRT_POWER = 2600.0          # kW
  FLIRT_SEATS = 250             # passengers
  FLIRT_A_MAX = 1.2             # m/s/s

  def initialize(trainsets, passengers)
    @trainsets = trainsets
    @passengers = passengers

    unloaded_mass = FLIRT_MASS * trainsets
    total_mass = unloaded_mass + PASSENGER_MASS * passengers

    # Data sheet "Max. acceleration (full load)" so let's believe them.
    super(total_mass, FLIRT_POWER * trainsets, FLIRT_A_MAX)
  end

  def show(fh = STDOUT)
    seated = @trainsets * FLIRT_SEATS
    if (@passengers > seated)
      fh.puts "#{@trainsets} FLIRT 75m EMUs with #{seated} passengers seated, #{@passengers - seated} standing"
    else
      fh.puts "#{@trainsets} FLIRT 75m EMUs with #{@passengers} passengers"
    end
    super(fh)
  end
end

# Other FLIRT data sheets:
# NSB version (105 m): https://wwwstadlerrailcom-live-01e96f7.s3-eu-central-1.amazonaws.com/filer_public/65/d7/65d73cab-ff99-4b8b-af00-6abe96e13179/fnsb1008e.pdf
# NS versions (63 and 81 m): https://wwwstadlerrailcom-live-01e96f7.s3-eu-central-1.amazonaws.com/filer_public/f8/54/f8545b2a-4d48-463b-a994-5921cf0fa0ac/f3nsreiz0715e.pdf
#
# Neither data sheet gives the unladen weight of the trainset, so we don't
# have enough information to drive the simulator yet.
#

class F40PHconsist < TrainPhysics
  # Figures from the first Google result for "F40PH tractive effort"
  F40PH_MASS  = 117.9           # t
  F40PH_POWER = 2237.1          # kW
  # Continuous tractive effort 38,240 lbf = 170.1 kN
  F40PH_A_MAX = 1.4427          # m/s/s

  # Based on the Bombardier bilevel, because I can't find the number
  # for an MBTA Kawasaki or Hyundai-Rotem bilevel
  COACH_MASS  = 50.0            # t
  COACH_SEATS = 175             # passengers

  def initialize(coaches, passengers)
    @coaches = coaches
    @passengers = passengers

    # We have to adjust mass and a_max by the passenger load.
    # Assumes same tractive effort, higher mass, so we can just
    # scale by (total_mass / mass).

    total_mass = F40PH_MASS + COACH_MASS * coaches + PASSENGER_MASS * passengers
    a_max = F40PH_A_MAX * (F40PH_MASS / total_mass)

    super(total_mass, F40PH_POWER, a_max)
  end

  def show(fh = STDOUT)
    seated = @coaches * COACH_SEATS
    if (@passengers > seated)
      fh.puts "F40PH locomotive and #{@coaches} bilevel coaches with #{seated} passengers seated, #{@passengers - seated} standing"
    else
      fh.puts "F40PH locomotive and #{@coaches} bilevel coaches with #{@passengers} passengers"
    end
    super(fh)
  end
end

class HSP46Consist < TrainPhysics
  # Unless otherwise specified, from MotivePower HSP46 data sheet
  HSP46_MASS  = 131.5           # t
  HSP46_POWER_MIN = 2600        # kW - range per Wikipedia
  HSP46_POWER_MAX = 3470        # kW - range per Wikipedia
  # Continuous tractive effort 78,000 lbf = 347.0 kN (at 13 mi/h)
  # Starting tractive effort 65,000 lbf = 284.19 kN
  # Use the former for most favorable comparison
  HSP46_A_MAX = 2.6377          # m/s/s
  # P/m ratio = 19.8 at high HEP load, 26.4 at low HEP load

  # Based on the Bombardier bilevel, because I can't find the number
  # for an MBTA Kawasaki or Hyundai-Rotem bilevel
  COACH_MASS  = 50.0            # t
  COACH_SEATS = 170             # passengers

  def initialize(coaches, passengers, hep_load = 0)
    @hep_load = hep_load
    power = HSP46_POWER_MAX - hep_load * (HSP46_POWER_MAX - HSP46_POWER_MIN)
    @coaches = coaches
    @passengers = passengers

    # We have to adjust mass and a_max by the passenger load.
    # Assumes same tractive effort, higher mass, so we can just
    # scale by (total_mass / mass).

    total_mass = HSP46_MASS + COACH_MASS * coaches + PASSENGER_MASS * passengers
    a_max = HSP46_A_MAX * (HSP46_MASS / total_mass)

    super(total_mass, power, a_max)
  end

  def show(fh = STDOUT)
    seated = @coaches * COACH_SEATS
    if (@passengers > seated)
      fh.puts "HSP46 locomotive and #{@coaches} bilevel coaches with #{seated} passengers seated, #{@passengers - seated} standing"
    else
      fh.puts "HSP46 locomotive and #{@coaches} bilevel coaches with #{@passengers} passengers"
    end
    fh.puts "HEP load factor: #{@hep_load}"
    super(fh)
  end
end

