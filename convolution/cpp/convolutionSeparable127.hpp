#ifndef CONVOLUTION_SEPARABLE127_H
#define CONVOLUTION_SEPARABLE127_H

#define KERNEL_RADIUS127 63
#define KERNEL_LENGTH127 (2 * KERNEL_RADIUS127 + 1)

#define COL_HALO_STEP127 2
#define ROW_HALO_STEP127 2

void rowConvolve127(float*,float*,int,int,int);

void colConvolve127(float*,float*,int,int,int);

void setConvolutionKernel127(float* h_Kernel, int k_length);

#endif