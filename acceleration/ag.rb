require './train_physics.rb'

SPEED_LIMIT_79 = 35.32          # 79 mi/h
STATIONS = [ "South Framingham", "Framingham State", "Tech Park",
	     "Southboro Center", "Marlboro/495", "Northboro Center",
	     "Northboro/290", "Clinton" ]
SEGMENTS = [ 1.86, 2.35, 2.42, 4.47, 3.41, 1.33, 7.85 ]

model = ClassSm5.new(1, 250)
model.show
puts ""

stations = STATIONS
File.open("ag-branch-79.tsv", "w") do |fh|
  printit = Proc.new { |*args| fh.puts args.join("\t") }
  last_station = stations.shift
  SEGMENTS.each do |distance|
    printf 'Leaving %s at %.0f s', last_station, model.t
    departure_time = model.t
    puts ''
    model.simulate_startstop(SPEED_LIMIT_79, distance * 1609, &printit)
    printf 'Arriving %s at %.0f s (travel time %.0f s)',
      last_station = stations.shift, model.t, model.t - departure_time
    puts ''
    model.simulate_dwell(25)
  end
end
