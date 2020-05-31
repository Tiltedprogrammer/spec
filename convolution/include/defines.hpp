#ifndef DEFINES_HPP
#define DEFINES_HPP

//how many pixels an individual thread would proccess
#define ROW_RESULT_STEP 8

#define COL_RESULT_STEP 8

#define ITERATIONS ITERATIONS_CMAKE


#include <iostream>
#include <vector>
#include <math.h>
#include <string>

#define ITERATIONS ITERATIONS_CMAKE

#ifndef RUN
#ifdef BENCHMARK
#define RUN(kernel) \
    cudaEvent_t start, stop;\
    cudaEventCreate(&start);\
    cudaEventCreate(&stop);\
    kernel;\
    std::vector<float> times;\
    int iterations = ITERATIONS;\
    const char* s = getenv("ITERATIONS");\
    if(s) iterations = atoi(s);\
    for(int i = 0; i < iterations; i++){\
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
    avg /= iterations;\
    float dev = 0.0;\
    for(auto &n: times) dev += ((n - avg) * (n - avg));\
    if(iterations > 1){\
        dev = sqrt(dev / (iterations - 1));\
    }\
    std::cout << "Kernel runtime " << avg << " Std dev: " << dev << std::endl;\

#else

#define RUN(kernel) (kernel);

#endif
#endif

#endif