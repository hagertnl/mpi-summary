
CC ?= CC
CXX_FLAGS = -fPIC -std=c++14 -shared -O3 -Wall
MPICH_INC = -I${MPICH_DIR}/include
LINK = -L${MPICH_DIR}/lib -lmpi

generic: generate_wrap
	$(CC) $(CXX_FLAGS) $(MPICH_INC) -o libmpi_summary.so output.cpp $(LINK)

amd: generate_wrap
	amdclang++ $(CXX_FLAGS) $(MPICH_INC) -o libmpi_summary.so output.cpp $(LINK)

cray: generate_wrap
	craycxx $(CXX_FLAGS) $(MPICH_INC) -o libmpi_summary.so output.cpp $(LINK)

gnu: generate_wrap
	g++ $(CXX_FLAGS) $(MPICH_INC) -o libmpi_summary.so output.cpp $(LINK)

# mpicxx is fairly harmless. Cray wrappers add a bunch of junk, so we avoid those
mpicxx: generate_wrap
	mpicxx $(CXX_FLAGS) -o libmpi_summary.so output.cpp

generate_wrap:
	python3 ../wrap/wrap.py -o output.cpp mpi_summary.w

clean:
	rm -f ./output.cpp
