#!/usr/bin/env python3

import matplotlib.pyplot as plt
import matplotlib.axes as mplax
import numpy as np
import argparse
import os

from tracer_common import TraceLine


parser = argparse.ArgumentParser()

parser.add_argument('--nodenumber', type=int, required=True, help='Node number (ie, 0, 1, 2, etc)')
parser.add_argument('--ranks-per-node', type=int, required=True, help='Ranks per node.')
parser.add_argument('--maxranks', type=int, required=True, help='Number of ranks in the run.')
parser.add_argument('--starttime', type=float, required=True, help='Start timestamp to search for rank traces.')
parser.add_argument('--endtime', type=float, required=True, help='Ending timestamp to search for rank traces.')
parser.add_argument('--prefix', type=str, default='./', help='Where to search for rank traces.')
parser.add_argument('--timestep', type=float, default=3.0, help='Level of granularity to discretize time.')
parser.add_argument('--exclude', type=str, default=[], action='append', help='MPI calls to exclude.')

args = parser.parse_args()

print(f"Looking for ranks {args.nodenumber * args.ranks_per_node}-{(args.nodenumber + 1) * args.ranks_per_node - 1} in prefix {args.prefix}")

ranks = list(range(args.nodenumber * args.ranks_per_node, (args.nodenumber + 1) * args.ranks_per_node))

for rank in ranks:
    if not os.path.isfile(f'{args.prefix}/trace_{rank}.txt'):
        print(f'Could not find {args.prefix}/trace_{rank}.txt')
        exit(1)

send_data_by_time = []
recv_data_by_time = []
index = []

index_spawner = args.starttime
while index_spawner < args.endtime:
    index.append(index_spawner)
    index_spawner += args.timestep
    send_data_by_time.append(0)
    recv_data_by_time.append(0)

current_time_bin = -1.0
cur_send = 0
cur_recv = 0

for rank in ranks:
    with open(f'{args.prefix}/trace_{rank}.txt', 'r') as in_f:
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
                        bytes_recv_map[i] += 1
                elif type(recv_from_rank) == int and not recv_from_rank in ranks:
                    time_bin = int((trace_obj.start - args.starttime) / args.timestep)
                    recv_data_by_time[time_bin] += 1
            # Add sent bytes:
            for sent_to_rank in trace_obj.sent_to.keys():
                if sent_to_rank == 'all':
                    for i in range(0, args.maxranks):
                        bytes_sent_map[i] += 1
                elif type(sent_to_rank) == int and not sent_to_rank in ranks:
                    time_bin = int((trace_obj.start - args.starttime) / args.timestep)
                    send_data_by_time[time_bin] += 1

for i in range(0, len(index)):
    send_data_by_time[i] = send_data_by_time[i] / args.timestep
    recv_data_by_time[i] = recv_data_by_time[i] / args.timestep

# Plot #########################################################################
plt.title(f'Bytes sent & received by node {args.nodenumber}', fontsize = 16)
# axis labels
plt.xlabel('Timestamp', fontsize = 12)
plt.ylabel('Messages/sec', fontsize = 12)

plt.grid(False)
#plt.axis(bounds_lst)
plt.scatter(index, send_data_by_time, s=12, label='Sent')
plt.scatter(index, recv_data_by_time, s=12, label='Received')
plt.legend()

# save figure to specified output filename
plt.savefig('node_injection_message_rate.png', dpi=300)
