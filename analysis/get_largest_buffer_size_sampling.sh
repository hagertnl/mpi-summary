#!/bin/bash

usage_str="get_largest_buffer_size_sampling.sh [args]\n\t--help\tprint help message\n\t--print-table\tprint data in LaTeX table format\n\t-n\tnumber of ranks to sample (default: 100)"

# A few command-line args:
print_table_format=0
# Default to sampling 100 ranks
n_sample=100

while [[ $# -gt 0 ]]; do
    case $1 in
        --print-table)
            print_table_format=1;
            shift;
            ;;
        -n)
            shift;
            n_sample=$1;
            shift;
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

total_ranks=$(find . -maxdepth 1 -name 'trace_*' -printf '.' | wc -m)

echo "Found $total_ranks trace files, sampling $n_sample of these"
[ "$total_ranks" == "0" ] && exit 1;

# We want to always look at rank 0, then randomly sample the other n-1 traces, and multiply that out to approximate the total load
sample_files=$(python3 -c "import random; lst = list(range(1, $total_ranks)); random.shuffle(lst); print(' '.join([ f'trace_{num}.txt' for num in lst[0:${n_sample}] ]))")
trace_files="trace_0.txt ${sample_files}"

echo "
BEGIN {
    sum=0.0;
    max=0.0;
    maxcall=\"\";
    sum_r0=0.0;
    max_r0=0.0;
    maxcall_r0=\"\";
}

\$0 ~ /MPI_Send_init/ {
    if (\$2 == \"0]\") {
        uniqcall_r0[\$3]++;
        callsizes_r0[\$3]+=\$14;
        sum_r0=sum_r0+\$14;
        if(\$14 > max_r0) {
            max_r0=\$14; maxcall_r0=\$3
        }
    } else {
        uniqcall[\$3]++;
        callsizes[\$3]+=\$14;
        sum=sum+\$14;
        if(\$14 > max) {
            max=\$14; maxcall=\$3
        }
    }
}

\$0 ~ /\[Rank 0\] MPI_Bcast/ {
    uniqcall_r0[\$3]++;
    callsizes_r0[\$3]+=\$11;
    sum_r0=sum_r0+\$11;
    if(\$11 > max_r0) {
        max_r0=\$11; maxcall_r0=\$3
    }
}

\$0 !~ /MPI_[I]?[Rr]ecv/ && \$0 !~ /Bcast/ && \$0 ~ /bytes/ {
    if (\$2 == \"0]\") {
        uniqcall_r0[\$3]++;
        callsizes_r0[\$3]+=\$11;
        sum_r0=sum_r0+\$11;
        if(\$11 > max_r0) {
            max_r0=\$11; maxcall_r0=\$3
        }
    } else {
        uniqcall[\$3]++;
        callsizes[\$3]+=\$11;
        sum=sum+\$11;
        if(\$11 > max) {
            max=\$11; maxcall=\$3
        }
    }
}


END {
    # The number of sampled files
    sampled_files=ARGC-2;
    # Extrapolate to the total number of files (minus rank 0)
    total_files=${total_ranks}-1

    # Extrapolate out to N-1
    sum=(sum/sampled_files)*total_files
    for(a in uniqcall) {
        callsizes[a] = (callsizes[a]/sampled_files) * total_files
        uniqcall[a] = (uniqcall[a]/sampled_files) * total_files
    }

    # Add in rank 0 stats as we print
    for(a in uniqcall) print \"Call=\"a\", count=\"uniqcall[a]\", totalbytes=\"callsizes[a];
    print \"TotalBytes=\"sum+sum_r0\", MaxBufSize=\"max\", MaxBufSizeCall=\"maxcall\", Nranks=${total_ranks}\";
}
" > $awk_script_name

awk -f $awk_script_name ${trace_files}

rm $awk_script_name
