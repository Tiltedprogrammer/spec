#ifndef CONVOLUTION_SEPARABLE255_H
#define CONVOLUTION_SEPARABLE255_H

#define KERNEL_RADIUS255 127
#define KERNEL_LENGTH255 (2 * KERNEL_RADIUS255 + 1)

void rowConvolve255(float*,float*,int,int,int);

void colConvolve255(float*,float*,int,int,int);

void setConvolutionKernel255(float* h_Kernel, int k_length);

#endif