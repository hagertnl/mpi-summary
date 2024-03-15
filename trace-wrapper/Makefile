
CC ?= g++
CXX_FLAGS = -fPIC -std=c++14 -shared -O3 -Wall
MPICH_INC = -I${MPICH_DIR}/include
LINK = -L${MPICH_DIR}/lib -lmpi

dev: generate_wrap
	$(CC) $(CXX_FLAGS) $(MPICH_INC) -o test.so output.cpp $(LINK)

frontier_amd: generate_wrap
	amdclang++ $(CXX_FLAGS) $(MPICH_INC) -o mpi_trace_frontier.so output.cpp $(LINK)

frontier_cray: generate_wrap
	craycxx $(CXX_FLAGS) $(MPICH_INC) -o mpi_trace_frontier.so output.cpp $(LINK)

# mpicxx is fairly harmless. Cray wrappers add a bunch of junk, so we avoid those
summit: generate_wrap
	mpicxx $(CXX_FLAGS) -o mpi_trace_summit.so output.cpp

generate_wrap:
	../wrap.py -o output.cpp mpi_trace.w

clean:
	rm -f ./output.cpp
