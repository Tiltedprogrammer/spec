#include <iostream>
#include <cstdlib>
#include <cassert>

// CUDA runtime
#include <cuda_runtime.h>

#include "convolutionSeparable.hpp"
#include "convolutionSeparable255.hpp"
#include "convolutionSeparable127.hpp"
#include "convolutionSeparable63.hpp"
#include "convolutionSeparable31.hpp"
#include "convolutionSeparable15.hpp"
#include "convolutionSeparable_gold.hpp"

#include "defines.hpp"

// arg parsing
#include "../include/cxxopts.hpp"

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

int main(int argc, char ** argv){

    cxxopts::Options options("as", " - example command line options");
    options.add_options()("o,outfile","path to save convolved image",cxxopts::value<std::string>())
                         ("i,isize","size of the image to generate : isize x isize",cxxopts::value<int>())
                         ("s,fsize","size of the filter to convolve with",cxxopts::value<int>())
                         ("c,static","whether to use static filters or not : 0 for not, 1 is default",cxxopts::value<int>())
                         ("t,test","assert correctness of the filter",cxxopts::value<int>());



    auto result = options.parse(argc, argv);
    int flag = 0;
    int test = 0;
    int KERNEL_LENGTH = 3;
    int imageH = 0;
    int imageW = 0;
    if(result.count("fsize")){
        KERNEL_LENGTH = result["fsize"].as<int>();
        assert(KERNEL_LENGTH % 2 == 1);
    }else{
        std::cout << "filter size is required" << "\n";
        return 0;
    }

    int KERNEL_RADIUS = (KERNEL_LENGTH - 1) / 2;
    
    if(result.count("isize")){
        imageH = imageW = result["isize"].as<int>();
    }else{
        std::cout << "Input image size is required" << "\n";
        return 0;
    }

    if(result.count("static")){
        flag = result["static"].as<int>();
    }

    if(result.count("test")){
        test = result["test"].as<int>();
    }

    int iterations = 1;

    srand(200);
    
    float* h_Input;
        
    long size = imageH * imageW;
    h_Input = new float [size];
    for (long i = 0; i < imageW * imageH; i++) {
            h_Input[i] = (float)(rand() % 16);
    }

    std::cout << "image size is " << imageW << "x" << imageH <<"\n";

    float* h_Kernel = new float[KERNEL_LENGTH];
    
    float* h_Output = new float[imageW * imageH];

    float  *d_Input,
           *d_Buffer,
           *d_Output;
    
    for (unsigned int i = 0; i < KERNEL_LENGTH; i++) {
        
        h_Kernel[i] = (float)(rand() % 16);
        
    }

    size_t pitch;   

    cudaMallocPitch((void**)&d_Input,&pitch,imageW * sizeof(float),imageH);
    cudaMallocPitch((void**)&d_Buffer,&pitch,imageW * sizeof(float),imageH);
    cudaMallocPitch((void**)&d_Output,&pitch,imageW * sizeof(float),imageH);
    

    cudaMemcpy2D(d_Input, pitch, h_Input, imageW*sizeof(float), imageW*sizeof(float), imageH, cudaMemcpyHostToDevice);

    if(KERNEL_RADIUS == 15 && flag){
        setConvolutionKernel31(h_Kernel,KERNEL_LENGTH);
    
        {RUN(rowConvolve31(d_Buffer,d_Input,imageW,imageH, pitch / sizeof(float)))}

        {RUN(colConvolve31(d_Output,d_Buffer,imageW,imageH,pitch / sizeof(float)))}
    
        cudaDeviceSynchronize();
    
    }else if(KERNEL_RADIUS == 31 && flag){
        setConvolutionKernel63(h_Kernel,KERNEL_LENGTH);
    
        {RUN(rowConvolve63(d_Buffer,d_Input,imageW,imageH, pitch / sizeof(float)))}

        {RUN(colConvolve63(d_Output,d_Buffer,imageW,imageH,pitch / sizeof(float)))}
    
        cudaDeviceSynchronize();
    }else if(KERNEL_RADIUS == 7 && flag){
        setConvolutionKernel15(h_Kernel,KERNEL_LENGTH);
    
        {RUN(rowConvolve15(d_Buffer,d_Input,imageW,imageH, pitch / sizeof(float)))}

        {RUN(colConvolve15(d_Output,d_Buffer,imageW,imageH,pitch / sizeof(float)))}
    
        cudaDeviceSynchronize();
    }else if(KERNEL_RADIUS == 63 && flag){
        setConvolutionKernel127(h_Kernel,KERNEL_LENGTH);
    
        {RUN(rowConvolve127(d_Buffer,d_Input,imageW,imageH, pitch / sizeof(float)))}

        {RUN(colConvolve127(d_Output,d_Buffer,imageW,imageH,pitch / sizeof(float)))}
    
        cudaDeviceSynchronize();
    }else if(KERNEL_RADIUS == 127 && flag){
        setConvolutionKernel255(h_Kernel,KERNEL_LENGTH);
    
        {RUN(rowConvolve255(d_Buffer,d_Input,imageW,imageH, pitch / sizeof(float)))}

        {RUN(colConvolve255(d_Output,d_Buffer,imageW,imageH,pitch / sizeof(float)))}
    
        cudaDeviceSynchronize();
    }else {
        int blockX = 32;
        int blockY = 16;
        int halo = 1;
        if(KERNEL_RADIUS <= 31){
            blockX = 32;
            blockY = 16;
        }else if(KERNEL_RADIUS <= 63){
            halo = 2;
        }else if(KERNEL_RADIUS <= 127){
            halo = 4;
        }else {
            std::cout << "Too huge length, maximum supported is 255" << "\n";
            return 0;
        }
        setConvolutionKernel(h_Kernel,KERNEL_LENGTH);

        {RUN(rowConvolve(d_Buffer,d_Input,imageW,imageH, pitch / sizeof(float),KERNEL_RADIUS,blockX,blockY,8,halo))}

        {RUN(colConvolve(d_Output,d_Buffer,imageW,imageH,pitch / sizeof(float),KERNEL_RADIUS,blockY,blockX,8,halo))}
    

        cudaDeviceSynchronize();

        CudaCheckError();
        
    }

    

    cudaMemcpy2D(h_Output, imageW * sizeof(float), d_Output, pitch, imageW*sizeof(float), imageH, cudaMemcpyDeviceToHost);

    //gold

    if(test){
        float* h_OutputGold = new float[imageW * imageH];
        float* h_BufferGold = new float[imageW * imageH];

        convolutionRowCPU(h_BufferGold,h_Input,h_Kernel,imageW,imageH,(KERNEL_LENGTH - 1) /2);
        convolutionColumnCPU(h_OutputGold,h_BufferGold,h_Kernel,imageW,imageH,(KERNEL_LENGTH - 1) /2);

        for (long i = 0; i < imageH * imageW; i++) {
                assert(h_OutputGold[i] == h_Output[i]);
        }
        
        delete[] (h_OutputGold);
        delete[] (h_BufferGold);
    }

    delete[] (h_Input);
    delete[] (h_Kernel);
    delete[] (h_Output);
    
    cudaFree(d_Input);
    cudaFree(d_Buffer);
    cudaFree(d_Output);
}