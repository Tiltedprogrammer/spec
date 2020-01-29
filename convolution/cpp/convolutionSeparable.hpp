#ifndef CONVOLUTION_SEPARABLE_H
#define CONVOLUTION_SEPARABLE_H


void rowConvolve(float*,float*,int,int,int,int,int,int,int,int);

void colConvolve(float*,float*,int,int,int,int,int,int,int,int);

void setConvolutionKernel(float* h_Kernel, int k_length);

#endif