# mpi-trace

This repository utilizes the LLNL wrap utility to write a basic MPI trace wrapper that outputs plain-text traces of many MPI calls.
This is NOT a complete implementation of any version of the MPI standard.

## Usage

Navigate to the source directory:
```
$ cd trace-wrapper
```

Modify the settings in the top of ``mpi_trace.w`` for settings for debug output and file vs stdout trace reporting.

Edit the ``Makefile`` to customize your specific environment.
Build the tracing library:
```
$ make $mytarget
```

You should now have a ``.so`` in your current directory.
To utilize this tracing library, use ``LD_PRELOAD``:
```
$ srun --export=ALL,LD_PRELOAD=/path/to/your/mpi-trace.so ...
```
or
```
$ export LD_PRELOAD=/path/to/your/mpi-trace.so
```

## Configuration

There are two stages of configuration -- build time and run time.
At build time, you select whether to print output to stdout or write to a file, and whether to have debug print statements to stdout.
At run time, you can configure the exact path to place trace files (if writing to file) using the ``TRACE_FILE_PATH`` environment variable.
This defaults to ``/tmp``.

## Example output

Each MPI call has a slightly different output format due to what data is being reported. Here is an example line from ``MPI_Send``:
```
[Rank 0] MPI_Send started 1710506924.359159708, ended 1710506924.359272718 (elapsed 0.000113010), moved 1119008 bytes to receiver 4
```
Lines are printed chronologically, but will always contain the start & end time if additional sorting later is needed.


## Analysis

A number of analysis scripts to generate plots have been placed in the ``analysis`` directory. These are experimental and currently only support PT2PT MPI calls.
