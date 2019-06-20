#!/usr/local/bin/gnuplot -persist
#
#    
#    	G N U P L O T
#    	Version 5.2 patchlevel 6    last modified 2019-01-01 
#    
#    	Copyright (C) 1986-1993, 1998, 2004, 2007-2018
#    	Thomas Williams, Colin Kelley and many others
#    
#    	gnuplot home:     http://www.gnuplot.info
#    	faq, bugs, etc:   type "help FAQ"
#    	immediate help:   type "help"  (plot window: hit 'h')
# set terminal wxt 0 enhanced
# set output
unset clip points
set clip one
unset clip two
set errorbars front 1.000000 
set border 31 front lt black linewidth 1.000 dashtype solid
set zdata 
set ydata 
set xdata time
set y2data 
set x2data 
set boxwidth
set style fill  empty border
set style rectangle back fc  bgnd fillstyle   solid 1.00 border lt -1
set style circle radius graph 0.02 
set style ellipse size graph 0.05, 0.03 angle 0 units xy
set dummy x, y
set format x "%H:%M" timedate
set format y "% h" 
set format x2 "% h" timedate
set format y2 "% h" 
set format z "% h" 
set format cb "% h" 
set format r "% h" 
set ttics format "% h"
set timefmt "%H:%M"
set angles radians
set tics back
set grid nopolar
set grid xtics nomxtics ytics nomytics noztics nomztics nortics nomrtics \
 nox2tics nomx2tics noy2tics nomy2tics nocbtics nomcbtics
