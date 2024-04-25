#!/usr/bin/env python3

import matplotlib.pyplot as plt
import matplotlib.axes as mplax
import numpy as np
import argparse
import os

from tracer_common import TraceLine


parser = argparse.ArgumentParser()

parser.add_argument('--rank', type=int, required=True, help='Rank to analyze.')
parser.add_argument('--prefix', type=str, default='./', help='Where to search for rank traces.')
parser.add_argument('--timestep', type=float, default=3.0, help='Level of granularity to discretize time.')
parser.add_argument('--exclude', type=str, default=[], action='append', help='MPI calls to exclude.')

args = parser.parse_args()

if not os.path.isfile(f'{args.prefix}/trace_{args.rank}.txt'):
    print(f'Could not find {args.prefix}/trace_{args.rank}.txt')
    exit(1)

total_mpi_time = 0.0
time_breakdown = {}

with open(f'{args.prefix}/trace_{args.rank}.txt', 'r') as in_f:
    for line in in_f:
        trace_obj = TraceLine(line)
        if trace_obj.mpi_op_name in args.exclude:
            continue
        else:
            if not trace_obj.mpi_op_name in time_breakdown.keys():
                time_breakdown[trace_obj.mpi_op_name] = 0
            total_mpi_time += (trace_obj.end - trace_obj.start)
            time_breakdown[trace_obj.mpi_op_name] += (trace_obj.end - trace_obj.start)

print('Timing Breakdown:')
for k in time_breakdown.keys():
    print(f'\t{k}: {time_breakdown[k]}')
print(f'Rank {args.rank} spent {total_mpi_time} seconds in MPI')
