#include "convolutionSeparable.hpp"
#include "defines.hpp"


__constant__ float c_Kernel[256];

void setConvolutionKernel(float* h_Kernel, int k_length)
{
    cudaMemcpyToSymbol(c_Kernel, h_Kernel, k_length * sizeof(float));
}

__global__ void rowConvolutionFilter(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch,
    int radius,
    int blockX,
    int blockY,
    int step,
    int halo
){
    int ROW_BLOCK_DIM_X255 = blockX;
    int ROW_BLOCK_DIM_Y255 = blockY;
    extern __shared__ float sData[];
    int sDataWidth = blockX * (step + 2 * halo);

    //offset to left halo edge
    const int baseX = (blockIdx.x * step) * ROW_BLOCK_DIM_X255 - halo * ROW_BLOCK_DIM_X255 + threadIdx.x;
    const int baseY = blockIdx.y * ROW_BLOCK_DIM_Y255 + threadIdx.y;

    d_Src += baseY * pitch + baseX;
    d_Dst += baseY * pitch + baseX;
    
    //load main data
    
    for (int i = halo; i < halo + step; i++) {
     
        sData[threadIdx.y * sDataWidth + threadIdx.x + i * ROW_BLOCK_DIM_X255] = (baseX + i * ROW_BLOCK_DIM_X255) < imageW ? d_Src[i*ROW_BLOCK_DIM_X255] : 0;
    
    }

    //load left halo
    
    for (int i = 0; i < halo; i++) {

        sData[threadIdx.y * sDataWidth + threadIdx.x + i * ROW_BLOCK_DIM_X255] = (baseX + i * ROW_BLOCK_DIM_X255) >= 0 ? d_Src[i*ROW_BLOCK_DIM_X255] : 0;
    }

    //load right halo

    for (int i = halo + step; i < halo + step + halo; i++) {
        
        sData[threadIdx.y * sDataWidth + threadIdx.x + i * ROW_BLOCK_DIM_X255] = (baseX + i * ROW_BLOCK_DIM_X255) < imageW ? d_Src[i * ROW_BLOCK_DIM_X255] : 0;
    
    }

    __syncthreads();

    if (baseY >= imageH) {
        return;
    }

    //convolve

    for (int i = halo; i < halo+step; i++){

        if(baseX + i * ROW_BLOCK_DIM_X255 < imageW){

            float sum = 0;
            
            for (int j = -radius; j <= radius; j++) {

                sum += c_Kernel[radius - j] * sData[threadIdx.y * sDataWidth + threadIdx.x + i * ROW_BLOCK_DIM_X255 + j];    
            
            }

            d_Dst[i*ROW_BLOCK_DIM_X255] = sum;
        }

    }
}


__global__ void colConvolutionFilter(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch,
    int radius,
    int blockX,
    int blockY,
    int step,
    int halo
)
{
    int COL_BLOCK_DIM_X255 = blockX;
    int COL_BLOCK_DIM_Y255 = blockY;

    extern __shared__ float sData[]; //+1 to avoid shared mem bank conflicts
    int sDataWidth = (blockY * (step + 2 * halo) + 1);
    const int baseX = blockIdx.x * COL_BLOCK_DIM_X255 + threadIdx.x;
    const int baseY = blockIdx.y * COL_BLOCK_DIM_Y255 * step - halo * COL_BLOCK_DIM_Y255 + threadIdx.y;

    d_Src += baseY * pitch + baseX;
    d_Dst += baseY * pitch + baseX;

    //load main data

    for (int i = halo; i < halo + step; i++) {
        
        sData[threadIdx.x * sDataWidth + threadIdx.y + i * COL_BLOCK_DIM_Y255] = (baseY + i * COL_BLOCK_DIM_Y255) < imageH ? d_Src[i * COL_BLOCK_DIM_Y255 * pitch] : 0;
    
    }

    //load top halo
    
    for (int i = 0; i < halo; i ++) {

        sData[threadIdx.x * sDataWidth + threadIdx.y + i * COL_BLOCK_DIM_Y255] = (baseY + i * COL_BLOCK_DIM_Y255) >= 0 ? d_Src[i * COL_BLOCK_DIM_Y255 * pitch] : 0;

    }
    //load bottom halo
    
    for (int i = halo + step; i < halo + step + halo; i++) {
        
        sData[threadIdx.x * sDataWidth + threadIdx.y + i * COL_BLOCK_DIM_Y255] = (baseY + i * COL_BLOCK_DIM_Y255) < imageH ? d_Src[i * COL_BLOCK_DIM_Y255 * pitch] : 0;
    
    }

    __syncthreads();

    if (baseX >= imageW) {
        return;
    }

    //convolve
    
    for (int i = halo; i < halo + step; i++) {

        if ((baseY + i * COL_BLOCK_DIM_Y255) < imageH) {

            float sum = 0;
            
            for (int j = -radius; j <= radius; j++) {
                
                sum += c_Kernel[radius - j] * sData[threadIdx.x * sDataWidth + threadIdx.y + i * COL_BLOCK_DIM_Y255 + j];
            }

            d_Dst[i * COL_BLOCK_DIM_Y255 * pitch] = sum;
        }
    }
}

void rowConvolve(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch,
    int radius,
    int blockX,
    int blockY,
    int step,
    int halo
    ){

        dim3 blocks((imageW + (step * blockX) - 1) / (step * blockX), (imageH + blockY - 1)  / blockY);
        dim3 threads(blockX, blockY);

        rowConvolutionFilter<<<blocks,threads,blockY * blockX * (step + 2 * halo) * sizeof(float) >>>(d_Dst,d_Src,imageW,imageH,pitch,radius,blockX,blockY,step,halo);

    }

void colConvolve(
    float *d_Dst,
    float *d_Src,
    int imageW,
    int imageH,
    int pitch,
    int radius,
    int blockX,
    int blockY,
    int step,
    int halo
    ){

        dim3 blocks((imageW + blockX - 1) / blockX, (imageH + blockY * step - 1)  / (blockY * step));
        dim3 threads(blockX, blockY);
        
        colConvolutionFilter<<<blocks,threads,blockX * (blockY * (step + 2 * halo) + 1) * sizeof(float)>>>(d_Dst,d_Src,imageW,imageH,pitch,radius,blockX,blockY,step,halo);

    }