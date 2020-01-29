#ifndef CONVOLUTION_SEPARABLE63_H
#define CONVOLUTION_SEPARABLE63_H

#define KERNEL_RADIUS63 31
#define KERNEL_LENGTH63 (2 * KERNEL_RADIUS63 + 1)

void rowConvolve63(float*,float*,int,int,int);

void colConvolve63(float*,float*,int,int,int);

void setConvolutionKernel63(float* h_Kernel, int k_length);

#endif