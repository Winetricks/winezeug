#!/bin/sh
# Quick and dirty script for plotting yagmark results
# And I do mean dirty.
set -e
set -x

. ./yagmark-vars

cd results

latest=`ls -d *Ubuntu*/stats.dat | sort -n -t- -k +7 | tail -n 1 | sed 's,/stats.dat,,'`
previous=`ls -d *Ubuntu*/stats.dat | sort -n -t- -k +7 | tail -n 2 | head -n 1 | sed 's,/stats.dat,,'`
vista=`ls -d *Vista*/stats.dat | sed 's,/stats.dat,,'`

latest_short=`echo $latest | sed 's/.*wine/wine/;s/-[^-]*$//'`
previous_short=`echo $previous | sed 's/.*wine/wine/;s/-[^-]*$//'`

compare()
{
  ref=$1
  ref_short=$2
  new=$3
  new_short=$4
  echo "Comparing $ref_short with $new_short"
  printf "%-36s %-14s %-14s %-14s\n" benchmark_variable	$ref_short	$new_short	ratio
  (
   join -t'	' $ref/stats.dat $new/stats.dat 
  ) | sed 's/_Detail//' | awk '{printf("%-36s %-14.2f %-14.2f %-14.2f\n", $1, $2, $3, $3/$2);}' 
} 

# Input: lines of form 
#     score dir-wine-1.1.44-22-checksum/filename
# Output: lines of form
#     2008-Jul-11-08:55:55 score
# FIXME: don't use local time
get_wine_date()
{
    sed 's, .*-wine-, wine-,' |     # remove systemname
    sed 's,/.*,,'        |     # remove filename
    while read line
    do
      set $line
      score=$1
      ver=$2
      echo -n "$score "
      (cd $WINEDIR
      git log -n 1 --date=local $ver ) |
      grep Date: |
      sed 's/Date: *[a-zA-Z]* *//' |
      sed 's/Jan/01/; s/Feb/02/; s/Mar/03/; s/Apr/04/; s/May/05/; s/Jun/06/; s/Jul/07/; s/Aug/08/; s/Sep/09/; s/Oct/10/; s/Nov/11/; s/Dec/12/;' |
      awk '{printf "%s-%s-%02d-%s\n", $4, $1, $2, $3}'
    done |
    awk '{print $2, $1}'
}


result="`echo "123 E8400-GT_220-Ubuntu_10.04_LTS-e8400-wine-1.1.44-104-g25d8616" | get_wine_date`"
if test "$result" != "2010-05-11-08:58:40 123"
then
    echo get_wine_date broken
    exit 1
fi

result="`echo "3364.1 E8400-GT_220-Ubuntu_10.04_LTS-e8400-wine-1.1.39-102-g25d8616/stats.dat" | get_wine_date`"
if test "$result" != "2010-05-11-08:58:40 3364.1"
then
    echo get_wine_date broke on 2nd test
    exit 1
fi

do_plot()
{
    varname=$1
    rm -f /tmp/yagplot*
    rm -f "$varname\.svg"
    SYSTEMID=`echo $latest | cut -d- -f1-4`
    # Format variable scores for plotting
    awk  '$1 == '\"$varname\"' { print $2, FILENAME}' $SYSTEMID*/stats.dat | get_wine_date | sort -k 1,8 > /tmp/yagplot-data
    if ! test -s /tmp/yagplot-data
    then
        echo "No $varname found in data"
        return
    fi

    min=`awk '{print $2}' < /tmp/yagplot-data | sort -n | head -n 1`
    sysprefix=`echo $SYSTEMID | cut -d- -f1-2`
    winprefix=`ls -d $sysprefix* | grep "Vista\|XP" | tail -n 1`
    case $winprefix in
    "")
        max=`awk '{print $2}' < /tmp/yagplot-data | sort -n | tail -n 1`
        reference=""
        ;;
     *)
        max=`awk  '$1 == '\"$varname\"' { print $2 }' $winprefix*/stats.dat`
        reference=", $max title \"$winprefix\" with lines"
        ;;
    esac
    count=`ls $SYSTEMID*/stats.dat | wc -l`
    first=`head -n 1 < /tmp/yagplot-data | cut -f1 -d" " `
    last=`tail -n 1 < /tmp/yagplot-data | cut -f1 -d" " `


    # Gnuplot script
    # FIXME: bring back reference line (removed during debugging)
cat > /tmp/yagplot-script << EOF
set terminal svg
set output "${SYSTEMID}-$varname.svg"
set title "${varname}"
set xdata time
set timefmt "%Y-%m-%d-%H:%M:%S"
set xtics font "Times-Roman, 8" 
set yrange [$min-400:$max+($max-$min)/2]
set autoscale
plot "/tmp/yagplot-data" using 1:2 title "$SYSTEMID" with linespoints
EOF
    # Work around bug in gnuplot where it dies if DISPLAY not set
    export GNUTERM=dumb
    gnuplot < /tmp/yagplot-script

    rm -f /tmp/yagplot-*
}

run_plot()
{
    for var in 3dmark06_3DMark_Score \
               3dmark2001_3DMark_Score \
               3dmark2000_3DMark_Result \
               heaven2_d3d9_FPS \
               heaven2_gl_FPS
    do
        do_plot $var
    done
}

gen_HTML()
{
    cat << EOF
<html>
<head>
<title>Yagmark Results for $latest_short</title>
</head>
<body>
<h1>Yagmark Results for $latest_short</h1>
<h2>vista and $previous_short vs $latest_short</h2>
<pre>
EOF
    join vista-vs-$latest_short.txt $previous_short-vs-$latest_short.txt |
      grep -v Comparing |
      awk '{printf("%-36s %-15s %-15s %-15s  %-15s %-15s %-15s\n",
                   $1, $2, $3, $4, $5, $6, $7);}'

    cat << EOF
</pre>

<h2>Graphs of key results across all versions</h2>
EOF

    for f in `ls $SYSTEMID-*.svg`
    do
        #echo "<object data=\"$f\" type=\"image/svg+xml\">" 
        echo "<img src=\"$f\">" 
    done
    cat << EOF
</body>
</html>
EOF

}

# Generate table of contents
gen_TOC()
{
    cat << EOF
<html>
<head>
<title>Yagmark Results Index</title>
</head>
<body>
<h1>Yagmark Results Index</h1>
<ul>
EOF

    ls *wine*html | sed 's,\(.*\),<li><a href="\1">\1</a></li>,'
    cat << EOF
</ul>
</body>
</html>
EOF

}

compare $vista vista $latest $latest_short > vista-vs-$latest_short.txt
compare $previous $previous_short $latest $latest_short > $previous_short-vs-$latest_short.txt
run_plot
gen_HTML > $SYSTEMID-$latest_short.html
gen_TOC > 00index.html
