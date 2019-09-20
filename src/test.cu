#include <string>
#include <iostream>

__global__ void match(char* pattern, int pattern_size, char* text, int text_size, int* result_buf) {

    int t_id = blockIdx.x * blockDim.x + threadIdx.x;

    if(t_id < text_size){
        int matched = 1;
        result_buf[t_id] = -1;

        for(int i = 0; i < pattern_size; i++) {
            if(text[t_id + i] != pattern[i]) {
                matched = -1;
            }
        }
        if(matched == 1) {
            result_buf[t_id] = 1;
        }             
                     

    }
}


int main(int argc, char** argv) {

    std::string pattern = std::string(argv[1]);

    if (pattern.size() > 31) {
        std::cout << "pattern should be less then or eq 31 bytes\n";
        return 0;
    }
    auto pattern_size = pattern.size();
    pattern.resize(31,'0');
    char* dpattern;
    cudaMalloc((void**)&dpattern, pattern_size * sizeof(char));
    cudaMemcpy((void*)dpattern,pattern.c_str(),pattern_size,cudaMemcpyHostToDevice); 
    std::cout << pattern_size << "\n";
    std::cout << pattern << "\n";

    std::string text = std::string(argv[2]);
    // std::cin >> text;
    auto text_size = text.length();
    int* result_buf = new int[text_size];
    int* dresult_buf;
    // std::cout << "text length : " << text_size << "\n";
    char* textptr;
    //think about data transfer;
    cudaMalloc((void**)&textptr, text_size * sizeof(char));
    cudaMemcpy((void*)textptr,text.c_str(),text_size,cudaMemcpyHostToDevice);
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(int));
    
    // for(int i = 0; i < text_size; i++) {
        // result_buf[i] = -1;
    // }
    // cudaMemset((void*)dresult_buf, -1, text_size*sizeof(int));
    // for (int i = 0; i < text_size; i++) {
        // std::cout << result_buf[i];
    // }
    // std::cout << "\n";
    
    // call(text.c_str(),text_size,result_buf);
    match<<<6,2>>>(dpattern,pattern_size,textptr,text_size,dresult_buf);
    cudaDeviceSynchronize();
    cudaMemcpy((void*)result_buf,dresult_buf,text_size*sizeof(int),cudaMemcpyDeviceToHost);

    for (int i = 0; i < text_size; i++) {
        std::cout << result_buf[i];
    }
    std::cout << "\n";
    
    cudaFree(dresult_buf);
    cudaFree(textptr);
    delete[] (result_buf);

    return 0;
}