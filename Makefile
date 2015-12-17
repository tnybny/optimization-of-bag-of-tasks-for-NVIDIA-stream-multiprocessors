EXECUTABLE      := p3

INCLUDES  += -I. -I/usr/local/cuda-7.5/include

CUDA_ARCH := -gencode arch=compute_20,code=sm_20 \
-gencode arch=compute_20,code=sm_21 \
-gencode arch=compute_30,code=sm_30 \
-gencode arch=compute_35,code=sm_35 \
-gencode arch=compute_50,code=sm_50
CUDA_PATH       ?= /usr/local/cuda-7.5
HOST_COMPILER ?= g++
NVCC          := $(CUDA_PATH)/bin/nvcc -ccbin $(HOST_COMPILER) $(INCLUDES) -arch=sm_35 $(CUDA_ARCH)

all:
	$(NVCC) -g -G p3.c scheduler.cu -o $(EXECUTABLE)

clean:
	rm -f *.o $(EXECUTABLE)

