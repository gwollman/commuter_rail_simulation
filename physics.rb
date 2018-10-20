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

  def show(fh = STDOUT)
    fh.puts "Mass: #{@m} tonnes"
    fh.puts "Power: #{@p} kW"
    fh.puts "Max continuous acceleration (a_max): #{@a_max} m/s/s"
    fh.puts "Max speed at a_max (v_a_max): #{@v_a_max} m/s"
    fh.puts "Time to reach v_a_max: #{@t_a_max} s"
  end
end

# It would be interesting to do this simulation for a 100m
# FLIRT with three traction motors (3000 kW) but I don't have
# the details for these yet.
class FLIRT_75m_EMU < TrainPhysics
  FLIRT_MASS  = 170.0           # t
  FLIRT_POWER = 2000.0          # kW
  FLIRT_SEATS = 250             # passengers
  FLIRT_A_MAX = 1.02            # m/s/s

  def initialize(trainsets, passengers)
    @trainsets = trainsets
    @passengers = passengers

    # We have to adjust mass and a_max by the passenger load.
    # Assumes same tractive effort, higher mass, so we can just
    # scale by (total_mass / mass).

    unloaded_mass = FLIRT_MASS * trainsets
    total_mass = unloaded_mass + PASSENGER_MASS * passengers
    a_max = FLIRT_A_MAX * (unloaded_mass / total_mass)

    super(total_mass, FLIRT_POWER * trainsets, a_max)
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

DISTANCE = 5000                 # 5 km
SPEED_LIMIT = 35.32             # 79 mi/h

$flirt_500_pax = FLIRT_75m_EMU.new(2, 500)
$flirt_500_pax.show
puts ""

File.open("flirt500.tsv", "w") do |fh|
  $flirt_500_pax.simulate(SPEED_LIMIT, DISTANCE) {|*args| 
    fh.puts args.join("\t")
  }
end

$loco_500_pax = F40PHconsist.new(3, 500)
$loco_500_pax.show
puts ""

File.open("loco500.tsv", "w") do |fh|
  $loco_500_pax.simulate(SPEED_LIMIT, DISTANCE) {|*args| 
    fh.puts args.join("\t")
  }
end

$loco_monster = F40PHconsist.new(9, 1600)
$loco_monster.show
puts ""

File.open("loco1600.tsv", "w") do |fh|
  $loco_monster.simulate(SPEED_LIMIT, DISTANCE) {|*args| 
    fh.puts args.join("\t")
  }
end

