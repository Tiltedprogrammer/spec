// specialized naive

#include <iostream>
#include <cstdlib>
#include <cassert>

// CUDA runtime
#include <cuda_runtime.h>

#define RUNTIME_ENABLE_JIT
// #include <anydsl_runtime.h>

// #include "kernel.inc"


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

// extern "C" void kernel(int*,int*,int);

__constant__ int mini_array [2];

__global__ void dummy_kernel(int* dst,int* clocks){
    
    int i;// = dst[0];
    int start,stop;
    int effect = mini_array[1]; //warm up cache
    dst[1] = effect;
    // start = clock();
    asm volatile("mov.u32 %0, %%clock;": "=r"(start) :: "memory");
    // asm volatile("st.global.u32 [%0], %1;": "=r"(clocks[0]) :"r"(start): "memory");
    
    asm volatile(
                //  "add.u32 %0, %1, 12;\n\t"
                "add.u32 %0, %1, %2;\n\t"
                //  "st.global.u32 [%1], 12;"
                //  :"=r"(i) :"r"(i): "memory");
                :"=r"(i) :"r"(i),"r"(mini_array[0]): "memory");
    asm volatile("mov.u32 %0, %%clock;": "=r"(stop) :: "memory");
    // asm volatile("st.global.u32 [%0], %1;": "=r"(clocks[1]) : "r"(stop): "memory");
    // dst[1] = effect;
    // stop = clock();
    clocks[0] = stop - start;
    dst[0] = i;
    // clocks[0] = stop - start;
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

__global__ void mini_register(int* src){
     
    int i = src[1];
    int j = src[0];
    
    asm volatile(
                 "add.u32 %0, %1, %2;\n\t"
                //  "st.global.u32 [%1], 12;"
                 :"=r"(i) :"r"(i), "r"(j): "memory");

    src[0] = i;
}

__global__ void mini_kernel_2(int* src, int* dst, int* clocks){
    

    int i = src[0];
    int start,stop;
    int effect = mini_array[1]; //warm up cache
    dst[1] = effect;
    
    asm volatile("mov.u32 %0, %%clock;": "=r"(start) :: "memory");
    
    // asm volatile(
    //              "shf.r.wrap.b32 %0, %0, 0, 2;\n\t"
    //             //  "st.global.u32 [%1], 12;"
    //              :"=r"(i) :"r"(i), "r"(mini_array[0]): "memory");
    asm volatile(
                 "div.u32 %0, %0, 4;\n\t"
                //  "st.global.u32 [%1], 12;"
                 :"=r"(i) :"r"(i), "r"(mini_array[0]): "memory");
    asm volatile("mov.u32 %0, %%clock;": "=r"(stop) :: "memory");
    
    clocks[1] = stop - start;
    dst[0] = i;
    // clocks[0] = stop - start;
}

void set_const_mem(int * host_mem, int size){
    cudaMemcpyToSymbol(mini_array, host_mem, size * sizeof(int));
}

void mini_kernel_wrap(dim3 grid,dim3 block,int* src, int* dst,int* clocks){
    dummy_kernel<<<1,1>>>(dst,clocks);
    // mini_kernel<<<grid,block>>>(src, dst, clocks);
    // mini_kernel_2<<<grid,block>>>(src, dst, clocks);
    // mini_register<<<grid,block>>>(src);
    
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

    h_src[0] = 16;
    h_src[1] = 34;

    cudaMemcpy(d_src,h_src,2 * sizeof(int),cudaMemcpyHostToDevice);
    set_const_mem(h_src,2);

    dim3 block;

    block.x = 1;

    dim3 grid;

    grid.x = 1;
    
    memset(h_clocks,0,7 * sizeof(int));

    mini_kernel_wrap(grid,block,d_src,d_dst,d_clocks);

    // std::string r_naive_spec;

    // r_naive_spec += "extern fn dummy(src: &[i32], dst : &mut[i32]) -> (){\n";

    // r_naive_spec += "  kernel(src,dst,2)}"; //;

    // std::string program = std::string((char*)kernel_impala) + r_naive_spec;
    // auto key = anydsl_compile(program.c_str(),program.size(),0);
    // typedef void (*function) (const int*, int *);
    // auto call = reinterpret_cast<function>(anydsl_lookup_function(key,"dummy"));
    
    // if (call == nullptr) {
    //     std::cout << "compiliacion failed\n";
    //     return;
    // } else {
    //     std::cout << "succesfully compiled\n";
    // }


    memset(h_clocks,0,7 * sizeof(int));
    // call(d_src,d_dst);

    // kernel(d_src,d_dst,2);

    cudaMemcpy(h_clocks,d_clocks,7 * sizeof(int),cudaMemcpyDeviceToHost);
    cudaMemcpy(h_dst,d_dst, 2 * sizeof(int),cudaMemcpyDeviceToHost);
    cudaMemcpy(h_src,d_src, 2 * sizeof(int),cudaMemcpyDeviceToHost);


    std::cout << "Clocks for global load/store " << h_clocks[0] << "\n";
    std::cout << "Clocks for L1 load/store " << h_clocks[1] << "\n";
    std::cout << "Clocks for Spec load/store " << h_clocks[2] << "\n";
    std::cout << "Clocks for const load/store " << h_clocks[3] << "\n";
    std::cout << "Clocks for const cache load/store " << h_clocks[4] << "\n";
    std::cout << "Clocks for shared load/store " << h_clocks[5] << "\n";
    
    std::cout << h_src[0] << std::endl;
    // assert(h_dst[0] == 33);
    // assert(h_dst[1] == 14);
    
    cudaFree(d_dst);
    cudaFree(d_clocks);
    cudaFree(d_src);

    delete[] (h_src);
    delete[] (h_clocks);
    delete[] (h_dst);


    return 0;
}