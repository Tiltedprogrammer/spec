// specialized naive
#include "match_wrappers.hpp"
#include "BenchKernels.hpp"


#include <iostream>
#include <cstdlib>
#include <cassert>

// CUDA runtime
#include <cuda_runtime.h>


#define CudaCheckError()    __cudaCheckError( __FILE__, __LINE__ )

inline void __cudaCheckError( const char *file, const int line )
{
    cudaError err = cudaGetLastError();
    if ( cudaSuccess != err )
    {
        fprintf( stderr, "cudaCheckError() failed at %s:%i : %s\n",
                 file, line, cudaGetErrorString( err ) );
        exit( -1 );
    }

    // More careful checking. However, this will affect performance.
    // Comment away if needed.
    err = cudaDeviceSynchronize();
    if( cudaSuccess != err )
    {
        fprintf( stderr, "cudaCheckError() with sync failed at %s:%i : %s\n",
                 file, line, cudaGetErrorString( err ) );
        exit( -1 );
    }
    return;
}

int main(int argc, char **argv)
{

    int* h_src = new int[2];
    int* h_clocks = new int[7];
    int* h_dst = new int[2];

    int* d_src;
    int* d_dst;
    int* d_clocks;

    cudaMalloc((void**)&d_src, 2 * sizeof(int));
    cudaMalloc((void**)&d_dst, 2 * sizeof(int));
    cudaMalloc((void**)&d_clocks, 7 * sizeof(int));

    h_src[0] = 33;
    h_src[1] = 34;

    cudaMemcpy(d_src,h_src,2 * sizeof(int),cudaMemcpyHostToDevice);
    set_const_mem(h_src,2);

    dim3 block;

    block.x = 1;

    dim3 grid;

    grid.x = 1;
    

    mini_kernel_wrap(grid,block,d_src,d_dst,d_clocks);

    cudaMemcpy(h_clocks,d_clocks,7 * sizeof(int),cudaMemcpyDeviceToHost);
    cudaMemcpy(h_dst,d_dst, 2 * sizeof(int),cudaMemcpyDeviceToHost);


    std::cout << "Clocks for global load/store" << h_clocks[0] << "\n";
    std::cout << "Clocks for L1 load/store" << h_clocks[1] << "\n";
    std::cout << "Clocks for Spec load/store" << h_clocks[2] << "\n";
    std::cout << "Clocks for const load/store" << h_clocks[3] << "\n";
    std::cout << "Clocks for const cache load/store" << h_clocks[4] << "\n";
    std::cout << "Clocks for shared load/store" << h_clocks[5] << "\n";
    
    assert(h_dst[0] == 34);
    assert(h_dst[1] == 14);
    
    cudaFree(d_dst);
    cudaFree(d_clocks);
    cudaFree(d_src);

    delete[] (h_src);
    delete[] (h_clocks);
    delete[] (h_dst);


    return 0;
}