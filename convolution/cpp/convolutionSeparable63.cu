#include "convolutionSeparable63.hpp"
#include "defines.hpp"

#define ROW_BLOCK_DIM_X63 32
#define ROW_BLOCK_DIM_Y63 16

__constant__ float c_Kernel63[256];

void setConvolutionKernel63(float* h_Kernel, int k_length)
{
    cudaMemcpyToSymbol(c_Kernel63, h_Kernel, k_length * sizeof(float));
}

__global__ void rowConvolutionFilter63(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
){
    __shared__ float sData[ROW_BLOCK_DIM_Y63][(ROW_RESULT_STEP + 2*ROW_HALO_STEP63) * ROW_BLOCK_DIM_X63];

    //offset to left halo edge
    const int baseX = (blockIdx.x * ROW_RESULT_STEP) * ROW_BLOCK_DIM_X63 - ROW_HALO_STEP63 * ROW_BLOCK_DIM_X63 + threadIdx.x;
    const int baseY = blockIdx.y * ROW_BLOCK_DIM_Y63 + threadIdx.y;

    d_Src += baseY * pitch + baseX;
    d_Dst += baseY * pitch + baseX;
    
    //load main data
    
#pragma unroll

    for (int i = ROW_HALO_STEP63; i < ROW_HALO_STEP63 + ROW_RESULT_STEP; i++) {
     
        sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X63] = (baseX + i * ROW_BLOCK_DIM_X63) < imageW ? d_Src[i*ROW_BLOCK_DIM_X63] : 0;
    
    }

    //load left halo
#pragma unroll
    
    for (int i = 0; i < ROW_HALO_STEP63; i++) {

        sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X63] = (baseX + i * ROW_BLOCK_DIM_X63) >= 0 ? d_Src[i*ROW_BLOCK_DIM_X63] : 0;
    }

    //load right halo
#pragma unroll

    for (int i = ROW_HALO_STEP63 + ROW_RESULT_STEP; i < ROW_HALO_STEP63 + ROW_RESULT_STEP + ROW_HALO_STEP63; i++) {
        
        sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X63] = (baseX + i * ROW_BLOCK_DIM_X63) < imageW ? d_Src[i * ROW_BLOCK_DIM_X63] : 0;
    
    }

    __syncthreads();

    if (baseY >= imageH) {
        return;
    }

    //convolve
#pragma unroll

    for (int i = ROW_HALO_STEP63; i < ROW_HALO_STEP63+ROW_RESULT_STEP; i++){

        if(baseX + i * ROW_BLOCK_DIM_X63 < imageW){

            float sum = 0;

        #pragma unroll
            
            for (int j = -KERNEL_RADIUS63; j <= KERNEL_RADIUS63; j++) {

                sum += c_Kernel63[KERNEL_RADIUS63 - j] * sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X63 + j];    
            
            }

            d_Dst[i*ROW_BLOCK_DIM_X63] = sum;
        }

    }
}

#define COL_BLOCK_DIM_X63 16
#define COL_BLOCK_DIM_Y63 32

__global__ void colConvolutionFilter63(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
)
{

    __shared__ float sData[COL_BLOCK_DIM_X63][(COL_RESULT_STEP + 2 * COL_HALO_STEP63) * COL_BLOCK_DIM_Y63 + 1]; //+1 to avoid shared mem bank conflicts
    
    const int baseX = blockIdx.x * COL_BLOCK_DIM_X63 + threadIdx.x;
    const int baseY = blockIdx.y * COL_BLOCK_DIM_Y63 * COL_RESULT_STEP - COL_HALO_STEP63 * COL_BLOCK_DIM_Y63 + threadIdx.y;

    d_Src += baseY * pitch + baseX;
    d_Dst += baseY * pitch + baseX;

    //load main data
#pragma unroll

    for (int i = COL_HALO_STEP63; i < COL_HALO_STEP63 + COL_RESULT_STEP; i++) {
        
        sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y63] = (baseY + i * COL_BLOCK_DIM_Y63) < imageH ? d_Src[i * COL_BLOCK_DIM_Y63 * pitch] : 0;
    
    }

    //load top halo
#pragma unroll
    
    for (int i = 0; i < COL_HALO_STEP63; i ++) {

        sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y63] = (baseY + i * COL_BLOCK_DIM_Y63) >= 0 ? d_Src[i * COL_BLOCK_DIM_Y63 * pitch] : 0;

    }
    //load bottom halo
#pragma unroll
    
    for (int i = COL_HALO_STEP63 + COL_RESULT_STEP; i < COL_HALO_STEP63 + COL_RESULT_STEP + COL_HALO_STEP63; i++) {
        
        sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y63] = (baseY + i * COL_BLOCK_DIM_Y63) < imageH ? d_Src[i * COL_BLOCK_DIM_Y63 * pitch] : 0;
    
    }

    __syncthreads();

    if (baseX >= imageW) {
        return;
    }

    //convolve
#pragma unroll
    
    for (int i = COL_HALO_STEP63; i < COL_HALO_STEP63 + COL_RESULT_STEP; i++) {

        if ((baseY + i * COL_BLOCK_DIM_Y63) < imageH) {

            float sum = 0;

        #pragma unroll
            
            for (int j = -KERNEL_RADIUS63; j <= KERNEL_RADIUS63; j++) {
                
                sum += c_Kernel63[KERNEL_RADIUS63 - j] * sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y63 + j];
            }

            d_Dst[i * COL_BLOCK_DIM_Y63 * pitch] = sum;
        }
    }
}

void rowConvolve63(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
    ){

        dim3 blocks((imageW + (ROW_RESULT_STEP * ROW_BLOCK_DIM_X63) - 1) / (ROW_RESULT_STEP * ROW_BLOCK_DIM_X63), (imageH + ROW_BLOCK_DIM_Y63 - 1)  / ROW_BLOCK_DIM_Y63);
        dim3 threads(ROW_BLOCK_DIM_X63, ROW_BLOCK_DIM_Y63);

        rowConvolutionFilter63<<<blocks,threads>>>(d_Dst,d_Src,imageW,imageH,pitch);

    }

void colConvolve63(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
    ){

        dim3 blocks((imageW + COL_BLOCK_DIM_X63 - 1) / COL_BLOCK_DIM_X63, (imageH + COL_BLOCK_DIM_Y63 * COL_RESULT_STEP - 1)  / (COL_BLOCK_DIM_Y63 * COL_RESULT_STEP));
        dim3 threads(COL_BLOCK_DIM_X63, COL_BLOCK_DIM_Y63);
        
        colConvolutionFilter63<<<blocks,threads>>>(d_Dst,d_Src,imageW,imageH,pitch);

    }