set grid layerdefault   lt 0 linecolor 0 linewidth 0.500 dashtype solid,  lt 0 linecolor 0 linewidth 0.500 dashtype solid
unset raxis
set theta counterclockwise right
set style parallel front  lt black linewidth 2.000 dashtype solid
set key title "" center
set key fixed right top vertical Right noreverse enhanced autotitle nobox
set key noinvert samplen 4 spacing 1 width 0 height 0 
set key maxcolumns 0 maxrows 0
set key noopaque
unset key
unset label
unset arrow
set style increment default
unset style line
unset style arrow
set style histogram clustered gap 2 title textcolor lt -1
unset object
set style textbox transparent margins  1.0,  1.0 border  lt -1 linewidth  1.0
set offsets 0, 0, 0, 0
set pointsize 1
set pointintervalbox 1
set encoding default
unset polar
unset parametric
unset decimalsign
unset micro
unset minussign
set view 60, 30, 1, 1
set view azimuth 0
set rgbmax 255
set samples 100, 100
set isosamples 10, 10
set surface 
unset contour
set cntrlabel  format '%8.3g' font '' start 5 interval 20
set mapping cartesian
set datafile separator "	"
unset hidden3d
set cntrparam order 4
set cntrparam linear
set cntrparam levels auto 5 unsorted
set cntrparam firstlinetype 0
set cntrparam points 5
set size ratio 0 1,1
set origin 0,0
set style data linespoints
set style function lines
unset xzeroaxis
unset yzeroaxis
unset zzeroaxis
unset x2zeroaxis
unset y2zeroaxis
set xyplane relative 0.5
set tics scale  1, 0.5, 1, 1, 1
set mxtics default
set mytics default
set mztics default
set mx2tics default
set my2tics default
set mcbtics default
set mrtics default
set nomttics
set xtics border in scale 1,0.5 mirror norotate  autojustify
set xtics  norangelimit autofreq 
set ytics border in scale 1,0.5 mirror norotate  autojustify
set ytics  norangelimit 
set ytics   ("South Station" 0.00000, "Back Bay" 2.10000, "Ruggles" 4.00000, "Forest Hills" 8.30000, "Hyde Park" 13.5000, "Readville" 15.5000, "Route 128" 18.8000, "Canton Jct." 24.1000, "Sharon" 29.2000, "Mansfield" 40.0000, "Attleboro" 51.4000, "South Attleboro" 59.7000, "Providence" 70.1000)
set ztics border in scale 1,0.5 nomirror norotate  autojustify
set ztics  norangelimit autofreq 
set x2tics border in scale 1,0.5 nomirror norotate  autojustify
set x2tics  norangelimit autofreq 
unset y2tics
set cbtics border in scale 1,0.5 mirror norotate  autojustify
set cbtics  norangelimit autofreq 
set rtics axis in scale 1,0.5 nomirror norotate  autojustify
set rtics  norangelimit autofreq 
unset ttics
set title "Providence Line half-string diagram (Southbound trips only)" 
set title  font "" norotate
set timestamp bottom 
set timestamp "" 
set timestamp  font "" norotate
set trange [ * : * ] noreverse nowriteback
set urange [ * : * ] noreverse nowriteback
set vrange [ * : * ] noreverse nowriteback
set xlabel "Departure time" 
set xlabel  font "" textcolor lt -1 norotate
set x2label "" 
set x2label  font "" textcolor lt -1 norotate
set xrange [ * : * ] noreverse writeback
set x2range [ * : * ] noreverse writeback
set ylabel "Station" 
set ylabel  font "" textcolor lt -1 rotate
set y2label "" 
set y2label  font "" textcolor lt -1 rotate
set yrange [ * : * ] noreverse writeback
set y2range [ * : * ] noreverse writeback
set zlabel "" 
set zlabel  font "" textcolor lt -1 norotate
set zrange [ * : * ] noreverse writeback
set cblabel "" 
set cblabel  font "" textcolor lt -1 rotate
set cbrange [ * : * ] noreverse writeback
set rlabel "" 
set rlabel  font "" textcolor lt -1 norotate
set rrange [ * : * ] noreverse writeback
unset logscale
unset jitter
set zero 1e-08
set lmargin  -1
set bmargin  -1
set rmargin  -1
set tmargin  -1
set locale "C"
set pm3d explicit at s
set pm3d scansautomatic
set pm3d interpolate 1,1 flush begin noftriangles noborder corners2color mean
set pm3d nolighting
set palette positive nops_allcF maxcolors 0 gamma 1.5 color model RGB 
set palette rgbformulae 7, 5, 15
set colorbox default
set colorbox vertical origin screen 0.9, 0.2 size screen 0.05, 0.6 front  noinvert bdefault
set style boxplot candles range  1.50 outliers pt 7 separation 1 labels auto unsorted
set loadpath 
set fontpath 
set psdir
set fit brief errorvariables nocovariancevariables errorscaling prescale nowrap v5
GNUTERM = "wxt"
x = 0.0
## Last datafile plotted: "U665.dat"
plot "amtk2151.dat" using 3:2 title "Acela 2151" with linespoints lw 3, "amtk2153.dat" using 3:2 title "Acela 2153" with linespoints lw 3, "amtk95.dat" using 3:2 title "Reg'l 95" with linespoints lw 2, "903.dat" using 3:2 title "903", "amtk2155.dat" using 3:2 title "Acela 2155" with linespoints lw 3, "905.dat" using 3:2 title "905", "amtk171.dat" using 3:2 title "Reg'l 171" with linespoints lw 2, "907.dat" using 3:2 title "907", "amtk2159.dat" using 3:2 title "Acela 2159" with linespoints lw 3, "amtk93.dat" using 3:2 title "Reg'l 93" with linespoints lw 2, "909.dat" using 3:2 title "909", "amtk173.dat" using 3:2 title "Reg'l 173" with linespoints lw 2, "U305.dat" using 3:2 title "U305", "U320.dat" using 3:2 title "U320", "U335.dat" using 3:2 title "U335", "U350.dat" using 3:2 title "U350", "U380.dat" using 3:2 title "U380", "U395.dat" using 3:2 title "U395", "U410.dat" using 3:2 title "U410", "U440.dat" using 3:2 title "U440", "U455.dat" using 3:2 title "U455", "U470.dat" using 3:2 title "U470", "U485.dat" using 3:2 title "U485", "U500.dat" using 3:2 title "U500", "U515.dat" using 3:2 title "U515", "U545.dat" using 3:2 title "U545", "U560.dat" using 3:2 title "U560", "U605.dat" using 3:2 title "U605", "U635.dat" using 3:2 title "U635", "U665.dat" using 3:2 title "U665"
#    EOF
