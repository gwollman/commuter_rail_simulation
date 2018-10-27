require './train_physics.rb'

SPEED_LIMIT_79 = 35.32          # 79 mi/h
SEGMENTS = [ 1.86, 2.35, 2.42, 4.47, 3.41, 1.33, 7.85 ]

model = ClassSm5.new(1, 250)
model.show
puts ""

File.open("ag-branch-79.tsv", "w") do |fh|
  printit = Proc.new { |*args| fh.puts args.join("\t") }

  SEGMENTS.each do |distance|
    model.simulate_startstop(SPEED_LIMIT_79, distance * 1609, &printit)
    model.simulate_dwell(25)
  end
end
