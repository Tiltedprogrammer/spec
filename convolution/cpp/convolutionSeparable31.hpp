#ifndef CONVOLUTION_SEPARABLE31_H
#define CONVOLUTION_SEPARABLE31_H

#define KERNEL_RADIUS31 15
#define KERNEL_LENGTH31 (2 * KERNEL_RADIUS31 + 1)

#define COL_HALO_STEP31 1
#define ROW_HALO_STEP31 1

void rowConvolve31(float*,float*,int,int,int);

void colConvolve31(float*,float*,int,int,int);

void setConvolutionKernel31(float* h_Kernel, int k_length);

#endif