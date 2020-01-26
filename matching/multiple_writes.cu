#include <string>
#include <iostream>

__global__ void write(int* a){

    a[0] = blockIdx.x + threadIdx.x;
}

int main(int argc, char** argv){

    int a[] = {0};
    int* d_a;
    cudaMalloc(&d_a, 1 * sizeof(int));
    cudaMemcpy(d_a,a,1 * sizeof(int),cudaMemcpyHostToDevice);
    write<<<2,1>>>(d_a);
    cudaMemcpy(a,d_a,1*sizeof(int),cudaMemcpyDeviceToHost);
    cudaDeviceSynchronize();
    std::cout << a[0] << "\n"; 


}
