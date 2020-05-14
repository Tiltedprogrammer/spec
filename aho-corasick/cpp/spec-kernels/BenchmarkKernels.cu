#include "../spec_match.hpp"
#include "BenchKernels.hpp"

__constant__ int mini_array [2];

__global__ void dummy_kernel(){
    
    int t_id = threadIdx.x;
    int i = 42;
}

__global__ void mini_kernel(int* src, int* dst, int* clocks){
    
    int t_id = blockIdx.x * gridDim.x + threadIdx.x;
    __shared__ int mini_shared [3];
    mini_shared[0] = 14;
    mini_shared[1] = 25;
    mini_shared[2] = 44;
    
    clock_t start,end;
    start = clock();
    
    int val = src[t_id]; //load from global
    dst[t_id] = val; //write to global

    end = clock();

    clocks[t_id] = (int)(start - end); //takes 634 cycles
    int next = t_id + 1;

    start = clock();
    
    int val2 = src[next]; //should be from L1
    dst[t_id] = val2; //should be to L1
    
    end = clock();

    clocks[t_id + 1] = (int)(start - end); //takes 76 cycles

    start = clock();
    
    dst[t_id] = 42; //to L1
    
    end = clock();  
    clocks[t_id + 2] = (int)(start - end); //takes 54 cycles

    start = clock();
    dst[t_id] = mini_array[0]; //load from const
    end = clock();
    clocks[t_id + 3] = (int)(start - end); //takes 54 cycles

    start = clock();
    dst[t_id] = mini_array[1]; //load from const cache
    end = clock();
    clocks[t_id + 4] = (int)(start - end); //takes 54 cycles

    start = clock();
    dst[t_id + 1] = mini_shared[0]; //load from shared
    end = clock();
    clocks[t_id + 5] = (int)(start - end); //takes 54 cycles

}

__global__ void mini_kernel_2(int* src, int* dst, int* clocks){

    int t_id = blockIdx.x * gridDim.x + threadIdx.x;

    int val1,val2,val3;
    val1 = 42; //
    val2 = src[t_id]; // L1 miss
    val3 = src[t_id + 1]; //L1

    dst[t_id] = val3;
}

void set_const_mem(int * host_mem, int size){
    cudaMemcpyToSymbol(mini_array, host_mem, size * sizeof(int));
}

void mini_kernel_wrap(dim3 grid,dim3 block,int* src, int* dst,int* clocks){
    dummy_kernel<<<1,1>>>();
    mini_kernel_2<<<grid,block>>>(src, dst, clocks);
    mini_kernel<<<grid,block>>>(src, dst, clocks);
}