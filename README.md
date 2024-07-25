# mpi-trace

This repository utilizes the LLNL wrap utility to write a basic MPI timing wrapper that outputs the number of seconds spent in MPI calls during a program's execution.
This is NOT a complete implementation of any version of the MPI standard.

## Usage

Navigate to the source directory:
```
$ cd summary-wrapper
```

Edit the ``Makefile`` to customize your specific environment.
Build the profiling library:
```
$ make $mytarget
```

For Frontier, `amd`, `cray`, and `gnu` targets have been provided.
An `mpicxx` target has been provided for non-Cray machines

You should now have ``libmpi_summary.so`` in your current directory.
To utilize this tracing library, use ``LD_PRELOAD``:
```
$ srun --export=ALL,LD_PRELOAD=/path/to/your/libmpi_summary.so ...
```
or
```
$ export LD_PRELOAD=/path/to/your/mpi_summary.so
```

## Example output

MPI time is printed at `MPI_Finalize`:

```
MPI REPORT ------------------------
Max time: 2.756765 s by rank 0
Avg time: 2.736936 s
END MPI REPORT --------------------
```
