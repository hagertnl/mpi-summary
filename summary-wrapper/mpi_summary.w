
#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

double total_time = 0.0;

/* MPI_Init prints a banner ***************************************************/
{{fn foo MPI_Init}} {
  {{callfn}}
  int rank;
  PMPI_Comm_rank(MPI_COMM_WORLD, &rank);
  if (rank == 0) printf("MPI summarization enabled\n");
}
{{endfn}}

{{fn foo MPI_Finalize}} {
  int rank, nranks;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &nranks);

  double *rank_timings = (double*) malloc(nranks * sizeof(double));
  double *timing = (double*) malloc(sizeof(double));
  timing[0] = total_time;

  MPI_Gather(timing, 1, MPI_DOUBLE, rank_timings, 1, MPI_DOUBLE, 0, MPI_COMM_WORLD);

  if (rank == 0) {
    int i;
    int maxrank = 0;
    double maxtime = 0.0, sumtime = 0.0;
    for (i = 0; i < nranks; i++) {
      sumtime += rank_timings[i];
      if (rank_timings[i] > maxtime) {
        maxrank = i;
        maxtime = rank_timings[i];
      }
    }
    printf("MPI REPORT ------------------------\n");
    printf("Max time: %f s by rank %d\n",maxtime,maxrank);
    printf("Avg time: %f s\n",sumtime/(double) nranks);
    printf("END MPI REPORT --------------------\n");
  }

  {{callfn}}

  free(rank_timings);
  free(timing);
}
{{endfn}}


// Lastly, override all other calls to catch the calls we aren't tracing
{{fnall foo MPI_Init MPI_Finalize }} {
  struct timespec tstart={0,0}, tend={0,0};
  clock_gettime(CLOCK_REALTIME, &tstart);
  {{callfn}}
  clock_gettime(CLOCK_REALTIME, &tend);
  const double start_timestamp = (double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec;
  const double end_timestamp = (double)tend.tv_sec + 1.0e-9*tend.tv_nsec;
  total_time += (end_timestamp - start_timestamp);
}
{{endfnall}}
