#include "convolutionSeparable31.hpp"
#include "defines.hpp"

#define ROW_BLOCK_DIM_X31 32
#define ROW_BLOCK_DIM_Y31 16

__constant__ float c_Kernel31[256];

void setConvolutionKernel31(float* h_Kernel, int k_length)
{
    cudaMemcpyToSymbol(c_Kernel31, h_Kernel, k_length * sizeof(float));
}

__global__ void rowConvolutionFilter31(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
){
    __shared__ float sData[ROW_BLOCK_DIM_Y31][(ROW_RESULT_STEP + 2*ROW_HALO_STEP) * ROW_BLOCK_DIM_X31];

    //offset to left halo edge
    const int baseX = (blockIdx.x * ROW_RESULT_STEP) * ROW_BLOCK_DIM_X31 - ROW_HALO_STEP * ROW_BLOCK_DIM_X31 + threadIdx.x;
    const int baseY = blockIdx.y * ROW_BLOCK_DIM_Y31 + threadIdx.y;

    d_Src += baseY * pitch + baseX;
    d_Dst += baseY * pitch + baseX;
    
    //load main data
    
#pragma unroll

    for (int i = ROW_HALO_STEP; i < ROW_HALO_STEP + ROW_RESULT_STEP; i++) {
     
        sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X31] = (baseX + i * ROW_BLOCK_DIM_X31) < imageW ? d_Src[i*ROW_BLOCK_DIM_X31] : 0;
    
    }

    //load left halo
#pragma unroll
    
    for (int i = 0; i < ROW_HALO_STEP; i++) {

        sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X31] = (baseX + i * ROW_BLOCK_DIM_X31) >= 0 ? d_Src[i*ROW_BLOCK_DIM_X31] : 0;
    }

    //load right halo
#pragma unroll

    for (int i = ROW_HALO_STEP + ROW_RESULT_STEP; i < ROW_HALO_STEP + ROW_RESULT_STEP + ROW_HALO_STEP; i++) {
        
        sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X31] = (baseX + i * ROW_BLOCK_DIM_X31) < imageW ? d_Src[i * ROW_BLOCK_DIM_X31] : 0;
    
    }

    __syncthreads();

    if (baseY >= imageH) {
        return;
    }

    //convolve
#pragma unroll

    for (int i = ROW_HALO_STEP; i < ROW_HALO_STEP+ROW_RESULT_STEP; i++){

        if(baseX + i * ROW_BLOCK_DIM_X31 < imageW){

            float sum = 0;

        #pragma unroll
            
            for (int j = -KERNEL_RADIUS31; j <= KERNEL_RADIUS31; j++) {

                sum += c_Kernel31[KERNEL_RADIUS31 - j] * sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X31 + j];    
            
            }

            d_Dst[i*ROW_BLOCK_DIM_X31] = sum;
        }

    }
}

#define COL_BLOCK_DIM_X31 16
#define COL_BLOCK_DIM_Y31 32

__global__ void colConvolutionFilter31(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
)
{

    __shared__ float sData[COL_BLOCK_DIM_X31][(COL_RESULT_STEP + 2 * COL_HALO_STEP) * COL_BLOCK_DIM_Y31 + 1]; //+1 to avoid shared mem bank conflicts
    
    const int baseX = blockIdx.x * COL_BLOCK_DIM_X31 + threadIdx.x;
    const int baseY = blockIdx.y * COL_BLOCK_DIM_Y31 * COL_RESULT_STEP - COL_HALO_STEP * COL_BLOCK_DIM_Y31 + threadIdx.y;

    d_Src += baseY * pitch + baseX;
    d_Dst += baseY * pitch + baseX;

    //load main data
#pragma unroll

    for (int i = COL_HALO_STEP; i < COL_HALO_STEP + COL_RESULT_STEP; i++) {
        
        sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y31] = (baseY + i * COL_BLOCK_DIM_Y31) < imageH ? d_Src[i * COL_BLOCK_DIM_Y31 * pitch] : 0;
    
    }

    //load top halo
#pragma unroll
    
    for (int i = 0; i < COL_HALO_STEP; i ++) {

        sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y31] = (baseY + i * COL_BLOCK_DIM_Y31) >= 0 ? d_Src[i * COL_BLOCK_DIM_Y31 * pitch] : 0;

    }
    //load bottom halo
#pragma unroll
    
    for (int i = COL_HALO_STEP + COL_RESULT_STEP; i < COL_HALO_STEP + COL_RESULT_STEP + COL_HALO_STEP; i++) {
        
        sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y31] = (baseY + i * COL_BLOCK_DIM_Y31) < imageH ? d_Src[i * COL_BLOCK_DIM_Y31 * pitch] : 0;
    
    }

    __syncthreads();

    if (baseX >= imageW) {
        return;
    }

    //convolve
#pragma unroll
    
    for (int i = COL_HALO_STEP; i < COL_HALO_STEP + COL_RESULT_STEP; i++) {

        if ((baseY + i * COL_BLOCK_DIM_Y31) < imageH) {

            float sum = 0;

        #pragma unroll
            
            for (int j = -KERNEL_RADIUS31; j <= KERNEL_RADIUS31; j++) {
                
                sum += c_Kernel31[KERNEL_RADIUS31 - j] * sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y31 + j];
            }

            d_Dst[i * COL_BLOCK_DIM_Y31 * pitch] = sum;
        }
    }
}

void rowConvolve31(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
    ){

        dim3 blocks((imageW + (ROW_RESULT_STEP * ROW_BLOCK_DIM_X31) - 1) / (ROW_RESULT_STEP * ROW_BLOCK_DIM_X31), (imageH + ROW_BLOCK_DIM_Y31 - 1)  / ROW_BLOCK_DIM_Y31);
        dim3 threads(ROW_BLOCK_DIM_X31, ROW_BLOCK_DIM_Y31);

        rowConvolutionFilter31<<<blocks,threads>>>(d_Dst,d_Src,imageW,imageH,pitch);

    }

void colConvolve31(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
    ){

        dim3 blocks((imageW + COL_BLOCK_DIM_X31 - 1) / COL_BLOCK_DIM_X31, (imageH + COL_BLOCK_DIM_Y31 * COL_RESULT_STEP - 1)  / (COL_BLOCK_DIM_Y31 * COL_RESULT_STEP));
        dim3 threads(COL_BLOCK_DIM_X31, COL_BLOCK_DIM_Y31);
        
        colConvolutionFilter31<<<blocks,threads>>>(d_Dst,d_Src,imageW,imageH,pitch);

    }