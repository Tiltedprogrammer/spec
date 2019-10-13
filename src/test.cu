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

long GetFileSize(std::string filename)
{
    struct stat stat_buf;
    int rc = stat(filename.c_str(), &stat_buf);
    return rc == 0 ? stat_buf.st_size : -1;
}

char* read_file(std::string filename,  int &text_size){
    
    text_size = GetFileSize(filename) - 1;//TODO
    //read file
    FILE *f;
    if((f = fopen(filename.c_str(), "rb")) == NULL){
	    std::cout << "can not oppen file" << filename << "\n";
	    return 0;
    }

    
    int text_chunk = 128 * 1024 * 1024;
    if(text_size < text_chunk) {
        text_chunk = text_size;
    }
    char *subject_string = new char[text_chunk];

    char* dtextptr;
    
    cudaMalloc((void**)&dtextptr, text_size * sizeof(char));

    for(int i = 0; i < (text_size + text_chunk - 1) / text_chunk; i++){ //number of chunks

        int right_bound = (i+1) * text_chunk < text_size ? (i+1) * text_chunk : text_size;
        int left_bound = i * text_chunk;
        fread(subject_string,sizeof(char),right_bound-(left_bound),f);
        cudaMemcpy((void*)(dtextptr + left_bound),subject_string,right_bound-(left_bound),cudaMemcpyHostToDevice);

    }

    delete[](subject_string);
    fclose(f);

    return dtextptr;
}

void write_from_device(int** dresult_buf,int text_size){

    int text_chunk = 128 * 1024 * 1024;
    if(text_size < text_chunk) {
        text_chunk = text_size;
    }

    int* result_buf = new int[text_chunk];


    for(int i = 0; i < (text_size + text_chunk - 1) / text_chunk; i++){ //number of chunks

        int right_bound = (i+1) * text_chunk < text_size ? (i+1) * text_chunk : text_size;
        int left_bound = i * text_chunk;

        cudaMemcpy((void*)(result_buf),((*dresult_buf)+left_bound),(right_bound-(left_bound))*sizeof(int),cudaMemcpyDeviceToHost);
        
        for (int i = 0; i < (right_bound-left_bound); i++) {
            std::cout << result_buf[i];
        }

    }
    std::cout << "\n";
    delete[] (result_buf);

}

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

