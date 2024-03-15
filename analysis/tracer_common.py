#!/usr/bin/env python3

class TraceLine:

    def __init__(self, line):
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
        self.source = -1
        self.mpi_op_name = 'NOT_SET'
        line_splt = line.split()
        mpi_op = line_splt[2]
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
