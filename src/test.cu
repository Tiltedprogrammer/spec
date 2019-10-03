#include <string>
#include <vector>
#include <iostream>
#include <stdlib.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fstream>
#include "timer.h"

typedef struct Template{
    char array[32] = {0};
    int size;
}Template;

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

__global__ void match_multy(char* pattern, int* p_sizes, int p_number, char* text, int text_size, int* result_buf) {

    int t_id = blockIdx.x * blockDim.x + threadIdx.x;

    if(t_id < text_size){
        int p_offset = 0;
        int matched = 0;
        result_buf[t_id] = -1;

        for(int i = 0; i < p_number; i++) {
            matched = 0;
            for(int j = 0; j < p_sizes[i]; j++){
                
                if(text[t_id + j] != pattern[j+p_offset]) {
                    matched = -1;
                }
            }

            p_offset += p_sizes[i]; 
            
            if(matched != -1) {
                result_buf[t_id] = i;
            }
        }             
    }
}

__global__ void match_struct(Template pattern, char* text, int text_size, int* result_buf) {

    int t_id = blockIdx.x * blockDim.x + threadIdx.x;

    if(t_id < text_size){
        int matched = 1;
        result_buf[t_id] = -1;

        for(int i = 0; i < pattern.size; i++) {
            if(text[t_id + i] != pattern.array[i]) {
                matched = -1;
            }
        }
        if(matched == 1) {
            result_buf[t_id] = 1;
        }             
                     

    }
}

long GetFileSize(std::string filename)
{
    struct stat stat_buf;
    int rc = stat(filename.c_str(), &stat_buf);
    return rc == 0 ? stat_buf.st_size : -1;
}

void multipattern_match(int p_number,char** argv_patterns, char* file_name){

    int* sizes = new int[p_number];
    int len = 0;
    for(int i = 1; i < p_number+1; i++) {
        auto str = std::string(argv_patterns[i]);
        sizes[i-1] = str.length();
        len += str.length();    
    }

    char* patterns = new char[len];
    
    int offset = 0;

    for(int i = 0; i < p_number; i++){

        for(int j = 0; j < sizes[i]; j++){
            patterns[offset+j] = argv_patterns[i+1][j];
        }
        offset+=sizes[i];    
    }

    char* dpatterns;
    int* dsizes;
    cudaMalloc((void**)&dsizes, (p_number)*sizeof(int));
    cudaMemcpy((void*)dsizes, sizes, (p_number)*sizeof(int), cudaMemcpyHostToDevice); 
    cudaMalloc((void**)&dpatterns, len * sizeof(char));
    cudaMemcpy((void*)dpatterns, patterns, len*sizeof(char), cudaMemcpyHostToDevice);

    std::string subject_string_filename(file_name);

    auto text_size = GetFileSize(subject_string_filename) - 1;//TODO
    
    //read file
    FILE *f;
    if((f = fopen(subject_string_filename.c_str(), "rb")) == NULL){
	std::cout << "can not oppen file" << subject_string_filename << "\n";
	    return;
    }

    char *subject_string = new char[text_size];
    fread(subject_string, 1, text_size, f);
    fclose(f);
    // std::cin >> text;
    int* result_buf = new int[text_size];
    int* dresult_buf;
    // std::cout << "text length : " << text_size << "\n";
    char* textptr;
    //think about data transfer;
    cudaMalloc((void**)&textptr, text_size * sizeof(char));
    cudaMemcpy((void*)textptr,subject_string,text_size,cudaMemcpyHostToDevice);
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(int));
    
    dim3 block(1024);
    int grid_size = (text_size + block.x - 1) / block.x;
    dim3 grid(grid_size);

    // cudaEvent_t start, stop;
    // cudaEventCreate(&start);
    // cudaEventCreate(&stop);
    
    std::cout << "running ..." << "\n";

    am::timer time;
    time.start();
    match_multy<<<grid,block>>>(dpatterns,dsizes,p_number,textptr,text_size,dresult_buf);
    // cudaEventRecord(stop);
    delete[](sizes);
    delete[](patterns);
    delete[](subject_string);
    cudaDeviceSynchronize();
    time.stop();
    std::cout << "running time " << time.milliseconds() << " ms" << std::endl;
    cudaMemcpy((void*)result_buf,dresult_buf,text_size*sizeof(int),cudaMemcpyDeviceToHost);
    // cudaEventSynchronize(stop);
    cudaDeviceSynchronize();

    float milliseconds = 0;
    // cudaEventElapsedTime(&milliseconds, start, stop);

    // std::cout << "running time " << milliseconds << "ms" << "\n";



    for (int i = 0; i < text_size; i++) {
        std::cout << result_buf[i];
    }
    std::cout << "\n";
    
    cudaFree(dresult_buf);
    cudaFree(textptr);
    // cudaFree(dpattern);
    // cudaEventDestroy(start);
    // cudaEventDestroy(stop);
    delete[] (result_buf);  

}


