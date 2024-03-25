// LAMMPS requires Allgather, Allgatherv, Allreduce, Alltoall, Alltoallv, Sendrecv, Irecv, Send, and Wait

#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <vector>
#include <string>
#include <string.h>

// Set to 0 for using file I/O, set to 1 for print I/O
#define USE_STDIO 0
// Set to 0 for debugging output, set to 1 for no debugging output
#define DEBUG 1
// Set a default file location at build-time. Override with TRACE_FILE_PATH environment variable
static const std::string default_file_path = "/tmp";

// vector of results
std::vector<std::string> trace_buffer;
char tmp_trace_char[256];

static inline size_t get_mpi_type_size(MPI_Datatype datatype) {
  int local_size;
  MPI_Type_size(datatype, &local_size);
  if (local_size == MPI_UNDEFINED) {
    printf("I have no idea what size this datatype is\n");
    return -1;
  }
  return local_size;
}

/* MPI_Init prints a banner ***************************************************/
{{fn foo MPI_Init}} {
  {{callfn}}
  int rank;
  PMPI_Comm_rank(MPI_COMM_WORLD, &rank);
  if (rank == 0) printf("MPI TRACE enabled\n");
}
{{endfn}}

/* Trace each MPI_Send ********************************************************/
{{fn foo MPI_Send MPI_Isend}} {
  struct timespec tstart={0,0}, tend={0,0};
  clock_gettime(CLOCK_REALTIME, &tstart);
  {{callfn}}
  clock_gettime(CLOCK_REALTIME, &tend);
  const double start_timestamp = (double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec;
  const double end_timestamp = (double)tend.tv_sec + 1.0e-9*tend.tv_nsec;
  int rank;
  PMPI_Comm_rank(MPI_COMM_WORLD, &rank);
  // check if communicator is COMM_WORLD or not:
  int issame = -1;
  PMPI_Comm_compare(comm, MPI_COMM_WORLD, &issame);
  int global_dest = dest;
  if (issame == MPI_UNEQUAL) {
    MPI_Group grp_global, grp_local;
    PMPI_Comm_group(comm, &grp_local);
    PMPI_Comm_group(MPI_COMM_WORLD, &grp_global);
    PMPI_Group_translate_ranks(grp_local, 1, &dest, grp_global, &global_dest);
  }
#if USE_STDIO == 0
  memset(tmp_trace_char, 0, 256);
  snprintf(tmp_trace_char, 256, "[Rank %d] {{foo}} started %.9f, ended %.9f (elapsed %.9f), moved %zu bytes to receiver %d\n", rank,
            start_timestamp, end_timestamp, end_timestamp - start_timestamp,
            count * get_mpi_type_size(datatype), global_dest);
  trace_buffer.push_back(tmp_trace_char);
#else
  printf("[Rank %d] {{foo}} started %.9f, ended %.9f (elapsed %.9f), moved %zu bytes to receiver %d\n", rank,
            start_timestamp, end_timestamp, end_timestamp - start_timestamp,
            count * get_mpi_type_size(datatype), global_dest);
#endif
}
{{endfn}}

/* Trace each MPI_Recv ********************************************************/
{{fn foo MPI_Recv MPI_Irecv}} {
  struct timespec tstart={0,0}, tend={0,0};
  clock_gettime(CLOCK_REALTIME, &tstart);
  {{callfn}}
  clock_gettime(CLOCK_REALTIME, &tend);
  const double start_timestamp = (double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec;
  const double end_timestamp = (double)tend.tv_sec + 1.0e-9*tend.tv_nsec;
  int rank;
  PMPI_Comm_rank(MPI_COMM_WORLD, &rank);
  // check if communicator is COMM_WORLD or not:
  int issame = -1;
  PMPI_Comm_compare(comm, MPI_COMM_WORLD, &issame);
  int global_source = source;
  if (issame == MPI_UNEQUAL) {
    MPI_Group grp_global, grp_local;
    PMPI_Comm_group(comm, &grp_local);
    PMPI_Comm_group(MPI_COMM_WORLD, &grp_global);
    PMPI_Group_translate_ranks(grp_local, 1, &source, grp_global, &global_source);
    printf("Translated MPI rank number\n");
  }
#if USE_STDIO == 0
  memset(tmp_trace_char, 0, 256);
  snprintf(tmp_trace_char, 256, "[Rank %d] {{foo}} started %.9f, ended %.9f (elapsed %.9f), moved %zu bytes from source %d\n", rank,
            start_timestamp, end_timestamp, end_timestamp - start_timestamp,
            count * get_mpi_type_size(datatype), global_source);
  trace_buffer.push_back(tmp_trace_char);
#else
  printf("[Rank %d] {{foo}} started %.9f, ended %.9f (elapsed %.9f), moved %zu bytes from source %d\n", rank,
            start_timestamp, end_timestamp, end_timestamp - start_timestamp,
            count * get_mpi_type_size(datatype), global_source);
#endif
}
{{endfn}}

/* Trace each MPI_Sendrecv ****************************************************/
{{fn foo MPI_Sendrecv}} {
  struct timespec tstart={0,0}, tend={0,0};
  clock_gettime(CLOCK_REALTIME, &tstart);
  {{callfn}}
  clock_gettime(CLOCK_REALTIME, &tend);
  const double start_timestamp = (double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec;
  const double end_timestamp = (double)tend.tv_sec + 1.0e-9*tend.tv_nsec;
  int rank;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  // check if communicator is COMM_WORLD or not:
  int issame = -1;
  PMPI_Comm_compare(comm, MPI_COMM_WORLD, &issame);
  int global_dest = dest;
  if (issame == MPI_UNEQUAL) {
    MPI_Group grp_global, grp_local;
    PMPI_Comm_group(comm, &grp_local);
    PMPI_Comm_group(MPI_COMM_WORLD, &grp_global);
    PMPI_Group_translate_ranks(grp_local, 1, &dest, grp_global, &global_dest);
#if DEBUG == 0
    printf("Translated MPI rank number\n");
#endif
  }
#if USE_STDIO == 0
  memset(tmp_trace_char, 0, 256);
  snprintf(tmp_trace_char, 256, "[Rank %d] {{foo}} started %.9f, ended %.9f (elapsed %.9f), sending %zu bytes to dest %d, receiving %zu bytes\n", rank,
            start_timestamp, end_timestamp, end_timestamp - start_timestamp,
            sendcount * get_mpi_type_size(sendtype), global_dest, recvcount * get_mpi_type_size(recvtype));
  trace_buffer.push_back(tmp_trace_char);
#else
  printf("[Rank %d] {{foo}} started %.9f, ended %.9f (elapsed %.9f), sending %zu bytes to dest %d, receiving %zu bytes\n", rank,
            start_timestamp, end_timestamp, end_timestamp - start_timestamp,
            sendcount * get_mpi_type_size(sendtype), global_dest, recvcount * get_mpi_type_size(recvtype));
#endif
}
{{endfn}}

/* Trace each Scatter/Gather collectives **************************************/
{{fn foo MPI_Gather MPI_Scatter}} {
  struct timespec tstart={0,0}, tend={0,0};
  clock_gettime(CLOCK_REALTIME, &tstart);
  {{callfn}}
  clock_gettime(CLOCK_REALTIME, &tend);
  const double start_timestamp = (double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec;
  const double end_timestamp = (double)tend.tv_sec + 1.0e-9*tend.tv_nsec;
  int rank;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  // check if communicator is COMM_WORLD or not:
  int issame = -1;
  PMPI_Comm_compare(comm, MPI_COMM_WORLD, &issame);
  int global_root = root;
  std::string comm_name = "MPI_COMM_WORLD";
  if (issame == MPI_UNEQUAL) {
    int npcs;
    MPI_Comm_size(comm, &npcs);
    comm_name = "a sub-communicator with " + std::to_string(npcs) + " processes";
    MPI_Group grp_global, grp_local;
    PMPI_Comm_group(comm, &grp_local);
    PMPI_Comm_group(MPI_COMM_WORLD, &grp_global);
    PMPI_Group_translate_ranks(grp_local, 1, &root, grp_global, &global_root);
#if DEBUG == 0
    printf("Translated MPI rank number\n");
#endif
  }
#if USE_STDIO == 0
  memset(tmp_trace_char, 0, 256);
  snprintf(tmp_trace_char, 256, "[Rank %d] {{foo}} started %.9f, ended %.9f (elapsed %.9f), moved %zu bytes with root %d to %s\n", rank,
            start_timestamp, end_timestamp, end_timestamp - start_timestamp,
            sendcount * get_mpi_type_size(sendtype), global_root, comm_name.c_str());
  trace_buffer.push_back(tmp_trace_char);
#else
  printf("[Rank %d] {{foo}} started %.9f, ended %.9f (elapsed %.9f), moved %zu bytes with root %d\n", rank,
            start_timestamp, end_timestamp, end_timestamp - start_timestamp,
            sendcount * get_mpi_type_size(sendtype), global_root, comm_name.c_str());
#endif
}
{{endfn}}

/* Trace each Reduce/Bcast collectives ****************************************/
{{fn foo MPI_Reduce MPI_Bcast}} {
  struct timespec tstart={0,0}, tend={0,0};
  clock_gettime(CLOCK_REALTIME, &tstart);
  {{callfn}}
  clock_gettime(CLOCK_REALTIME, &tend);
  const double start_timestamp = (double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec;
  const double end_timestamp = (double)tend.tv_sec + 1.0e-9*tend.tv_nsec;
  int rank;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  // check if communicator is COMM_WORLD or not:
  int issame = -1;
  PMPI_Comm_compare(comm, MPI_COMM_WORLD, &issame);
  int global_root = root;
  std::string comm_name = "MPI_COMM_WORLD";
  if (issame == MPI_UNEQUAL) {
    int npcs;
    MPI_Comm_size(comm, &npcs);
    comm_name = "a sub-communicator with " + std::to_string(npcs) + " processes";
    MPI_Group grp_global, grp_local;
    PMPI_Comm_group(comm, &grp_local);
    PMPI_Comm_group(MPI_COMM_WORLD, &grp_global);
    PMPI_Group_translate_ranks(grp_local, 1, &root, grp_global, &global_root);
#if DEBUG == 0
    printf("Translated MPI rank number\n");
#endif
  }
#if USE_STDIO == 0
  memset(tmp_trace_char, 0, 256);
  snprintf(tmp_trace_char, 256, "[Rank %d] {{foo}} started %.9f, ended %.9f (elapsed %.9f), moved %zu bytes with root %d to %s\n", rank,
            start_timestamp, end_timestamp, end_timestamp - start_timestamp,
            count * get_mpi_type_size(datatype), global_root, comm_name.c_str());
  trace_buffer.push_back(tmp_trace_char);
#else
  printf("[Rank %d] {{foo}} started %.9f, ended %.9f (elapsed %.9f), moved %zu bytes with root %d to %s\n", rank,
            start_timestamp, end_timestamp, end_timestamp - start_timestamp,
            count * get_mpi_type_size(datatype), global_root, comm_name.c_str());
#endif
}
{{endfn}}

/* Trace each All* non-variable collective calls which have sendcount *********/
{{fn foo MPI_Alltoall MPI_Allgather}} {
  struct timespec tstart={0,0}, tend={0,0};
  clock_gettime(CLOCK_REALTIME, &tstart);
  {{callfn}}
  clock_gettime(CLOCK_REALTIME, &tend);
  const double start_timestamp = (double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec;
  const double end_timestamp = (double)tend.tv_sec + 1.0e-9*tend.tv_nsec;
  int rank;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  // check if communicator is COMM_WORLD or not:
  int issame = -1;
  PMPI_Comm_compare(comm, MPI_COMM_WORLD, &issame);
  std::string comm_name = "MPI_COMM_WORLD";
  if (issame == MPI_UNEQUAL) {
    int npcs;
    MPI_Comm_size(comm, &npcs);
    comm_name = "a sub-communicator with " + std::to_string(npcs) + " processes";
  }
#if USE_STDIO == 0
  memset(tmp_trace_char, 0, 256);
  snprintf(tmp_trace_char, 256, "[Rank %d] {{foo}} started %.9f, ended %.9f (elapsed %.9f), sent %zu bytes to %s\n", rank,
            start_timestamp, end_timestamp, end_timestamp - start_timestamp,
            sendcount * get_mpi_type_size(sendtype), comm_name.c_str());
  trace_buffer.push_back(tmp_trace_char);
#else
  printf("[Rank %d] {{foo}} started %.9f, ended %.9f (elapsed %.9f), sent %zu bytes to %s\n", rank,
            start_timestamp, end_timestamp, end_timestamp - start_timestamp,
            sendcount * get_mpi_type_size(sendtype), comm_name.c_str());
#endif
}
{{endfn}}

/* Trace each All* non-variable collective calls which have count *************/
{{fn foo MPI_Allreduce}} {
  struct timespec tstart={0,0}, tend={0,0};
  clock_gettime(CLOCK_REALTIME, &tstart);
  {{callfn}}
  clock_gettime(CLOCK_REALTIME, &tend);
  const double start_timestamp = (double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec;
  const double end_timestamp = (double)tend.tv_sec + 1.0e-9*tend.tv_nsec;
  int rank;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  // check if communicator is COMM_WORLD or not:
  int issame = -1;
  PMPI_Comm_compare(comm, MPI_COMM_WORLD, &issame);
  std::string comm_name = "MPI_COMM_WORLD";
  if (issame == MPI_UNEQUAL) {
    int npcs;
    MPI_Comm_size(comm, &npcs);
    comm_name = "a sub-communicator with " + std::to_string(npcs) + " processes";
  }
#if USE_STDIO == 0
  memset(tmp_trace_char, 0, 256);
  snprintf(tmp_trace_char, 256, "[Rank %d] {{foo}} started %.9f, ended %.9f (elapsed %.9f), sent %zu bytes to %s\n", rank,
            start_timestamp, end_timestamp, end_timestamp - start_timestamp,
            count * get_mpi_type_size(datatype), comm_name.c_str());
  trace_buffer.push_back(tmp_trace_char);
#else
  printf("[Rank %d] {{foo}} started %.9f, ended %.9f (elapsed %.9f), sent %zu bytes to %s\n", rank,
            start_timestamp, end_timestamp, end_timestamp - start_timestamp,
            count * get_mpi_type_size(datatype), comm_name.c_str());
#endif
}
{{endfn}}

/* Trace AlltoAllv variable collective call ***********************************/
{{fn foo MPI_Alltoallv}} {
  struct timespec tstart={0,0}, tend={0,0};
  clock_gettime(CLOCK_REALTIME, &tstart);
  {{callfn}}
  clock_gettime(CLOCK_REALTIME, &tend);
  const double start_timestamp = (double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec;
  const double end_timestamp = (double)tend.tv_sec + 1.0e-9*tend.tv_nsec;
  // Summarize the output with total & max (+max rank)
  int nranks;
  int rank;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(comm, &nranks);
  int i, max_rank_s = -1, max_rank_r = -1;
  size_t total_s = 0, max_size_s = 0;
  size_t total_r = 0, max_size_r = 0;
  for (i = 0; i < nranks; i++) {
    const size_t tmp_comp_s = sendcounts[i] * get_mpi_type_size(sendtype);
    const size_t tmp_comp_r = recvcounts[i] * get_mpi_type_size(sendtype);
    total_s += tmp_comp_s;
    total_r += tmp_comp_r;
    if (tmp_comp_s > max_size_s) {
      max_size_s = tmp_comp_s;
      max_rank_s = i;
    }
    if (tmp_comp_r > max_size_r) {
      max_size_r = tmp_comp_r;
      max_rank_r = i;
    }
  }
  // check if communicator is COMM_WORLD or not:
  int issame = -1;
  PMPI_Comm_compare(comm, MPI_COMM_WORLD, &issame);
  std::string comm_name = "MPI_COMM_WORLD";
  int max_rank_global_s = max_rank_s;
  int max_rank_global_r = max_rank_r;
  if (issame == MPI_UNEQUAL) {
    int npcs;
    MPI_Comm_size(comm, &npcs);
    comm_name = "a sub-communicator with " + std::to_string(npcs) + " processes";
    // translate max_rank, too
    MPI_Group grp_global, grp_local;
    PMPI_Comm_group(comm, &grp_local);
    PMPI_Comm_group(MPI_COMM_WORLD, &grp_global);
    PMPI_Group_translate_ranks(grp_local, 1, &max_rank_s, grp_global, &max_rank_global_s);
    PMPI_Group_translate_ranks(grp_local, 1, &max_rank_r, grp_global, &max_rank_global_r);
  }
#if USE_STDIO == 0
  memset(tmp_trace_char, 0, 256);
  snprintf(tmp_trace_char, 256, "[Rank %d] {{foo}} started %.9f, ended %.9f (elapsed %.9f), sent %zu bytes total, max of %zu to rank %d, received %zu bytes total, max of %zu from rank %d, to %s\n", rank,
            start_timestamp, end_timestamp, end_timestamp - start_timestamp,
            total_s, max_size_s, max_rank_global_s,
            total_r, max_size_r, max_rank_global_r, comm_name.c_str());
  trace_buffer.push_back(tmp_trace_char);
#else
  printf("[Rank %d] {{foo}} started %.9f, ended %.9f (elapsed %.9f), sent %zu bytes total, max of %zu to rank %d, received %zu bytes total, max of %zu from rank %d, to %s\n", rank,
            start_timestamp, end_timestamp, end_timestamp - start_timestamp,
            total_s, max_size_s, max_rank_global_s,
            total_r, max_size_r, max_rank_global_r, comm_name.c_str());
#endif
}
{{endfn}}

/* Trace AllGatherv variable collective call **********************************/
{{fn foo MPI_Allgatherv}} {
  struct timespec tstart={0,0}, tend={0,0};
  clock_gettime(CLOCK_REALTIME, &tstart);
  {{callfn}}
  clock_gettime(CLOCK_REALTIME, &tend);
  const double start_timestamp = (double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec;
  const double end_timestamp = (double)tend.tv_sec + 1.0e-9*tend.tv_nsec;
  int rank;
  MPI_Comm_rank(comm, &rank);
  // check if communicator is COMM_WORLD or not:
  int issame = -1;
  PMPI_Comm_compare(comm, MPI_COMM_WORLD, &issame);
  std::string comm_name = "MPI_COMM_WORLD";
  if (issame == MPI_UNEQUAL) {
    int npcs;
    MPI_Comm_size(comm, &npcs);
    comm_name = "a sub-communicator with " + std::to_string(npcs) + " processes";
  }
#if USE_STDIO == 0
  memset(tmp_trace_char, 0, 256);
  snprintf(tmp_trace_char, 256, "[Rank %d] {{foo}} started %.9f, ended %.9f (elapsed %.9f), sent %zu bytes to %s\n", rank,
            start_timestamp, end_timestamp, end_timestamp - start_timestamp,
            sendcount * get_mpi_type_size(sendtype), comm_name.c_str());
  trace_buffer.push_back(tmp_trace_char);
#else
  printf("[Rank %d] {{foo}} started %.9f, ended %.9f (elapsed %.9f), sent %zu bytes to %s\n", rank,
            start_timestamp, end_timestamp, end_timestamp - start_timestamp,
            sendcount * get_mpi_type_size(sendtype), comm_name.c_str());
#endif
}
{{endfn}}

/* Trace Calls without message sizes ******************************************/
{{fn foo MPI_Barrier}} {
  struct timespec tstart={0,0}, tend={0,0};
  clock_gettime(CLOCK_REALTIME, &tstart);
  {{callfn}}
  clock_gettime(CLOCK_REALTIME, &tend);
  const double start_timestamp = (double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec;
  const double end_timestamp = (double)tend.tv_sec + 1.0e-9*tend.tv_nsec;
  int rank;
  MPI_Comm_rank(comm, &rank);
#if USE_STDIO == 0
  memset(tmp_trace_char, 0, 256);
  snprintf(tmp_trace_char, 256, "[Rank %d] {{foo}} started %.9f, ended %.9f (elapsed %.9f)\n", rank,
            start_timestamp, end_timestamp, end_timestamp - start_timestamp);
  trace_buffer.push_back(tmp_trace_char);
#else
  printf("[Rank %d] {{foo}} started %.9f, ended %.9f (elapsed %.9f)\n", rank,
            start_timestamp, end_timestamp, end_timestamp - start_timestamp);
#endif
}
{{endfn}}

{{fn foo MPI_Wait}} {
  struct timespec tstart={0,0}, tend={0,0};
  clock_gettime(CLOCK_REALTIME, &tstart);
  {{callfn}}
  clock_gettime(CLOCK_REALTIME, &tend);
  const double start_timestamp = (double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec;
  const double end_timestamp = (double)tend.tv_sec + 1.0e-9*tend.tv_nsec;
  int rank;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
#if USE_STDIO == 0
  memset(tmp_trace_char, 0, 256);
  snprintf(tmp_trace_char, 256, "[Rank %d] {{foo}} started %.9f, ended %.9f (elapsed %.9f)\n", rank,
            start_timestamp, end_timestamp, end_timestamp - start_timestamp);
  trace_buffer.push_back(tmp_trace_char);
#else
  printf("[Rank %d] {{foo}} started %.9f, ended %.9f (elapsed %.9f)\n", rank,
            start_timestamp, end_timestamp, end_timestamp - start_timestamp);
#endif
}
{{endfn}}

#if USE_STDIO == 0
{{fn foo MPI_Finalize}} {
  int rank;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  {{callfn}}
  // Path for trace file is TRACE_FILE_PATH environment variable
  // Default is default_file_path
  std::string file_path = default_file_path;
  if (getenv("TRACE_FILE_PATH")) {
    file_path = getenv("TRACE_FILE_PATH");
#if DEBUG == 0
    printf("Found trace environment variable. Set file_path to %s\n", file_path.c_str());
#endif
  } else {
    file_path = default_file_path;
#if DEBUG == 0
    printf("TRACE_FILE_PATH not set. Using default of %s\n", default_file_path.c_str());
#endif
  }
  std::string f_name = file_path + "/trace_" + std::to_string(rank) + ".txt";
#if DEBUG == 0
  printf("Saving output from rank %d to file %s\n",rank,f_name.c_str());
#else
  if (rank == 0) printf("MPI TRACE: Saving output for each rank to %s\n",f_name.c_str());
#endif
  FILE *fp;
  fp = fopen(f_name.c_str(), "w");
  for (std::vector<std::string>::iterator t = trace_buffer.begin(); t != trace_buffer.end(); ++t) {
        fprintf(fp,"%s",t->c_str());
  }
}
{{endfn}}
#endif


// Lastly, override all other calls to catch the calls we aren't tracing
{{fnall foo MPI_Send MPI_Isend MPI_Recv MPI_Irecv MPI_Barrier MPI_Info_create MPI_Info_set MPI_Info_free MPI_File_open MPI_Comm_get_attr MPI_Comm_rank MPI_Comm_size MPI_Reduce MPI_Bcast MPI_Gather MPI_Scatter MPI_Wait MPI_Sendrecv MPI_Alltoall MPI_Allreduce MPI_Allgather MPI_Alltoallv MPI_Allgatherv MPI_Finalize MPI_Init MPI_Waitany MPI_Waitall MPI_Type_size MPI_Get_library_version MPI_Cart_create MPI_Cart_get MPI_Comm_free MPI_Comm_dup MPI_Cart_shift MPI_Cart_rank}} {
  {{callfn}}
#if DEBUG == 0
  printf("Warning: {{foo}} not traced.\n");
#else
  int rank;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  if (rank == 0) printf("Warning: {{foo}} not traced.\n");
#endif
}
{{endfnall}}
