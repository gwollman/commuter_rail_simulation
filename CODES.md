I use the following prefixes to generate unique train numbers
for the various lines, in both legacy and new schedules:

A - Amtrak intercity
B - Greenbush outbound
C - Greenbush inbound
F - Franklin outbound
G - Franklin inbound
J - Plymouth/Kingston outbound
K - Plymouth/Kingston inbound
L - Middleboro/Lakeville outbound
M - Middleboro/Lakeville inbound
N - Needham outbound
O - Needham inbound
P - historic CSX prefix, used on Worcester line trains in both directions
Q - Readville outbound
R - Readville inbound
S - Stoughton outbound
T - Stoughton inbound
U - Providence outbound
V - Providence inbound
X - Worcester inbound
Y - Worcester outbound

Simulated train numbers are generated automatically from the scheduled
arrival time at the terminal station in minutes since midnight.  Actual
train numbers would likely be different.  Having a letter prefix ensures
that R treats these columns as text rather than numeric values.

This list covers South Side lines only; I'll have to assign a new set of
prefixes for North Side routes because there aren't enough letters to
account for all the branches.
