set terminal postscript color "Helvetica" 16 portrait
set output 'commits.eps'
set style fill solid
set ylabel "Changes/year"
set yrange [2000:13000]
set size square 
plot "commits.dat" using 2: xtic(1) with histogram \
 title "Wine source code checkins per year"
