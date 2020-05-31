#include "convolutionSeparable15.hpp"
#include "defines.hpp"

#define ROW_BLOCK_DIM_X15 32
#define ROW_BLOCK_DIM_Y15 16

__constant__ float c_Kernel15[256];

void setConvolutionKernel15(float* h_Kernel, int k_length)
{
    cudaMemcpyToSymbol(c_Kernel15, h_Kernel, k_length * sizeof(float));
}

__global__ void rowConvolutionFilter15(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
){
    __shared__ float sData[ROW_BLOCK_DIM_Y15][(ROW_RESULT_STEP + 2*ROW_HALO_STEP15) * ROW_BLOCK_DIM_X15];

    //offset to left halo edge
    const int baseX = (blockIdx.x * ROW_RESULT_STEP) * ROW_BLOCK_DIM_X15 - ROW_HALO_STEP15 * ROW_BLOCK_DIM_X15 + threadIdx.x;
    const int baseY = blockIdx.y * ROW_BLOCK_DIM_Y15 + threadIdx.y;

    d_Src += baseY * pitch + baseX;
    d_Dst += baseY * pitch + baseX;
    
    //load main data
    
#pragma unroll

    for (int i = ROW_HALO_STEP15; i < ROW_HALO_STEP15 + ROW_RESULT_STEP; i++) {
     
        sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X15] = (baseX + i * ROW_BLOCK_DIM_X15) < imageW ? d_Src[i*ROW_BLOCK_DIM_X15] : 0;
    
    }

    //load left halo
#pragma unroll
    
    for (int i = 0; i < ROW_HALO_STEP15; i++) {

        sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X15] = (baseX + i * ROW_BLOCK_DIM_X15) >= 0 ? d_Src[i*ROW_BLOCK_DIM_X15] : 0;
    }

    //load right halo
#pragma unroll

    for (int i = ROW_HALO_STEP15 + ROW_RESULT_STEP; i < ROW_HALO_STEP15 + ROW_RESULT_STEP + ROW_HALO_STEP15; i++) {
        
        sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X15] = (baseX + i * ROW_BLOCK_DIM_X15) < imageW ? d_Src[i * ROW_BLOCK_DIM_X15] : 0;
    
    }

    __syncthreads();

    if (baseY >= imageH) {
        return;
    }

    //convolve
#pragma unroll

    for (int i = ROW_HALO_STEP15; i < ROW_HALO_STEP15+ROW_RESULT_STEP; i++){

        if(baseX + i * ROW_BLOCK_DIM_X15 < imageW){

            float sum = 0;

        #pragma unroll
            
            for (int j = -KERNEL_RADIUS15; j <= KERNEL_RADIUS15; j++) {

                sum += c_Kernel15[KERNEL_RADIUS15 - j] * sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X15 + j];    
            
            }

            d_Dst[i*ROW_BLOCK_DIM_X15] = sum;
        }

    }
}

#define COL_BLOCK_DIM_X15 16
#define COL_BLOCK_DIM_Y15 32

__global__ void colConvolutionFilter15(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
)
{

    __shared__ float sData[COL_BLOCK_DIM_X15][(COL_RESULT_STEP + 2 * COL_HALO_STEP15) * COL_BLOCK_DIM_Y15 + 1]; //+1 to avoid shared mem bank conflicts
    
    const int baseX = blockIdx.x * COL_BLOCK_DIM_X15 + threadIdx.x;
    const int baseY = blockIdx.y * COL_BLOCK_DIM_Y15 * COL_RESULT_STEP - COL_HALO_STEP15 * COL_BLOCK_DIM_Y15 + threadIdx.y;

    d_Src += baseY * pitch + baseX;
    d_Dst += baseY * pitch + baseX;

    //load main data
#pragma unroll

    for (int i = COL_HALO_STEP15; i < COL_HALO_STEP15 + COL_RESULT_STEP; i++) {
        
        sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y15] = (baseY + i * COL_BLOCK_DIM_Y15) < imageH ? d_Src[i * COL_BLOCK_DIM_Y15 * pitch] : 0;
    
    }

    //load top halo
#pragma unroll
    
    for (int i = 0; i < COL_HALO_STEP15; i ++) {

        sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y15] = (baseY + i * COL_BLOCK_DIM_Y15) >= 0 ? d_Src[i * COL_BLOCK_DIM_Y15 * pitch] : 0;

    }
    //load bottom halo
#pragma unroll
    
    for (int i = COL_HALO_STEP15 + COL_RESULT_STEP; i < COL_HALO_STEP15 + COL_RESULT_STEP + COL_HALO_STEP15; i++) {
        
        sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y15] = (baseY + i * COL_BLOCK_DIM_Y15) < imageH ? d_Src[i * COL_BLOCK_DIM_Y15 * pitch] : 0;
    
    }

    __syncthreads();

    if (baseX >= imageW) {
        return;
    }

    //convolve
#pragma unroll
    
    for (int i = COL_HALO_STEP15; i < COL_HALO_STEP15 + COL_RESULT_STEP; i++) {

        if ((baseY + i * COL_BLOCK_DIM_Y15) < imageH) {

            float sum = 0;

        #pragma unroll
            
            for (int j = -KERNEL_RADIUS15; j <= KERNEL_RADIUS15; j++) {
                
                sum += c_Kernel15[KERNEL_RADIUS15 - j] * sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y15 + j];
            }

            d_Dst[i * COL_BLOCK_DIM_Y15 * pitch] = sum;
        }
    }
}

void rowConvolve15(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
    ){

        dim3 blocks((imageW + (ROW_RESULT_STEP * ROW_BLOCK_DIM_X15) - 1) / (ROW_RESULT_STEP * ROW_BLOCK_DIM_X15), (imageH + ROW_BLOCK_DIM_Y15 - 1)  / ROW_BLOCK_DIM_Y15);
        dim3 threads(ROW_BLOCK_DIM_X15, ROW_BLOCK_DIM_Y15);

        rowConvolutionFilter15<<<blocks,threads>>>(d_Dst,d_Src,imageW,imageH,pitch);

    }

void colConvolve15(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
    ){

        dim3 blocks((imageW + COL_BLOCK_DIM_X15 - 1) / COL_BLOCK_DIM_X15, (imageH + COL_BLOCK_DIM_Y15 * COL_RESULT_STEP - 1)  / (COL_BLOCK_DIM_Y15 * COL_RESULT_STEP));
        dim3 threads(COL_BLOCK_DIM_X15, COL_BLOCK_DIM_Y15);
        
        colConvolutionFilter15<<<blocks,threads>>>(d_Dst,d_Src,imageW,imageH,pitch);

    }