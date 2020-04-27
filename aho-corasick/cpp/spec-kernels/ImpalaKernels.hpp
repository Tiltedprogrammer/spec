#ifndef IMPALA_CORASICK_HPP
#define IMPALA_CORASICK_HPP

#include <iostream>
#include <vector>
#include <math.h>
#include <string>


#include <PFAC.h>

#include "PFAC_P.h"

// cuda jit library
#include "jitify.hpp"
// #include "cuda_runtime.h"

#define ITERATIONS 20
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


void impalaCorasickWrapper(dim3 grid, dim3 block, int* d_input_string, int* d_match_result, int input_size, int blocks_minus1,int n_hat);

void impalaNaiveWrapper(dim3 grid, dim3 block, unsigned char* d_input_string, int* d_match_result, int input_size);

void impalaNaiveOptWrapper(dim3 grid, dim3 block, int* d_input_string, int* d_match_result, int input_size,int blocks_minus1,int n_hat,int max_len);

void matchNaiveOptWrapper(dim3 grid, dim3 block,const char* d_patterns, int* p_sizes, int p_num, const int* d_input_string, int input_size, int n_hat, int num_blocks_minus1,int max_len, int* d_match_result);

void matchNaiveSpecManualOptWrapper(PFAC_handle_t handle, dim3 grid, dim3 block,const int* d_input_string, int input_size, int n_hat, int num_blocks_minus1, int* d_match_result);

void matchNaiveSpecManualOptNUWrapper(PFAC_handle_t handle,dim3 grid, dim3 block,const int* d_input_string, int input_size, int n_hat, int num_blocks_minus1, int* d_match_result);

void matchNaiveSpecManualOptNUBWWrapper(PFAC_handle_t handle,dim3 grid, dim3 block,const int* d_input_string, int input_size, int n_hat, int num_blocks_minus1, int* d_match_result);

void matchCorasickSpecWrapper(PFAC_handle_t handle,dim3 grid, dim3 block,const int* d_input_string, int input_size, int n_hat, int num_blocks_minus1, int* d_match_result);

#endif