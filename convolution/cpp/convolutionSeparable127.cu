#include "convolutionSeparable127.hpp"
#include "defines.hpp"

#define ROW_BLOCK_DIM_X127 64
#define ROW_BLOCK_DIM_Y127 8

__constant__ float c_Kernel127[256];

void setConvolutionKernel127(float* h_Kernel, int k_length)
{
    cudaMemcpyToSymbol(c_Kernel127, h_Kernel, k_length * sizeof(float));
}

__global__ void rowConvolutionFilter127(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
){
    __shared__ float sData[ROW_BLOCK_DIM_Y127][(ROW_RESULT_STEP + 2*ROW_HALO_STEP) * ROW_BLOCK_DIM_X127];

    //offset to left halo edge
    const int baseX = (blockIdx.x * ROW_RESULT_STEP) * ROW_BLOCK_DIM_X127 - ROW_HALO_STEP * ROW_BLOCK_DIM_X127 + threadIdx.x;
    const int baseY = blockIdx.y * ROW_BLOCK_DIM_Y127 + threadIdx.y;

    d_Src += baseY * pitch + baseX;
    d_Dst += baseY * pitch + baseX;
    
    //load main data
    
#pragma unroll

    for (int i = ROW_HALO_STEP; i < ROW_HALO_STEP + ROW_RESULT_STEP; i++) {
     
        sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X127] = (baseX + i * ROW_BLOCK_DIM_X127) < imageW ? d_Src[i*ROW_BLOCK_DIM_X127] : 0;
    
    }

    //load left halo
#pragma unroll
    
    for (int i = 0; i < ROW_HALO_STEP; i++) {

        sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X127] = (baseX + i * ROW_BLOCK_DIM_X127) >= 0 ? d_Src[i*ROW_BLOCK_DIM_X127] : 0;
    }

    //load right halo
#pragma unroll

    for (int i = ROW_HALO_STEP + ROW_RESULT_STEP; i < ROW_HALO_STEP + ROW_RESULT_STEP + ROW_HALO_STEP; i++) {
        
        sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X127] = (baseX + i * ROW_BLOCK_DIM_X127) < imageW ? d_Src[i * ROW_BLOCK_DIM_X127] : 0;
    
    }

    __syncthreads();

    if (baseY >= imageH) {
        return;
    }

    //convolve
#pragma unroll

    for (int i = ROW_HALO_STEP; i < ROW_HALO_STEP+ROW_RESULT_STEP; i++){

        if(baseX + i * ROW_BLOCK_DIM_X127 < imageW){

            float sum = 0;

        #pragma unroll
            
            for (int j = -KERNEL_RADIUS127; j <= KERNEL_RADIUS127; j++) {

                sum += c_Kernel127[KERNEL_RADIUS127 - j] * sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X127 + j];    
            
            }

            d_Dst[i*ROW_BLOCK_DIM_X127] = sum;
        }

    }
}

#define COL_BLOCK_DIM_X127 8
#define COL_BLOCK_DIM_Y127 64

__global__ void colConvolutionFilter127(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
)
{

    __shared__ float sData[COL_BLOCK_DIM_X127][(COL_RESULT_STEP + 2 * COL_HALO_STEP) * COL_BLOCK_DIM_Y127 + 1]; //+1 to avoid shared mem bank conflicts
    
    const int baseX = blockIdx.x * COL_BLOCK_DIM_X127 + threadIdx.x;
    const int baseY = blockIdx.y * COL_BLOCK_DIM_Y127 * COL_RESULT_STEP - COL_HALO_STEP * COL_BLOCK_DIM_Y127 + threadIdx.y;

    d_Src += baseY * pitch + baseX;
    d_Dst += baseY * pitch + baseX;

    //load main data
#pragma unroll

    for (int i = COL_HALO_STEP; i < COL_HALO_STEP + COL_RESULT_STEP; i++) {
        
        sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y127] = (baseY + i * COL_BLOCK_DIM_Y127) < imageH ? d_Src[i * COL_BLOCK_DIM_Y127 * pitch] : 0;
    
    }

    //load top halo
#pragma unroll
    
    for (int i = 0; i < COL_HALO_STEP; i ++) {

        sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y127] = (baseY + i * COL_BLOCK_DIM_Y127) >= 0 ? d_Src[i * COL_BLOCK_DIM_Y127 * pitch] : 0;

    }
    //load bottom halo
#pragma unroll
    
    for (int i = COL_HALO_STEP + COL_RESULT_STEP; i < COL_HALO_STEP + COL_RESULT_STEP + COL_HALO_STEP; i++) {
        
        sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y127] = (baseY + i * COL_BLOCK_DIM_Y127) < imageH ? d_Src[i * COL_BLOCK_DIM_Y127 * pitch] : 0;
    
    }

    __syncthreads();

    if (baseX >= imageW) {
        return;
    }

    //convolve
#pragma unroll
    
    for (int i = COL_HALO_STEP; i < COL_HALO_STEP + COL_RESULT_STEP; i++) {

        if ((baseY + i * COL_BLOCK_DIM_Y127) < imageH) {

            float sum = 0;

        #pragma unroll
            
            for (int j = -KERNEL_RADIUS127; j <= KERNEL_RADIUS127; j++) {
                
                sum += c_Kernel127[KERNEL_RADIUS127 - j] * sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y127 + j];
            }

            d_Dst[i * COL_BLOCK_DIM_Y127 * pitch] = sum;
        }
    }
}

void rowConvolve127(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
    ){

        dim3 blocks((imageW + (ROW_RESULT_STEP * ROW_BLOCK_DIM_X127) - 1) / (ROW_RESULT_STEP * ROW_BLOCK_DIM_X127), (imageH + ROW_BLOCK_DIM_Y127 - 1)  / ROW_BLOCK_DIM_Y127);
        dim3 threads(ROW_BLOCK_DIM_X127, ROW_BLOCK_DIM_Y127);

        rowConvolutionFilter127<<<blocks,threads>>>(d_Dst,d_Src,imageW,imageH,pitch);

    }

void colConvolve127(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
    ){

        dim3 blocks((imageW + COL_BLOCK_DIM_X127 - 1) / COL_BLOCK_DIM_X127, (imageH + COL_BLOCK_DIM_Y127 * COL_RESULT_STEP - 1)  / (COL_BLOCK_DIM_Y127 * COL_RESULT_STEP));
        dim3 threads(COL_BLOCK_DIM_X127, COL_BLOCK_DIM_Y127);
        
        colConvolutionFilter127<<<blocks,threads>>>(d_Dst,d_Src,imageW,imageH,pitch);

    }