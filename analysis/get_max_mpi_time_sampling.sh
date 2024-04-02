#!/bin/bash

usage_str="get_max_mpi_time_sampling.sh [args]\n\t--prefix PREFIX\n\t-n NSAMPLES"

# A few command-line args:
prefix=${PWD}
n_samples=200

while [[ $# -gt 0 ]]; do
    case $1 in
        --prefix)
            shift;
            prefix=$1
            shift
            ;;
        -n)
            shift;
            n_samples=$1
            shift
            ;;
        -h|--help)
            echo -e "Usage: $usage_str";
            exit 0;
            ;;
        -*|--*)
            echo "Unknown option: $1"
            echo -e "Usage: $usage_str"
            exit 1
            ;;
        *)
            echo "Unknown option: $1"
            echo -e "Usage: $usage_str"
            exit 1
            ;;
    esac
done

awk_script_name=/tmp/$USER-$(date +"%m-%dT%H.%M.%S")

echo '
BEGIN {
    sum_time=0.0;
    sum_bytes=0;
    count=0;
}

$3 ~ /^MPI_Send$/ {
    gsub("),", "")
    sum_time=sum_time+$9;
    sum_bytes=sum_bytes+$11;
    count=count+1;
}


END {
    print "TotalTime="sum_time", Count="count", TotalBytes="sum_bytes;
}
' > $awk_script_name

max_time=0
max_count=0
max_bytes=0
max_file=""

total_ranks=$(find ${prefix} -maxdepth 1 -name 'trace_*' -printf '.' | wc -m)
sample_files=$(python3 -c "import random; lst = list(range(1, $total_ranks)); random.shuffle(lst); print(' '.join([ f'${prefix}/trace_{num}.txt' for num in lst[0:${n_samples}] ]))")

for f in ${prefix}/trace_0.txt ${sample_files}; do
    output=$(awk -f $awk_script_name ${f})
    cur_time=$(echo $output | cut -d'=' -f2 | cut -d',' -f1)
    cur_count=$(echo $output | cut -d'=' -f3 | cut -d',' -f1)
    cur_bytes=$(echo $output | cut -d'=' -f4 | cut -d',' -f1)
    #if python3 -c "exit(0) if ($cur_time > $max_time) else exit(1)"; then
    if (( $(echo "$cur_time > $max_time" | bc -l) )); then
        #echo "$cur_time from $f is greater than $max_time. Updating..."
        max_time=$cur_time
        max_count=$cur_count
        max_bytes=$cur_bytes
        max_file=$f
    fi
done

rm $awk_script_name

echo "Max time $max_time from $max_file, count=$max_count, totalbytes=$max_bytes"
