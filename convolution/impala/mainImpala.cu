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
#include "../include/timer.h"
//arg parsing
#include "../include/cxxopts.hpp"


int main(int argc, char** argv) {

    cxxopts::Options options("as", " - example command line options");
    options.add_options()("f,filename","path to image to convolve",cxxopts::value<std::string>())
                         ("o,outfile","path to save convolved image",cxxopts::value<std::string>())
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
        std::cout << "filter size if required" << "\n";
        return 0;
    }

    std::string img_path;
    int KERNEL_RADIUS = (KERNEL_LENGTH - 1) / 2;
    int image = 0;
    if(result.count("filename")){
        img_path = result["filename"].as<std::string>();
        image = 1;
    }else if(result.count("isize")){
        imageH = imageW = result["isize"].as<int>();
    }else{
        std::cout << "Either input image or its size is required" << "\n";
        return 0;
    }

    if(result.count("static")){
        flag = result["static"].as<int>();
    }

    if(result.count("test")){
        test = result["test"].as<int>();
    }

    int iterations = 1;

    // cimg_library::CImg<float> img1("/home/alekseytyurinspb_gmail_com/specialization/spec/convolution/images/graytussaint100.jpg");
    srand(200);
    
    float* h_Input;
    
    if(image){
        cimg_library::CImg<float> img1(img_path.c_str());
        imageW = img1.width();
        imageH = img1.height();
        h_Input = new float [imageH * imageW];
        for (int i = 0; i < imageW * imageH; i++)
        {
            h_Input[i] = img1.data()[i];
        }
    }else{
        long size = imageH * imageW;
        h_Input = new float [size];
        for (long i = 0; i < imageW * imageH; i++)
        {
            h_Input[i] = (float)(rand() % 16);
        }
    }


    std::cout << "image size is " << imageW << "x" << imageH <<"\n";

    float* h_Kernel = new float[KERNEL_LENGTH];
    
    float* h_Output = new float[imageW * imageH];
    

    float  *d_Input,
           *d_Buffer,
           *d_Output;

    size_t pitch;
    cudaMallocPitch((void**)&d_Input,&pitch,imageW * sizeof(float),imageH);
    cudaMallocPitch((void**)&d_Buffer,&pitch,imageW * sizeof(float),imageH);
    cudaMallocPitch((void**)&d_Output,&pitch,imageW * sizeof(float),imageH);

    cudaMemcpy2D(d_Input, pitch, h_Input, imageW*sizeof(float), imageW*sizeof(float), imageH, cudaMemcpyHostToDevice);
    
    for (unsigned int i = 0; i < KERNEL_LENGTH; i++) {
        
        h_Kernel[i] = (float)(rand() % 16);
        
    }

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
            std::to_string(imageH) + "i32, " +
            std::to_string(imageW) + "i32, " +
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

    // cimg_library::CImg<float> output(h_Output,img1.width(),img1.height(),1,1);
    // cimg_library::CImg<float> convolved(h_OutputGold,img1.width(),img1.height(),1,1);

    //Tests whether convolution is correct
    // assert(convolved == output);

    // output.save("impala-convolved.jpg");
    // convolved.save("manually-convolved.jpg");
    // std::cout << "pitch = " << pitch << "\n";

    delete[] (h_Input);
    delete[] (h_Kernel);
    delete[] (h_Output);

    cudaFree(d_Input);
    cudaFree(d_Buffer);
    cudaFree(d_Output);

}