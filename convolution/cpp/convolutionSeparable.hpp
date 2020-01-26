#ifndef CONVOLUTION_SEPARABLE_H
#define CONVOLUTION_SEPARABLE_H

#define KERNEL_RADIUS 8
#define KERNEL_LENGTH (2 * KERNEL_RADIUS + 1)

void rowConvolve(float*,float*,int,int,int);

void colConvolve(float*,float*,int,int,int);

void setConvolutionKernel(float *h_Kernel);

#endif