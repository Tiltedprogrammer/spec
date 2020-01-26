#include <iostream>
#include <cstdlib>
#include <cassert>

// CUDA runtime
#include <cuda_runtime.h>

#define cimg_use_jpeg

#include "cimg/CImg-2.8.3/CImg.h"
#include "cpp/convolutionSeparable.hpp"
#include "cpp/convolutionSeparable_gold.hpp"

int main(int argc, char ** argv){

    cimg_library::CImg<float> img1("/home/alekseytyurinspb_gmail_com/specialization/spec/convolution/images/graytussaint100.jpg");

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

    setConvolutionKernel(h_Kernel);

    cudaMemcpy2D(d_Input, pitch, img1.data(), img1.width()*sizeof(float), img1.width()*sizeof(float), img1.height(), cudaMemcpyHostToDevice);

    rowConvolve(d_Buffer,d_Input,img1.width(),img1.height(), pitch / sizeof(float));

    colConvolve(d_Output,d_Buffer,img1.width(),img1.height(),pitch / sizeof(float));

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