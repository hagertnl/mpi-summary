#!/bin/bash

awk_script_name=/tmp/$USER-$(date +"%m-%dT%H.%M.%S")

echo '
BEGIN {
    sum=0.0;
    max=0.0;
    maxcall="";
}

$12 == "bytes" && $3 != "MPI_Irecv" && $3 != "MPI_Recv" {
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

awk -f $awk_script_name trace_*.txt

rm $awk_script_name
