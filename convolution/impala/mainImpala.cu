#include <iostream>
#include <cstdlib>
#include <cassert>

// CUDA runtime
// #include <cuda_runtime.h>

#define cimg_use_jpeg

#include "../cimg/CImg-2.8.3/CImg.h"
#include "../cpp/convolutionSeparable_gold.hpp"


#define RUNTIME_ENABLE_JIT
#include <anydsl_runtime.h>

// Generated from convolutionSeparable.impala
#include "convolutionSeparable.inc"

//timers
#include "timer.h"
#include "cxxopts.hpp"


int main(int argc, char** argv) {

    if (argc < 4) {
        std::cout << "Image path and #iterations required" << "\n";
        return 0;
    }

    int KERNEL_LENGTH = std::atoi(argv[3]);
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


    size_t pitch;
    cudaMallocPitch((void**)&d_Input,&pitch,img1.width() * sizeof(float),img1.height());
    cudaMallocPitch((void**)&d_Buffer,&pitch,img1.width() * sizeof(float),img1.height());
    cudaMallocPitch((void**)&d_Output,&pitch,img1.width() * sizeof(float),img1.height());

    cudaMemcpy2D(d_Input, pitch, img1.data(), img1.width()*sizeof(float), img1.width()*sizeof(float), img1.height(), cudaMemcpyHostToDevice);

    srand(200);
    
    for (unsigned int i = 0; i < KERNEL_LENGTH; i++) {
        
        h_Kernel[i] = (float)(rand() % 16);
        
    }

    for (int i = 0; i < KERNEL_LENGTH; i++) {
        std::cout << h_Kernel[i] << " ";
    }
    std::cout << "\n";

    std::string kernel_string;

    for (int i = 0; i < KERNEL_LENGTH - 1; i++) {
        kernel_string += std::to_string(h_Kernel[i]);
        kernel_string += "f32, ";
    }
    kernel_string += std::to_string(h_Kernel[KERNEL_LENGTH - 1]) + "f32";

    int block_sizeX = 32;
    int block_sizeY = 16;
    int result_step = 8;

    if(KERNEL_LENGTH <= 63 ){ //radius < 31
        block_sizeX = 32;
        block_sizeY = 16;
    }else if(KERNEL_LENGTH <= 127){ //radius is 63
        block_sizeX = 64;
        block_sizeY = 8;
    }else if (KERNEL_LENGTH <= 255){
        block_sizeX = 128;
        block_sizeY = 4;
    }else{
        std::cout << "Too huge kernel length, maximum supported is 255" << "\n";
        return 0;
    }
    

    std::string dummy = "extern fn dummy(d_Src: &[f32],d_Buf : &mut[f32],d_Dst: &mut[f32])-> (){\n";
    dummy += "   convolveImpala(d_Src, d_Buf, d_Dst, [" +
            kernel_string + "], " +
            std::to_string((KERNEL_LENGTH - 1) / 2) + "i32, " +
            std::to_string(img1.height()) + "i32, " +
            std::to_string(img1.width()) + "i32, " +
            std::to_string(pitch / sizeof(float)) + "i32, " +
            std::to_string(block_sizeX) + "i32, " +
            std::to_string(block_sizeY) + "i32, " +
            std::to_string(result_step) + "i32)\n }";

    std::string program = std::string((char*)convolutionSeparable_impala) + dummy;

    std::cout << "Compiling ..." << "\n";
    am::timer time;
    time.start();
    
    auto key = anydsl_compile(program.c_str(),program.size(),0);
    
    time.stop();
    std::cout << "compilation time " << time.milliseconds() << std::endl;
    time.reset();

    typedef void (*function) (const float*,const float* ,const float *);
    auto call = reinterpret_cast<function>(anydsl_lookup_function(key,"dummy"));
    
    if (call == nullptr) {
        std::cout << "compilation failed\n";
        return 0;
    } else {
        std::cout << "succesfully compiled\n";
    }

    
    for (int j = 0; j < iterations; j++){
        call(d_Input,d_Buffer,d_Output);
    }
    cudaDeviceSynchronize();

    cudaMemcpy2D(h_Output, img1.width() * sizeof(float), d_Output, pitch, img1.width()*sizeof(float), img1.height(), cudaMemcpyDeviceToHost);


    //gold

    convolutionRowCPU(h_BufferGold,img1.data(),h_Kernel,img1.width(),img1.height(),(KERNEL_LENGTH - 1) /2);
    convolutionColumnCPU(h_OutputGold,h_BufferGold,h_Kernel,img1.width(),img1.height(),(KERNEL_LENGTH - 1) /2);
    

    cimg_library::CImg<float> output(h_Output,img1.width(),img1.height(),1,1);
    cimg_library::CImg<float> convolved(h_OutputGold,img1.width(),img1.height(),1,1);

    //Tests whether convolution is correct
    assert(convolved == output);
    output.save("impala-convolved.jpg");
    convolved.save("manually-convolved.jpg");
    std::cout << "pitch = " << pitch << "\n";

    delete[] (h_Kernel);
    delete[] (h_Output);
    delete[] (h_OutputGold);
    delete[] (h_BufferGold);

    cudaFree(d_Input);
    cudaFree(d_Buffer);
    cudaFree(d_Output);

}