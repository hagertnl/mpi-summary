#!/usr/bin/env python3

import sys

class TraceLine:

    def __init__(self, line, nranks=1):
        # Number of ranks (important for collectives)
        self.nranks = nranks;
        # Total number of bytes in the transaction
        self.bytes_total = 0
        # Total number of bytes sent
        self.bytes_sent = 0
        # Total number of bytes received
        self.bytes_recv = 0
        # Ranks that were sent bytes from current rank
        self.sent_to = {}
        # Ranks that sent bytes to current rank
        self.recv_from = {}
        # Rank that generated the message
        self.source = -1
        # Number of ranks in the call
        line_splt = line.split()
        mpi_op = line_splt[2]
        self.mpi_op_name = mpi_op
        self.start = float(line_splt[4].replace(',', ''))
        self.end = float(line_splt[6])
        if mpi_op == 'MPI_Send' or mpi_op == 'MPI_Isend':
            self.mpi_op_name = mpi_op
            self.sent_to[int(line_splt[14])] = int(line_splt[10])
            self.bytes_sent = int(line_splt[10])
            self.source = int(line_splt[1].replace(']', ''))
            self.bytes_total = self.bytes_sent
        elif mpi_op == 'MPI_Recv' or mpi_op == 'MPI_Irecv':
            self.mpi_op_name = mpi_op
            self.recv_from[int(line_splt[14])] = int(line_splt[10])
            self.bytes_recv = int(line_splt[10])
            self.source = int(line_splt[1].replace(']', ''))
            self.bytes_total = self.bytes_recv
        elif mpi_op == 'MPI_Sendrecv':
            # Column 10 for bytes sent, column 16 for bytes received
            self.mpi_op_name = mpi_op
            partner_rank = int(line_splt[14].replace(',', ''))
            self.sent_to[partner_rank] = int(line_splt[10])
            self.recv_from[partner_rank] = int(line_splt[16])
            self.bytes_sent = int(line_splt[10])
            self.bytes_recv = int(line_splt[16])
            self.source = int(line_splt[1].replace(']', ''))
            self.bytes_total = self.bytes_recv + self.bytes_sent
        #elif mpi_op == 'MPI_Alltoall':
            # Column 10 for byte count
            #self.mpi_op_name = mpi_op
            #self.source = int(line_splt[1].replace(']', ''))
            #if self.nranks == 1:
                #print('Warning: to accurately analyze collectives to MPI_COMM_WORLD, please set the "nranks" keyword argument.', file=sys.stderr)
            #if not line_splt[13] == 'MPI_COMM_WORLD':
                #print('Found Alltoall that is not in MPI_COMM_WORLD. Node-specific tracking will not be accurate.', file=sys.stderr)
                #print('ERROR: Alltoall to non-MPI_COMM_WORLD has not been implemented yet', file=sys.stderr)
                #self.bytes_sent = int(line_splt[10]) 
                #self.bytes_recv = int(line_splt[10])
            #else:
                #for i in range(0,self.nranks):
                    #if not i == self.source:
                        #self.sent_to[i] = int(line_splt[10])
                        #self.recv_from[i] = int(line_splt[10])
                #self.bytes_sent = int(line_splt[10]) * (self.nranks - 1)
                #self.bytes_recv = int(line_splt[10]) * (self.nranks - 1)
            #self.bytes_total = self.bytes_recv + self.bytes_sent
        #elif mpi_op == 'MPI_Allreduce':
            # Column 10 for byte count
            #self.mpi_op_name = mpi_op
            #self.source = int(line_splt[1].replace(']', ''))
            #if self.nranks == 1:
                #print('Warning: to accurately analyze collectives to MPI_COMM_WORLD, please set the "nranks" keyword argument.', file=sys.stderr)
            #if not line_splt[13] == 'MPI_COMM_WORLD':
                #print('Found Allreduce that is not in MPI_COMM_WORLD. Node-specific tracking will not be accurate.', file=sys.stderr)
                #print('ERROR: Allreduce to non-MPI_COMM_WORLD has not been implemented yet', file=sys.stderr)
            #else:
                #self.sent_to[0] = int(line_splt[10])
                #self.recv_from[0] = int(line_splt[10])
                #self.bytes_sent = int(line_splt[10])
                #self.bytes_recv = int(line_splt[10])
            #self.bytes_total = self.bytes_recv + self.bytes_sent
        #elif mpi_op == 'MPI_Alltoallv':
            # Column 10 for byte count
            #self.mpi_op_name = mpi_op
            #self.source = int(line_splt[1].replace(']', ''))
            #if self.nranks == 1:
                #print('Warning: to accurately analyze collectives to MPI_COMM_WORLD, please set the "nranks" keyword argument.', file=sys.stderr)
            #if not line_splt[13] == 'MPI_COMM_WORLD':
                #print('Found Alltoallv that is not in MPI_COMM_WORLD. Node-specific tracking will not be accurate.', file=sys.stderr)
                #print('ERROR: Alltoallv to non-MPI_COMM_WORLD has not been implemented yet', file=sys.stderr)
                #self.bytes_sent = int(line_splt[10]) 
                #self.bytes_recv = int(line_splt[10])
            #else:
                #for i in range(0,self.nranks):
                    #if not i == self.source:
                        #self.sent_to[i] = int(line_splt[10])
                        #self.recv_from[i] = int(line_splt[10])
            #self.bytes_sent = int(line_splt[10])
            #self.bytes_recv = int(line_splt[10])
            #self.bytes_total = self.bytes_recv + self.bytes_sent
