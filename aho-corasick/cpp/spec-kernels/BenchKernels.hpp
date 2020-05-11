#ifndef BK
#define BK

#include <cuda_runtime.h>


void mini_kernel_wrap(dim3 grid,dim3 block,int* src,int* dst, int* clocks);
void set_const_mem(int * host_mem, int size);

#endif