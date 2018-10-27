require './train_physics.rb'

SPEED_LIMIT_89 = 39.79          # 89 mi/h ~ 140 km/h
SPEED_LIMIT_79 = 35.32          # 79 mi/h ~ 130 km/h
SPEED_LIMIT_69 = 30.85          # 69 mi/h ~ 115 km/h
SPEED_LIMIT_65 = 29.06          # 65 mi/h
SPEED_LIMIT_59 = 26.38          # 59 mi/h

SCENARIOS = { "flirt200.tsv" => ClassSm5.new(1, 200),
	      "flirt500.tsv" => ClassSm5.new(2, 500),
	      "flirt800.tsv" => ClassSm5.new(3, 800),
              "loco500.tsv" => F40PHconsist.new(3, 500),
              "loco1600.tsv" => HSP46Consist.new(9, 1600, 0.5),
              "loco1600-nodwell.tsv" => HSP46Consist.new(9, 1600, 0.5) }

SCENARIOS.each do |file, model|
  model.show
  puts ""
  dwell_time = 
    if (model.is_a?(EMU))
      25
    else
      55
    end
  dwell_time = 0 if (file =~ /nodwell/)

  File.open(file, "w") do |fh|
    printit = Proc.new { |*args| fh.puts args.join("\t") }

    # West Station to Boston Landing
    model.simulate_startstop(SPEED_LIMIT_89, 7500 - 6200, &printit)
    model.simulate_dwell(dwell_time)

    # Boston Landing to Newtonville
    model.simulate_startstop(SPEED_LIMIT_89, 13300 - 7500, &printit)
    model.simulate_dwell(dwell_time)

    # Newtonville to West Newton
    model.simulate_startstop(SPEED_LIMIT_89, 15200 - 13300, &printit)
    model.simulate_dwell(dwell_time)

    # West Newton to Auburndale
    model.simulate_startstop(SPEED_LIMIT_89, 16900 - 15200, &printit)
    model.simulate_dwell(dwell_time)

    # Auburndale to Wellesley Farms
    model.simulate_startstop(SPEED_LIMIT_65, 20300 - 16900, &printit)
    model.simulate_dwell(dwell_time)

    # Wellesley Farms to Wellesley Hills
    model.simulate_startstop(SPEED_LIMIT_69, 21800 - 20300, &printit)
    model.simulate_dwell(dwell_time)

    # Wellesley Hills to Wellesley Square
    model.simulate_startstop(SPEED_LIMIT_69, 23800 - 21800, &printit)
    model.simulate_dwell(dwell_time)

    # Wellesley Square to Natick
    model.simulate_startstop(SPEED_LIMIT_79, 28500 - 23800, &printit)
    model.simulate_dwell(dwell_time)

    # Natick to West Natick
    model.simulate_startstop(SPEED_LIMIT_89, 32100 - 28500, &printit)
    model.simulate_dwell(dwell_time)

    # West Natick to Framingham
    model.simulate_startstop(SPEED_LIMIT_89, 34300 - 32100, &printit)
  end
end
