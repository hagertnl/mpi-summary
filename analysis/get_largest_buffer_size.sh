#!/bin/bash

usage_str="get_largest_buffer_size.sh [args]\n\t--help\tprint help message\n\t--print-table\tprint data in LaTeX table format"

# A few command-line args:
print_table_format=0

while [[ $# -gt 0 ]]; do
    case $1 in
        --print-table)
            print_table_format=1;
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

if [ "$print_table_format" == "0" ]; then
echo '
BEGIN {
    sum=0.0;
    max=0.0;
    maxcall="";
}

$0 ~ /MPI_Send_init/ {
    uniqcall[$3]++;
    callsizes[$3]+=$14;
    sum=sum+$14;
    if($14 > max) {
        max=$14; maxcall=$3
    }
}

$0 ~ /\[Rank 0\] MPI_Bcast/ {
    uniqcall[$3]++;
    callsizes[$3]+=$11;
    sum=sum+$11;
    if($11 > max) {
        max=$11; maxcall=$3
    }
}

$0 !~ /[Rr]ecv/ && $0 !~ /Bcast/ && $0 ~ /bytes/ {
    uniqcall[$3]++;
    callsizes[$3]+=$11;
    sum=sum+$11;
    if($11 > max) {
        max=$11; maxcall=$3
    }
}


END {
    for(a in uniqcall) print "Call="a", count="uniqcall[a]", totalbytes="callsizes[a];
    print "TotalBytes="sum", MaxBufSize="max", MaxBufSizeCall="maxcall", Nranks="ARGC-1;
}
' > $awk_script_name
else

echo '
BEGIN {
    sum=0.0;
    max=0.0;
    maxcall="";
}

$0 !~ /[Rr]ecv/ && $12 == "bytes" {
    uniqcall[$3]++;
    callsizes[$3]+=$11;
    sum=sum+$11;
    if($11 > max) {
        max=$11; maxcall=$3
    }
}

$0 ~ /MPI_Send_init/ && $15 == "bytes" {
    uniqcall[$3]++;
    callsizes[$3]+=$14;
    sum=sum+$14;
    if($14 > max) {
        max=$14; maxcall=$3
    }
}

END {
    print "\\begin{table}[!t]"
    print "\\begin{tabular}{|l|c|c|}"
    print "MPI Call & Count & TotalBytes \\\\"
    print "\\hline"
    print "\\hline"
    for(a in uniqcall) {
        print a" & "uniqcall[a]" & "callsizes[a]" \\\\";
        print "\\hline"
    }
    print "\\end{tabular}"
    print "\\caption{MAKE CAPTION}"
    print "\\label{tab:MAKE_LABEL}"
    print "\\end{table}"
    print "TotalBytes="sum", MaxBufSize="max", MaxBufSizeCall="maxcall", Nranks="ARGC-1;
}
' > $awk_script_name

fi

awk -f $awk_script_name trace_*.txt

rm $awk_script_name
