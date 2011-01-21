#!/bin/sh

# Compute median
# Input and output are lines of form 'variable value'.
# Multiple lines with same variable represent different measurements.
# Replaces all the lines for a particular variable
# with one containing the median of all measurements for that variable.
median()
{
    # Sort first by variable name...
    sort | perl -e '
        sub report { 
            return if !@vals;
            # ... then sort all values for variable, and take the middle one.
            @sorted = sort { $a - $b; } @vals; 
            print $oldvar."\t".$sorted[@sorted/2]."\n";
            undef @vals;
        }
        while (<STDIN>) {
            ($var,$val)=split(" ");
            report() if ($var ne $oldvar);
            push(@vals, $val);
            $oldvar=$var;
        }
        report();
    '
}

# Show statistics over all results from this system
# Current directory must be this system's results dir
# with one subdirectory for each version of wine, and under that,
# one subdirectory per run
# Outputs:
# 1) one data.parsed and one median.parsed per wine version
# 2) Master output file, just all the median.parsed's concatenated
# together, but with one more column on the left for wine version
# Plus a .csv version of the master output file.
# FIXME: add min and max outputs, too

rm -f data.parsed median.parsed
for winever in `echo wine-*`
do
    (
    cd $winever
    if test `ls */*.parsed | wc -l` -gt 0
    then
        # Raw data
        cat */*.parsed > data.parsed
        # Median
        median < data.parsed > median.parsed
    fi
    )
    awk "{print \"$winever\", \$0}" < $winever/data.parsed >> data.parsed
    awk "{print \"$winever\", \$0}" < $winever/median.parsed >> median.parsed
done

exit 0
