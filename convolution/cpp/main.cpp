#include <iostream>
#include <cstdlib>
#include <cassert>

// CUDA runtime
#include <cuda_runtime.h>

#define cimg_use_jpeg

#include "../cimg/CImg-2.8.3/CImg.h"
#include "convolutionSeparable.hpp"
#include "convolutionSeparable255.hpp"
#include "convolutionSeparable127.hpp"
#include "convolutionSeparable63.hpp"
#include "convolutionSeparable31.hpp"
#include "convolutionSeparable15.hpp"
#include "convolutionSeparable_gold.hpp"

#include "defines.hpp"


int main(int argc, char ** argv){

    if (argc < 5) {
        std::cout << "Image path and #iterations required" << "\n";
        return 0;
    }
    int flag = std::atoi(argv[4]);
    int KERNEL_LENGTH = std::atoi(argv[3]);
    assert(KERNEL_LENGTH % 2 == 1);
    int KERNEL_RADIUS = (KERNEL_LENGTH - 1) / 2;
    std::string img_path(argv[1]);
    int iterations = std::atoi(argv[2]);
    std::cout << "# of iterations set to " << iterations << "\n";
    // cimg_library::CImg<float> img1("/home/alekseytyurinspb_gmail_com/specialization/spec/convolution/images/graytussaint100.jpg");
    cimg_library::CImg<float> img1(img_path.c_str());

    float* h_Kernel = new float[KERNEL_LENGTH];
    
    float* h_Output = new float[img1.width() * img1.height()];
    float* h_OutputGold = new float[img1.width() * img1.height()];
    float* h_BufferGold = new float[img1.width() * img1.height()];

    float  *d_Input,
           *d_Buffer,
           *d_Output;

    srand(200);
    
    for (unsigned int i = 0; i < KERNEL_LENGTH; i++) {
        
        h_Kernel[i] = (float)(rand() % 16);
        
    }

    // for (unsigned int i = 0; i < KERNEL_LENGTH; i++) {
    //     h_Kernel[i] /= sum;
    // }

    for (int i = 0; i < KERNEL_LENGTH; i++) {
        std::cout << h_Kernel[i] << " ";
    }
    std::cout << "\n";

    size_t pitch;
    cudaMallocPitch((void**)&d_Input,&pitch,img1.width() * sizeof(float),img1.height());
    cudaMallocPitch((void**)&d_Buffer,&pitch,img1.width() * sizeof(float),img1.height());
    cudaMallocPitch((void**)&d_Output,&pitch,img1.width() * sizeof(float),img1.height());
    

    cudaMemcpy2D(d_Input, pitch, img1.data(), img1.width()*sizeof(float), img1.width()*sizeof(float), img1.height(), cudaMemcpyHostToDevice);

    if(KERNEL_RADIUS == 15 && flag){
        setConvolutionKernel31(h_Kernel,KERNEL_LENGTH);

        for (int j = 0; j < iterations; j++) {
    
            rowConvolve31(d_Buffer,d_Input,img1.width(),img1.height(), pitch / sizeof(float));

            colConvolve31(d_Output,d_Buffer,img1.width(),img1.height(),pitch / sizeof(float));
    
        }
        cudaDeviceSynchronize();
    
    }else if(KERNEL_RADIUS == 31 && flag){
        setConvolutionKernel63(h_Kernel,KERNEL_LENGTH);
        for (int j = 0; j < iterations; j++) {
    
            rowConvolve63(d_Buffer,d_Input,img1.width(),img1.height(), pitch / sizeof(float));

            colConvolve63(d_Output,d_Buffer,img1.width(),img1.height(),pitch / sizeof(float));
    
        }
        cudaDeviceSynchronize();
    }else if(KERNEL_RADIUS == 7 && flag){
        setConvolutionKernel15(h_Kernel,KERNEL_LENGTH);
        for (int j = 0; j < iterations; j++) {
    
            rowConvolve15(d_Buffer,d_Input,img1.width(),img1.height(), pitch / sizeof(float));

            colConvolve15(d_Output,d_Buffer,img1.width(),img1.height(),pitch / sizeof(float));
    
        }
        cudaDeviceSynchronize();
    }else if(KERNEL_RADIUS == 63 && flag){
        setConvolutionKernel127(h_Kernel,KERNEL_LENGTH);
        for (int j = 0; j < iterations; j++) {
    
            rowConvolve127(d_Buffer,d_Input,img1.width(),img1.height(), pitch / sizeof(float));

            colConvolve127(d_Output,d_Buffer,img1.width(),img1.height(),pitch / sizeof(float));
    
        }
        cudaDeviceSynchronize();
    }else if(KERNEL_RADIUS == 127 && flag){
        setConvolutionKernel255(h_Kernel,KERNEL_LENGTH);
        for (int j = 0; j < iterations; j++) {
    
            rowConvolve255(d_Buffer,d_Input,img1.width(),img1.height(), pitch / sizeof(float));

            colConvolve255(d_Output,d_Buffer,img1.width(),img1.height(),pitch / sizeof(float));
    
        }
        cudaDeviceSynchronize();
    }else {
        int blockX;
        int blockY;
        if(KERNEL_RADIUS <= 31){
            blockX = 32;
            blockY = 16;
        }else if(KERNEL_RADIUS <= 63){
            blockX = 64;
            blockY = 8;
        }else if(KERNEL_RADIUS <= 127){
            blockX = 128;
            blockY = 4;
        }else {
            std::cout << "Too huge length, maximum supported is 255" << "\n";
            return 0;
        }
        setConvolutionKernel(h_Kernel,KERNEL_LENGTH);
        for (int j = 0; j < iterations; j++) {
    
            rowConvolve(d_Buffer,d_Input,img1.width(),img1.height(), pitch / sizeof(float),KERNEL_RADIUS,blockX,blockY,8,1);

            colConvolve(d_Output,d_Buffer,img1.width(),img1.height(),pitch / sizeof(float),KERNEL_RADIUS,blockY,blockX,8,1);
    
        }
        cudaDeviceSynchronize();
    }

    

    cudaMemcpy2D(h_Output, img1.width() * sizeof(float), d_Output, pitch, img1.width()*sizeof(float), img1.height(), cudaMemcpyDeviceToHost);

    //gold

    convolutionRowCPU(h_BufferGold,img1.data(),h_Kernel,img1.width(),img1.height(),KERNEL_RADIUS);
    convolutionColumnCPU(h_OutputGold,h_BufferGold,h_Kernel,img1.width(),img1.height(),KERNEL_RADIUS);

    cimg_library::CImg<float> output(h_Output,img1.width(),img1.height(),1,1);
    cimg_library::CImg<float> convolved(h_OutputGold,img1.width(),img1.height(),1,1);
    
    convolved.save("cpu-convolved.jpg");
    output.save("cuda-convolved.jpg");

    //Tests whether convolution is correct
    assert(convolved == output);
    std::cout << "pitch = " << pitch << "\n";

    delete[] (h_Kernel);
    delete[] (h_Output);
    delete[] (h_OutputGold);
    delete[] (h_BufferGold);

    cudaFree(d_Input);
    cudaFree(d_Buffer);
    cudaFree(d_Output);
}