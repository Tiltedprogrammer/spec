#include "convolutionSeparable.hpp"

#define ROW_BLOCK_DIM_X 32
#define ROW_BLOCK_DIM_Y 32

//how many pixels an individual thread would proccess
#define ROW_RESULT_STEP 8
//borders length of size @ROW_BLOCK_DIM to satisfy correct alignment
#define ROW_HALO_STEP 1

__constant__ float c_Kernel[KERNEL_LENGTH];

void setConvolutionKernel(float* h_Kernel)
{
    cudaMemcpyToSymbol(c_Kernel, h_Kernel, KERNEL_LENGTH * sizeof(float));
}

__global__ void rowConvolutionFilter(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
){
    __shared__ float sData[ROW_BLOCK_DIM_Y][(ROW_RESULT_STEP + 2*ROW_HALO_STEP) * ROW_BLOCK_DIM_X];

    //offset to left halo edge
    const int baseX = (blockIdx.x * ROW_RESULT_STEP) * ROW_BLOCK_DIM_X - ROW_HALO_STEP * ROW_BLOCK_DIM_X + threadIdx.x;
    const int baseY = blockIdx.y * ROW_BLOCK_DIM_Y + threadIdx.y;

    d_Src += baseY * pitch + baseX;
    d_Dst += baseY * pitch + baseX;
    
    //load main data
    
#pragma unroll

    for (int i = ROW_HALO_STEP; i < ROW_HALO_STEP + ROW_RESULT_STEP; i++) {
     
        sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X] = (baseX + i * ROW_BLOCK_DIM_X) < imageW ? d_Src[i*ROW_BLOCK_DIM_X] : 0;
    
    }

    //load left halo
#pragma unroll
    
    for (int i = 0; i < ROW_HALO_STEP; i++) {

        sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X] = (baseX + i*ROW_BLOCK_DIM_X) >= 0 ? d_Src[i*ROW_BLOCK_DIM_X] : 0;
    }

    //load right halo
#pragma unroll

    for (int i = ROW_HALO_STEP + ROW_RESULT_STEP; i < ROW_HALO_STEP + ROW_RESULT_STEP + ROW_HALO_STEP; i++) {
        
        sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X] = (baseX + i*ROW_BLOCK_DIM_X) < imageW ? d_Src[i * ROW_BLOCK_DIM_X] : 0;
    
    }

    __syncthreads();

    if (baseY >= imageH) {
        return;
    }

    //convolve
#pragma unroll

    for (int i = ROW_HALO_STEP; i < ROW_HALO_STEP+ROW_RESULT_STEP; i++){

        if(baseX + i * ROW_BLOCK_DIM_X < imageW){

            float sum = 0;

        #pragma unroll
            
            for (int j = -KERNEL_RADIUS; j <= KERNEL_RADIUS; j ++) {

                sum += c_Kernel[KERNEL_RADIUS - j] * sData[threadIdx.y][threadIdx.x + i * ROW_BLOCK_DIM_X + j];    
            
            }

            d_Dst[i*ROW_BLOCK_DIM_X] = sum;
        }

    }
}

#define COL_BLOCK_DIM_X 32
#define COL_BLOCK_DIM_Y 32
#define COL_RESULT_STEP 8
#define COL_HALO_STEP 1

__global__ void colConvolutionFilter(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
)
{

    __shared__ float sData[COL_BLOCK_DIM_X][(COL_RESULT_STEP + 2 * COL_HALO_STEP) * COL_BLOCK_DIM_Y + 1]; //+1 to avoid shared mem bank conflicts
    
    const int baseX = blockIdx.x * COL_BLOCK_DIM_X + threadIdx.x;
    const int baseY = blockIdx.y * COL_BLOCK_DIM_Y * COL_RESULT_STEP - COL_HALO_STEP * COL_BLOCK_DIM_Y + threadIdx.y;

    d_Src += baseY * pitch + baseX;
    d_Dst += baseY * pitch + baseX;

    //load main data
#pragma unroll

    for (int i = COL_HALO_STEP; i < COL_HALO_STEP + COL_RESULT_STEP; i++) {
        
        sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y] = (baseY + i * COL_BLOCK_DIM_Y) < imageH ? d_Src[i * COL_BLOCK_DIM_Y * pitch] : 0;
    
    }

    //load top halo
#pragma unroll
    
    for (int i = 0; i < COL_HALO_STEP; i ++) {

        sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y] = (baseY + i * COL_BLOCK_DIM_Y) >= 0 ? d_Src[i * COL_BLOCK_DIM_Y * pitch] : 0;

    }
    //load bottom halo
#pragma unroll
    
    for (int i = COL_HALO_STEP + COL_RESULT_STEP; i < COL_HALO_STEP + COL_RESULT_STEP + COL_HALO_STEP; i++) {
        
        sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y] = (baseY + i * COL_BLOCK_DIM_Y) < imageH ? d_Src[i * COL_BLOCK_DIM_Y * pitch] : 0;
    
    }

    __syncthreads();

    if (baseX >= imageW) {
        return;
    }

    //convolve
#pragma unroll
    
    for (int i = COL_HALO_STEP; i < COL_HALO_STEP + COL_RESULT_STEP; i++) {

        if ((baseY + i * COL_BLOCK_DIM_Y) < imageH) {

            float sum = 0;

        #pragma unroll
            
            for (int j = -KERNEL_RADIUS; j <= KERNEL_RADIUS; j++) {
                
                sum += c_Kernel[KERNEL_RADIUS - j] * sData[threadIdx.x][threadIdx.y + i * COL_BLOCK_DIM_Y + j];
            }

            d_Dst[i * COL_BLOCK_DIM_Y * pitch] = sum;
        }
    }
}

void rowConvolve(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
    ){

        dim3 blocks((imageW + (ROW_RESULT_STEP * ROW_BLOCK_DIM_X) - 1) / (ROW_RESULT_STEP * ROW_BLOCK_DIM_X), (imageH + ROW_BLOCK_DIM_Y - 1)  / ROW_BLOCK_DIM_Y);
        dim3 threads(ROW_BLOCK_DIM_X, ROW_BLOCK_DIM_Y);

        rowConvolutionFilter<<<blocks,threads>>>(d_Dst,d_Src,imageW,imageH,pitch);

    }

void colConvolve(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch
    ){

        dim3 blocks((imageW + COL_BLOCK_DIM_X - 1) / ROW_BLOCK_DIM_X, (imageH + COL_BLOCK_DIM_Y * COL_RESULT_STEP - 1)  / (COL_BLOCK_DIM_Y * COL_RESULT_STEP));
        dim3 threads(COL_BLOCK_DIM_X, COL_BLOCK_DIM_Y);
        
        colConvolutionFilter<<<blocks,threads>>>(d_Dst,d_Src,imageW,imageH,pitch);

    }