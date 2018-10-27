require './train_physics.rb'

SPEED_LIMIT_99 = 44.26          # 99 mi/h ~ 160 km/h

SCENARIOS = { "flirt500-accel.tsv" => ClassSm5.new(2, 500),
              "loco500-accel.tsv" => F40PHconsist.new(3, 500),
              "loco1600.tsv" => HSP46Consist.new(9, 1600, 0.5) }

SCENARIOS.each do |file, model|
  model.show
  puts ""

  File.open(file, "w") do |fh|
    printit = Proc.new { |*args| fh.puts args.join("\t") }
    model.simulate(SPEED_LIMIT_99, &printit)
  end
end
