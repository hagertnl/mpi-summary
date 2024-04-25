#!/usr/bin/env python3

import matplotlib.pyplot as plt
import matplotlib.axes as mplax
import numpy as np
import argparse
import os

from tracer_common import TraceLine


parser = argparse.ArgumentParser()

parser.add_argument('--rank', type=int, required=True, help='Rank to generate plot for.')
parser.add_argument('--maxranks', type=int, required=True, help='Number of ranks in the run.')
parser.add_argument('--prefix', type=str, default='./', help='Where to search for rank traces.')
parser.add_argument('--starttime', type=float, default=-1, help='Start timestamp to search for rank traces.')
parser.add_argument('--endtime', type=float, default=-1, help='Ending timestamp to search for rank traces.')
parser.add_argument('--exclude', type=str, default=[], action='append', help='MPI calls to exclude.')
parser.add_argument('--count-only', action='store_true', help='If set, displays the count of MPI messages instead of bytes.')

args = parser.parse_args()

print(f"Looking for rank {args.rank} in prefix {args.prefix}")

if not os.path.isfile(f'{args.prefix}/trace_{args.rank}.txt'):
    print(f'Could not find {args.prefix}/trace_{args.rank}.txt')
    exit(1)

bytes_recv_map = [0] * args.maxranks
bytes_sent_map = [0] * args.maxranks

with open(f'{args.prefix}/trace_{args.rank}.txt', 'r') as in_f:
    for line in in_f:
        trace_obj = TraceLine(line)
        if trace_obj.mpi_op_name in args.exclude:
            continue
        elif args.starttime > 0 and trace_obj.start < args.starttime:
            continue
        elif args.endtime > 0 and trace_obj.end > args.endtime:
            continue
        # Add received bytes:
        for recv_from_rank in trace_obj.recv_from.keys():
            if recv_from_rank == 'all':
                for i in range(0, args.maxranks):
                    bytes_recv_map[i] += trace_obj.recv_from[recv_from_rank]
            elif type(recv_from_rank) == int:
                if not args.count_only:
                    bytes_recv_map[recv_from_rank] += trace_obj.recv_from[recv_from_rank]
                else:
                    bytes_recv_map[recv_from_rank] += 1
        # Add sent bytes:
        for sent_to_rank in trace_obj.sent_to.keys():
            if sent_to_rank == 'all':
                for i in range(0, args.maxranks):
                    bytes_sent_map[i] += trace_obj.sent_to[sent_to_rank]
            elif type(sent_to_rank) == int:
                if not args.count_only:
                    bytes_sent_map[sent_to_rank] += trace_obj.sent_to[sent_to_rank]
                else:
                    bytes_sent_map[sent_to_rank] += 1

index = list(range(0, args.maxranks))

max_size = 0
max_index = -1
min_size = 1e9
min_index = -1


for i in index:
    if bytes_sent_map[i] > max_size:
        max_size = bytes_sent_map[i]
        max_index = i
    if bytes_sent_map[i] < min_size:
        min_size = bytes_sent_map[i]
        min_index = i

print(f"Max index = {max_index}, max size = {max_size} bytes; Min index = {min_index}, min size = {min_size}")
    

# Plot #########################################################################
if not args.count_only:
    plt.title(f'Bytes sent & received for rank {args.rank}', fontsize = 24)
    # axis labels
    plt.xlabel('Rank number', fontsize = 16)
    plt.ylabel('Bytes', fontsize = 16)
else:
    plt.title(f'Message count sent & received for rank {args.rank}', fontsize = 24)
    # axis labels
    plt.xlabel('Rank number', fontsize = 16)
    plt.ylabel('Count', fontsize = 16)

plt.grid(False)
#plt.axis(bounds_lst)
plt.scatter(index, bytes_recv_map, s=12, label='Received', marker='o')
plt.scatter(index, bytes_sent_map, s=12, label='Sent', marker='x')
plt.legend()

# save figure to specified output filename
plt.savefig('rank_to_all.png', dpi=300)
