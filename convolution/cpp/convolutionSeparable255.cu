#include "convolutionSeparable255.hpp"
#include "defines.hpp"

#define ROW_BLOCK_DIM_X255 128
#define ROW_BLOCK_DIM_Y255 4

__constant__ float c_Kernel255[256];

void setConvolutionKernel255(float* h_Kernel, int k_length)
{
    cudaMemcpyToSymbol(c_Kernel255, h_Kernel, k_length * sizeof(float));
}

__global__ void rowConvolutionFilter255(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
){
    __shared__ float sData[ROW_BLOCK_DIM_Y255][(ROW_RESULT_STEP + 2*ROW_HALO_STEP) * ROW_BLOCK_DIM_X255];

    //offset to left halo edge
    const int baseX = (blockIdx.x * ROW_RESULT_STEP) * ROW_BLOCK_DIM_X255 - ROW_HALO_STEP * ROW_BLOCK_DIM_X255 + threadIdx.x;
    const int baseY = blockIdx.y * ROW_BLOCK_DIM_Y255 + threadIdx.y;

    d_Src += baseY * pitch + baseX;
    d_Dst += baseY * pitch + baseX;
    
    //load main data
    
#pragma unroll

    for (int i = ROW_HALO_STEP; i < ROW_HALO_STEP + ROW_RESULT_STEP; i++) {
     
        sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X255] = (baseX + i * ROW_BLOCK_DIM_X255) < imageW ? d_Src[i*ROW_BLOCK_DIM_X255] : 0;
    
    }

    //load left halo
#pragma unroll
    
    for (int i = 0; i < ROW_HALO_STEP; i++) {

        sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X255] = (baseX + i * ROW_BLOCK_DIM_X255) >= 0 ? d_Src[i*ROW_BLOCK_DIM_X255] : 0;
    }

    //load right halo
#pragma unroll

    for (int i = ROW_HALO_STEP + ROW_RESULT_STEP; i < ROW_HALO_STEP + ROW_RESULT_STEP + ROW_HALO_STEP; i++) {
        
        sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X255] = (baseX + i * ROW_BLOCK_DIM_X255) < imageW ? d_Src[i * ROW_BLOCK_DIM_X255] : 0;
    
    }

    __syncthreads();

    if (baseY >= imageH) {
        return;
    }

    //convolve
#pragma unroll

    for (int i = ROW_HALO_STEP; i < ROW_HALO_STEP+ROW_RESULT_STEP; i++){

        if(baseX + i * ROW_BLOCK_DIM_X255 < imageW){

            float sum = 0;

        #pragma unroll
            
            for (int j = -KERNEL_RADIUS255; j <= KERNEL_RADIUS255; j++) {

                sum += c_Kernel255[KERNEL_RADIUS255 - j] * sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X255 + j];    
            
            }

            d_Dst[i*ROW_BLOCK_DIM_X255] = sum;
        }

    }
}

#define COL_BLOCK_DIM_X255 4
#define COL_BLOCK_DIM_Y255 128

__global__ void colConvolutionFilter255(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
)
{

    __shared__ float sData[COL_BLOCK_DIM_X255][(COL_RESULT_STEP + 2 * COL_HALO_STEP) * COL_BLOCK_DIM_Y255 + 1]; //+1 to avoid shared mem bank conflicts
    
    const int baseX = blockIdx.x * COL_BLOCK_DIM_X255 + threadIdx.x;
    const int baseY = blockIdx.y * COL_BLOCK_DIM_Y255 * COL_RESULT_STEP - COL_HALO_STEP * COL_BLOCK_DIM_Y255 + threadIdx.y;

    d_Src += baseY * pitch + baseX;
    d_Dst += baseY * pitch + baseX;

    //load main data
#pragma unroll

    for (int i = COL_HALO_STEP; i < COL_HALO_STEP + COL_RESULT_STEP; i++) {
        
        sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y255] = (baseY + i * COL_BLOCK_DIM_Y255) < imageH ? d_Src[i * COL_BLOCK_DIM_Y255 * pitch] : 0;
    
    }

    //load top halo
#pragma unroll
    
    for (int i = 0; i < COL_HALO_STEP; i ++) {

        sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y255] = (baseY + i * COL_BLOCK_DIM_Y255) >= 0 ? d_Src[i * COL_BLOCK_DIM_Y255 * pitch] : 0;

    }
    //load bottom halo
#pragma unroll
    
    for (int i = COL_HALO_STEP + COL_RESULT_STEP; i < COL_HALO_STEP + COL_RESULT_STEP + COL_HALO_STEP; i++) {
        
        sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y255] = (baseY + i * COL_BLOCK_DIM_Y255) < imageH ? d_Src[i * COL_BLOCK_DIM_Y255 * pitch] : 0;
    
    }

    __syncthreads();

    if (baseX >= imageW) {
        return;
    }

    //convolve
#pragma unroll
    
    for (int i = COL_HALO_STEP; i < COL_HALO_STEP + COL_RESULT_STEP; i++) {

        if ((baseY + i * COL_BLOCK_DIM_Y255) < imageH) {

            float sum = 0;

        #pragma unroll
            
            for (int j = -KERNEL_RADIUS255; j <= KERNEL_RADIUS255; j++) {
                
                sum += c_Kernel255[KERNEL_RADIUS255 - j] * sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y255 + j];
            }

            d_Dst[i * COL_BLOCK_DIM_Y255 * pitch] = sum;
        }
    }
}

void rowConvolve255(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
    ){

        dim3 blocks((imageW + (ROW_RESULT_STEP * ROW_BLOCK_DIM_X255) - 1) / (ROW_RESULT_STEP * ROW_BLOCK_DIM_X255), (imageH + ROW_BLOCK_DIM_Y255 - 1)  / ROW_BLOCK_DIM_Y255);
        dim3 threads(ROW_BLOCK_DIM_X255, ROW_BLOCK_DIM_Y255);

        rowConvolutionFilter255<<<blocks,threads>>>(d_Dst,d_Src,imageW,imageH,pitch);

    }

void colConvolve255(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
    ){

        dim3 blocks((imageW + COL_BLOCK_DIM_X255 - 1) / COL_BLOCK_DIM_X255, (imageH + COL_BLOCK_DIM_Y255 * COL_RESULT_STEP - 1)  / (COL_BLOCK_DIM_Y255 * COL_RESULT_STEP));
        dim3 threads(COL_BLOCK_DIM_X255, COL_BLOCK_DIM_Y255);
        
        colConvolutionFilter255<<<blocks,threads>>>(d_Dst,d_Src,imageW,imageH,pitch);

    }