__global__ void match_shared(char* pattern, int pattern_size, char* text, int text_size, int* result_buf) {

    int t_id = blockIdx.x * blockDim.x + threadIdx.x;
    __shared__ char spattern [32];
    if(threadIdx.x < pattern_size) {
        spattern[threadIdx.x] = pattern[threadIdx.x];
    }
    __syncthreads();

    if(t_id < text_size){
        int matched = 1;
        result_buf[t_id] = -1;

        for(int i = 0; i < pattern_size; i++) {
            if(text[t_id + i] != spattern[i]) {
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

__global__ void match_chunk_shared(char* pattern, int pattern_size, int chunk_size ,char* text, int text_size, int* result_buf) {

    int t_id = blockIdx.x * blockDim.x + threadIdx.x;
    __shared__ char spattern [32];
    if(threadIdx.x == 0) {
        for(int i = 0; i < pattern_size; i++){
            spattern[i] = pattern[i];
        }
    }
    __syncthreads();
    int left_bound = t_id * chunk_size;
    // int right_bound = left_bound + chunk_size + pattern_size - 1 >= text_size ? text_size  
                                                                        //  : left_bound + chunk_size + pattern_size - 1;

    if(left_bound < text_size){
        for (int i = 0; i < chunk_size && left_bound + i < text_size; i++) {

            result_buf[left_bound + i] = -1;
            int matched = 1;
            for(int j = 0; j < pattern_size; j++) {

                if(text[left_bound + i + j] != spattern[j]) {
                    matched = -1;
                }
            }

            if(matched == 1) {
                result_buf[left_bound + i] = 1;
            }
        }
                             
    }
}

__global__ void match_chunk(char* pattern, int pattern_size, int chunk_size ,char* text, int text_size, int* result_buf) {

    int t_id = blockIdx.x * blockDim.x + threadIdx.x;
    int left_bound = t_id * chunk_size;
    // int right_bound = left_bound + chunk_size + pattern_size - 1 >= text_size ? text_size  
                                                                        //  : left_bound + chunk_size + pattern_size - 1;

    if(left_bound < text_size){
        for (int i = 0; i < chunk_size && left_bound + i < text_size; i++) {

            result_buf[left_bound + i] = -1;
            int matched = 1;
            for(int j = 0; j < pattern_size; j++) {

                if(text[left_bound + i + j] != pattern[j]) {
                    matched = -1;
                }
            }

            if(matched == 1) {
                result_buf[left_bound + i] = 1;
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

void prefix(const char* pattern, int pattern_size, int* prefix_table){
    
    prefix_table[0] = 0;
    
    for (int i = 1; i < pattern_size; ++i) {
		
        int j = prefix_table[i-1];
		
        while (j > 0 && pattern[i] != pattern[j]){
			
            j = prefix_table[j-1];
        
        }
		
        if (pattern[i] == pattern[j])  ++j;
		
        prefix_table[i] = j;
	}
}

__global__ void kmp_chunk(int* prefix_table, char* pattern,int pattern_size,char* text, int text_size, int* result_buf,int chunk){
    
    int t_id = blockIdx.x * blockDim.x + threadIdx.x;

    int left_bound = t_id * chunk;
    int right_bound = left_bound + chunk + pattern_size - 1 < text_size ? left_bound + chunk + pattern_size - 1 : text_size;

    int ams = 0;

    for(int i = left_bound; i < right_bound; i++){
        
        if (i < left_bound + chunk) {
            result_buf[i] = -1;
        }

        while(ams > 0 && pattern[ams] != text[i]){
            ams = prefix_table[ams-1];
        }

        if(text[i] == pattern[ams]){
            ams += 1;
        }
        if(ams == pattern_size) {
            result_buf[i-pattern_size + 1] = 1;
            ams = prefix_table[ams-1];
        }


    }
}

__global__ void kmp_nochunk(int* prefix_table, char* pattern,int pattern_size,char* text, int text_size, int* result_buf,int chunk){
    
    int t_id = blockIdx.x * blockDim.x + threadIdx.x;

    int ams = 0;

    for(int i = 0; i < pattern_size; i++){
        
        result_buf[t_id] = -1;

        while(ams > 0 && pattern[ams] != text[t_id + i]){
            ams = prefix_table[ams-1];
        }

        if(text[t_id + i] == pattern[ams]){
            ams += 1;
        }
        if(ams == pattern_size) {
            result_buf[t_id] = 1;
            ams = prefix_table[ams-1];
        }


    }
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

void match_naive(std::string pattern, std::string subject_string_filename, int nochunk){ //nochunk == 0 => nochunk

    if (pattern.size() > 31) {
        std::cout << "pattern should be less then or eq 31 bytes\n";
        return;
    }

    auto pattern_size = pattern.size();
    char *dpattern;
    cudaMalloc((void**)&dpattern, pattern_size * sizeof(char));
    cudaMemcpy((void*)dpattern,pattern.c_str(),pattern_size * sizeof(char),cudaMemcpyHostToDevice); 

    int text_size;
    char* dtextptr = read_file(subject_string_filename,text_size);

    int* dresult_buf;
    
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(int));
    
    int chunk = 256;

    dim3 block(1024);
    int grid_size;
    if(nochunk){
        grid_size = (text_size + block.x - 1) / block.x;
    } else{
        grid_size = (((text_size + chunk - 1) / chunk) + block.x - 1) / block.x;
    }
    dim3 grid(grid_size);

    // cudaEvent_t start, stop;
    // cudaEventCreate(&start);
    // cudaEventCreate(&stop);
    
    std::cout << "running ..." << "\n";

    am::timer time;
    time.start();
    // cudaEventRecord(start);
    if(nochunk){
        match<<<grid,block>>>(dpattern,pattern_size,dtextptr,text_size,dresult_buf);
    }else{
        match_chunk<<<grid,block>>>(dpattern,pattern_size,chunk,dtextptr,text_size,dresult_buf);
        }  
    cudaDeviceSynchronize();
    time.stop();

    std::cout << "running time " << time.milliseconds() << " ms" << std::endl;
    
    write_from_device(&dresult_buf,text_size);
    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
    cudaFree(dpattern);

}



void match_naive_shared(std::string pattern, std::string subject_string_filename, int nochunk){ //nochunk == 0 => nochunk

    if (pattern.size() > 31) {
        std::cout << "pattern should be less then or eq 31 bytes\n";
        return;
    }

    auto pattern_size = pattern.size();
    char *dpattern;
    cudaMalloc((void**)&dpattern, pattern_size * sizeof(char));
    cudaMemcpy((void*)dpattern,pattern.c_str(),pattern_size * sizeof(char),cudaMemcpyHostToDevice); 

    int text_size;
    char* dtextptr = read_file(subject_string_filename,text_size);
    
    int* dresult_buf;
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(int));
    
    int chunk = 256;

    dim3 block(1024);
    int grid_size;
    if(nochunk){
        grid_size = (text_size + block.x - 1) / block.x;
    } else{
        grid_size = (((text_size + chunk - 1) / chunk) + block.x - 1) / block.x;
    }
    dim3 grid(grid_size);

    // cudaEvent_t start, stop;
    // cudaEventCreate(&start);
    // cudaEventCreate(&stop);
    
    std::cout << "running ..." << "\n";

    am::timer time;
    time.start();
    // cudaEventRecord(start);
    if(nochunk){
        match_shared<<<grid,block>>>(dpattern,pattern_size,dtextptr,text_size,dresult_buf);
    }else{
        match_chunk_shared<<<grid,block>>>(dpattern,pattern_size,chunk,dtextptr,text_size,dresult_buf);
        }  

    cudaDeviceSynchronize();
    time.stop();

    std::cout << "running time " << time.milliseconds() << " ms" << std::endl;
    

    write_from_device(&dresult_buf,text_size);
    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
    cudaFree(dpattern);
      
}

void match_naive_pointer(std::string pattern, std::string subject_string_filename){ //nochunk == 0 => nochunk

    if (pattern.size() > 31) {
        std::cout << "pattern should be less then or eq 31 bytes\n";
        return;
    }

    auto pattern_size = pattern.size();
    char *dpattern;

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
    int grid_size;
    grid_size = (text_size + block.x - 1) / block.x;
    dim3 grid(grid_size);

    // cudaEvent_t start, stop;
    // cudaEventCreate(&start);
    // cudaEventCreate(&stop);
    
    std::cout << "running ..." << "\n";

    am::timer time;
    time.start();
    // cudaEventRecord(start);
    cudaMalloc((void**)&dpattern, pattern_size * sizeof(char));
    cudaMemcpy((void*)dpattern,pattern.c_str(),pattern_size * sizeof(char),cudaMemcpyHostToDevice); 

    match<<<grid,block>>>(dpattern,pattern_size,textptr,text_size,dresult_buf);
    // match_struct<<<grid,block>>>(dpattern_s,textptr,text_size,dresult_buf);
    // match<<<grid,block>>>(dpattern,pattern_size,textptr,text_size,dresult_buf);
    // match_multy<<<grid,block>>>(dpatterns,dsizes,argc-1,textptr,text_size,dresult_buf);
    // cudaEventRecord(stop);
    // delete[](sizes);
    cudaDeviceSynchronize();
    time.stop();

    // delete[](pattern);
    delete[](subject_string);
    std::cout << "running time " << time.milliseconds() << " ms" << std::endl;
    cudaMemcpy((void*)result_buf,dresult_buf,text_size*sizeof(int),cudaMemcpyDeviceToHost);
    // cudaEventSynchronize(stop);

    float milliseconds = 0;
    // cudaEventElapsedTime(&milliseconds, start, stop);

    // std::cout << "running time " << milliseconds << "ms" << "\n";



    for (int i = 0; i < text_size; i++) {
        std::cout << result_buf[i];
    }
    std::cout << "\n";
    
    cudaFree(dresult_buf);
    cudaFree(textptr);
    cudaFree(dpattern);
    // cudaEventDestroy(start);
    // cudaEventDestroy(stop);
    delete[] (result_buf);   
}

void match_kmp(std::string pattern, std::string subject_string_filename, int nochunk){ //nochunk == 0 => nochunk

    if (pattern.size() > 31) {
        std::cout << "pattern should be less then or eq 31 bytes\n";
        return;
    }

    auto pattern_size = pattern.size();
    char *dpattern;
    cudaMalloc((void**)&dpattern, pattern_size * sizeof(char));
    cudaMemcpy((void*)dpattern,pattern.c_str(),pattern_size * sizeof(char),cudaMemcpyHostToDevice); 

    int* prefix_table = new int[pattern_size];
    prefix(pattern.c_str(),pattern_size,prefix_table);
    int* dprefix_table;

    cudaMalloc((void**)&dprefix_table, pattern_size * sizeof(int));
    cudaMemcpy((void*)dprefix_table,prefix_table,pattern_size * sizeof(int),cudaMemcpyHostToDevice); 
    delete[](prefix_table);

    int text_size;//TODO

    char* dtextptr = read_file(subject_string_filename,text_size);
    int* dresult_buf;
    // std::cout << "text length : " << text_size << "\n";
    //think about data transfer;
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(int));
    
    int chunk = 256;

    dim3 block(1024);
    int grid_size;
    if(nochunk){
        grid_size = (text_size + block.x - 1) / block.x;
    } else{
        grid_size = (((text_size + chunk - 1) / chunk) + block.x - 1) / block.x;
    }
    dim3 grid(grid_size);

    // cudaEvent_t start, stop;
    // cudaEventCreate(&start);
    // cudaEventCreate(&stop);
    
    std::cout << "running ..." << "\n";

    am::timer time;
    time.start();
    // cudaEventRecord(start);
    if(nochunk){
        kmp_nochunk<<<grid,block>>>(dprefix_table,dpattern,pattern_size,dtextptr,text_size,dresult_buf,chunk);
    }else{
        kmp_chunk<<<grid,block>>>(dprefix_table,dpattern,pattern_size,dtextptr,text_size,dresult_buf,chunk);
        }  

    cudaDeviceSynchronize();
    time.stop();

    
    std::cout << "running time " << time.milliseconds() << " ms" << std::endl;

    write_from_device(&dresult_buf,text_size);
    
    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
    cudaFree(dpattern);
    cudaFree(dprefix_table);
    // cudaEventDestroy(start);
    // cudaEventDestroy(stop);   
}


__constant__ char c_pattern[32]; //might be as fast as registers, but not in this case =)

__global__ void match_chunk_const(int pattern_size, int chunk_size ,char* text, int text_size, int* result_buf) {

    int t_id = blockIdx.x * blockDim.x + threadIdx.x;
    int left_bound = t_id * chunk_size;
    // int right_bound = left_bound + chunk_size + pattern_size - 1 >= text_size ? text_size  
                                                                        //  : left_bound + chunk_size + pattern_size - 1;

    if(left_bound < text_size){
        for (int i = 0; i < chunk_size && left_bound + i < text_size; i++) {

            result_buf[left_bound + i] = -1;
            int matched = 1;
            for(int j = 0; j < pattern_size; j++) {

                if(text[left_bound + i + j] != c_pattern[j]) {
                    matched = -1;
                }
            }

            if(matched == 1) {
                result_buf[left_bound + i] = 1;
            }
        }
                             
    }
}

__global__ void match_const(int pattern_size, char* text, int text_size, int* result_buf) {

    int t_id = blockIdx.x * blockDim.x + threadIdx.x;

    if(t_id < text_size){
        int matched = 1;
        result_buf[t_id] = -1;

        for(int i = 0; i < pattern_size; i++) {
            if(text[t_id + i] != c_pattern[i]) {
                matched = -1;
            }
        }
        if(matched == 1) {
            result_buf[t_id] = 1;
        }             
                     

    }
}

void match_const(std::string pattern, std::string subject_string_filename, int nochunk){
    
    if (pattern.size() > 31) {
        std::cout << "pattern should be less then or eq 31 bytes\n";
        return;
    }

    auto pattern_size = pattern.size();
    cudaMemcpyToSymbol(c_pattern,(void*)pattern.c_str(),pattern.size()*sizeof(char));

    int text_size;//TODO

    char* dtextptr = read_file(subject_string_filename,text_size);

    //think about data transfer;
    int* dresult_buf;
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(int));
    

    int chunk = 256;

    dim3 block(1024);
    int grid_size;
    if(nochunk){
        grid_size = (text_size + block.x - 1) / block.x;
    } else{
        grid_size = (((text_size + chunk - 1) / chunk) + block.x - 1) / block.x;
    }
    dim3 grid(grid_size);

    // cudaEvent_t start, stop;
    // cudaEventCreate(&start);
    // cudaEventCreate(&stop);
    
    std::cout << "running ..." << "\n";

    am::timer time;
    time.start();
    // cudaEventRecord(start);
    if(nochunk){
        match_const<<<grid,block>>>(pattern_size,dtextptr,text_size,dresult_buf);
    }else{
        match_chunk_const<<<grid,block>>>(pattern_size,chunk,dtextptr,text_size,dresult_buf);
        }  
    //move results back;

    cudaDeviceSynchronize();
    time.stop();

    std::cout << "running time " << time.milliseconds() << " ms" << std::endl;

    write_from_device(&dresult_buf,text_size);
    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
}

int main(int argc, char** argv) {

    
    std::string pattern = std::string(argv[1]);
    std::string subject_string_filename("data/subject.txt");
    auto arg = std::string(argv[2]) + std::string(argv[3]);
    
    if(arg == "naive1"){
    
            match_naive(pattern,subject_string_filename,1);
    
    }else if(arg == "naive0"){
            
            match_naive(pattern,subject_string_filename,0);

    }else if(arg == "kmp1") {
            
            match_kmp(pattern,subject_string_filename,1);
    
    }else if(arg == "kmp0") {
            match_kmp(pattern,subject_string_filename,0);
            

    }else if(arg == "const1") {
            match_const(pattern,subject_string_filename,1);
    }else if(arg == "const0"){
            match_const(pattern,subject_string_filename,0);
    }else if(arg == "naivesh1"){
            match_naive_shared(pattern,subject_string_filename,1);
    }else if(arg == "naivesh0"){
            match_naive_shared(pattern,subject_string_filename,0);
    }else{

    }
    // match_naive(pattern,subject_string_filename,atoi(argv[2]));
    // match_naive_pointer(pattern,subject_string_filename);
    // match_kmp(pattern,subject_string_filename,1);

    return 0;
}
