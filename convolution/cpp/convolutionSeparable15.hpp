#ifndef CONVOLUTION_SEPARABLE15_H
#define CONVOLUTION_SEPARABLE15_H

#define KERNEL_RADIUS15 7
#define KERNEL_LENGTH15 (2 * KERNEL_RADIUS15 + 1)

#define COL_HALO_STEP15 1
#define ROW_HALO_STEP15 1


void rowConvolve15(float*,float*,int,int,int);

void colConvolve15(float*,float*,int,int,int);

void setConvolutionKernel15(float* h_Kernel, int k_length);

#endif