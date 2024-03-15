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
parser.add_argument('--timestep', type=float, default=0.1, help='Level of granularity to discretize time.')
parser.add_argument('--starttime', type=float, default=-1, help='Start timestamp to search for rank traces.')
parser.add_argument('--endtime', type=float, default=-1, help='Ending timestamp to search for rank traces.')
parser.add_argument('--exclude', type=str, default=[], action='append', help='MPI calls to exclude.')

args = parser.parse_args()

print(f"Looking for rank {args.rank} in prefix {args.prefix}")

if not os.path.isfile(f'{args.prefix}/trace_{args.rank}.txt'):
    print(f'Could not find {args.prefix}/trace_{args.rank}.txt')
    exit(1)

send_data_by_time = []
recv_data_by_time = []
index = []

current_time_bin = -1.0
cur_send = 0
cur_recv = 0

with open(f'{args.prefix}/trace_{args.rank}.txt', 'r') as in_f:
    for line in in_f:
        trace_obj = TraceLine(line)
        if trace_obj.mpi_op_name in args.exclude:
            continue
        elif args.starttime > 0 and trace_obj.start < args.starttime:
            continue
        elif args.endtime > 0 and trace_obj.end > args.endtime:
            continue
        if current_time_bin < 0:
            current_time_bin = trace_obj.start
        while (trace_obj.start - current_time_bin) > args.timestep:
            # Then dump the current data set
            send_data_by_time.append(cur_send)
            recv_data_by_time.append(cur_recv)
            index.append(current_time_bin)
            cur_send = 0
            cur_recv = 0
            current_time_bin += args.timestep
        # Add received bytes:
        for recv_from_rank in trace_obj.recv_from.keys():
            if recv_from_rank == 'all':
                for i in range(0, args.maxranks):
                    bytes_recv_map[i] += trace_obj.recv_from[recv_from_rank]
            elif type(recv_from_rank) == int:
                cur_recv += trace_obj.recv_from[recv_from_rank]
        # Add sent bytes:
        for sent_to_rank in trace_obj.sent_to.keys():
            if sent_to_rank == 'all':
                for i in range(0, args.maxranks):
                    bytes_sent_map[i] += trace_obj.sent_to[sent_to_rank]
            elif type(sent_to_rank) == int:
                cur_send += trace_obj.sent_to[sent_to_rank]

# Plot #########################################################################
plt.title(f'Bytes sent & received by time for rank {args.rank}', fontsize = 16)
# axis labels
plt.xlabel('Timestamp', fontsize = 12)
plt.ylabel('Bytes', fontsize = 12)

plt.grid(False)
#plt.axis(bounds_lst)
plt.scatter(index, send_data_by_time, s=12, label='Sent')
plt.scatter(index, recv_data_by_time, s=12, label='Received')
plt.legend()

# save figure to specified output filename
plt.savefig('message_size_trace.png', dpi=300)
