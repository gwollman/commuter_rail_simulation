I use the following prefixes to generate unique train numbers
for the various lines, in both legacy and new schedules:

P - historic CSX prefix, used on Worcester line trains in both directions
X - simulated trains on Worcester Line eastbound
Y - simulated trains on Worcester Line westbound

Simulated train numbers are generated automatically from the scheduled
arrival time at the terminal station in minutes since midnight.  Actual
train numbers would likely be different.  Having a letter prefix ensures
that R treats these columns as text rather than numeric values.
