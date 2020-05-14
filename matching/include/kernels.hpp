#ifndef KERNELS_HPP
#define KERNELS_HPP

#include <iostream>
#include <vector>
#include <math.h>
#include <string>

#include "jitify.hpp"

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

#define ITERATIONS 20

#ifndef RUN
#ifdef BENCHMARK
#define RUN(kernel) \
    cudaEvent_t start, stop;\
    cudaEventCreate(&start);\
    cudaEventCreate(&stop);\
    kernel;\
    std::vector<float> times;\
    for(int i = 0; i < ITERATIONS; i++){\
        cudaEventRecord(start);\
        kernel;\
        cudaEventRecord(stop);\
        cudaEventSynchronize(stop);\
        float milliseconds = 0;\
        cudaEventElapsedTime(&milliseconds, start, stop);\
        times.push_back(milliseconds);\
    }\
    float avg = 0.0;\
    for(auto &n: times) avg += n;\
    avg /= ITERATIONS;\
    float dev = 0.0;\
    for(auto &n: times) dev += ((n - avg) * (n - avg));\
    dev = sqrt(dev / (ITERATIONS - 1));\
    std::cout << "Kernel runtime " << avg << " Std dev: " << dev << std::endl;\

#else

#define RUN(kernel) (kernel);

#endif
#endif

#include <vector>
#include <string>

void multipattern_match_const_wrapper(std::vector<std::string> vpatterns, std::string file_name,size_t size, size_t offset,int verbose,std::vector<std::pair<int,int>> &res ,int res_to_vec);

void multipattern_match_wrapper(std::vector<std::string> vpatterns, std::string file_name,long size, long offset,int verbose,std::vector<std::pair<int,int>> &res ,int res_to_vec);

void multipattern_match_shared_wrapper(std::vector<std::string> vpatterns, std::string file_name,long size, long offset,int verbose,std::vector<std::pair<int,int>> &res ,int res_to_vec);

void match_naive_wrapper(std::string pattern, std::string subject_string_filename, int nochunk, long size, long offset,int verbose);

void multipattern_match_texture_wrapper(std::vector<std::string> vpatterns, std::string subject_string_filename, long size, long offset,int verbose); //nochunk == 0 => nochunk

void multipattern_match_const_sizes_wrapper(std::vector<std::string> vpatterns, std::string file_name,long size, long offset,int verbose,std::vector<std::pair<int,int>> &res ,int res_to_vec);


void multipattern_match_const_unroll_wrapper(std::vector<std::string> vpatterns, std::string file_name,size_t size, size_t offset,int verbose,std::vector<std::pair<int,int>> &res ,int res_to_vec);

#endif