int main(int argc, char** argv) {

    
    // std::string pattern = std::string(argv[1]);

    // if (pattern.size() > 31) {
        // std::cout << "pattern should be less then or eq 31 bytes\n";
        // return 0;
    // }
    // auto pattern_size = pattern.size();
    // pattern.resize(31,'0');
    // Template dpattern_s;
    // dpattern_s.size = pattern_size;
    // for(int i = 0; i < pattern_size; i++) {
        // dpattern_s.array[i] = pattern[i];
    // }
    // char* dpatterns;
    // int* dsizes;
    // cudaMalloc((void**)&dsizes, (argc-1)*sizeof(int));
    // cudaMemcpy((void*)dsizes, sizes, (argc-1)*sizeof(int), cudaMemcpyHostToDevice); 
    // cudaMalloc((void**)&dpatterns, len * sizeof(char));
    // cudaMemcpy((void*)dpatterns, patterns, len*sizeof(char), cudaMemcpyHostToDevice); 
    

    /*std::string subject_string_filename("data/subject.txt");

    auto text_size = GetFileSize(subject_string_filename) - 1;//TODO
    
    //read file
    FILE *f;
    if((f = fopen(subject_string_filename.c_str(), "rb")) == NULL){
	std::cout << "can not oppen file" << subject_string_filename << "\n";
	return 0;
    }

    char *subject_string = new char[text_size];
    fread(subject_string, 1, text_size, f);
    fclose(f);
    // std::cin >> text;
    int* result_buf = new int[text_size];
    int* dresult_buf;
    // std::cout << "text length : " << text_size << "\n";
    char* textptr;
    //think about data transfer;
    cudaMalloc((void**)&textptr, text_size * sizeof(char));
    cudaMemcpy((void*)textptr,subject_string,text_size,cudaMemcpyHostToDevice);
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(int));
    
    dim3 block(1024);
    int grid_size = (text_size + block.x - 1) / block.x;
    dim3 grid(grid_size);

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    
    std::cout << "running ..." << "\n";

    am::timer time;
    time.start();
    // cudaEventRecord(start);
    // match_struct<<<grid,block>>>(dpattern_s,textptr,text_size,dresult_buf);
    // match<<<grid,block>>>(dpattern,pattern_size,textptr,text_size,dresult_buf);
    match_multy<<<grid,block>>>(dpatterns,dsizes,argc-1,textptr,text_size,dresult_buf);
    // cudaEventRecord(stop);
    delete[](sizes);
    delete[](patterns);
    delete[](subject_string);
    cudaDeviceSynchronize();
    time.stop();
    std::cout << "running time " << time.milliseconds() << " ms" << std::endl;
    cudaMemcpy((void*)result_buf,dresult_buf,text_size*sizeof(int),cudaMemcpyDeviceToHost);
    // cudaEventSynchronize(stop);
    cudaDeviceSynchronize();

    float milliseconds = 0;
    // cudaEventElapsedTime(&milliseconds, start, stop);

    // std::cout << "running time " << milliseconds << "ms" << "\n";



    for (int i = 0; i < text_size; i++) {
        std::cout << result_buf[i];
    }
    std::cout << "\n";
    
    cudaFree(dresult_buf);
    cudaFree(textptr);
    // cudaFree(dpattern);
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
    delete[] (result_buf);*/

    multipattern_match(argc-1,argv,"data/subject.txt");

    return 0;
}
