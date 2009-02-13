set terminal postscript color "Helvetica" 16 portrait
set output 'jsbench.eps'
set logscale y
set style fill solid
set ylabel "Time (ms)"
set yrange [1000:110000]
set ytics (1000,2000,5000,10000,20000,50000,100000)
set size ratio 1
plot "jsbench.dat" using 2: xtic(1) with histogram \
 title "Sunspider benchmark - smaller is better"
