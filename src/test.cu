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
#include <math.h>
#include "timer.h"
#include "cxxopts.hpp"


#define block_size 1024

typedef struct Template{

    char array[32] = {0};
    int size;

}Template;

__device__ long threadId(){
    
    long blockId = (long)blockIdx.y * (long)gridDim.x + (long)blockIdx.x;
    long threadId = blockId * (long)blockDim.x + (long)threadIdx.x;
    return threadId;

}

long GetFileSize(std::string filename)
{
    // struct stat stat_buf;
    // int rc = stat(filename.c_str(), &stat_buf);
    // return rc == 0 ? stat_buf.st_size : -1;
    int fd = open(filename.c_str(),O_RDONLY);  //;
    long size = lseek(fd, 0, SEEK_END);
    close(fd);
    return size;
}

std::vector<std::string> read_pattern(std::string filename){
    
    std::ifstream file(filename);
    std::vector<std::string> res = std::vector<std::string>();
 
    if (!file) 
    {
        std::cout << "error openning pattern file" << "\n"; 
    // TODO: assign item_name based on line (or if the entire line is 
    // the item name, replace line with item_name in the code above)
    }
    while(!file.eof()){
        std::string str;
        std::getline(file, str);
        res.push_back(str);
    }
    // std::getline(file, str);
    return res;

}

char* read_file(std::string filename,long &text_size,long size = 0, long offset = 0){
    
    long f_size = GetFileSize(filename) - 1;//TODO
    if(f_size == -1){
        std::cout << "bad_size" << "\n";
        return nullptr;
    }
    //read file
    FILE *f;
    if((f = fopen(filename.c_str(), "rb")) == NULL){
	    std::cout << "can not oppen file" << filename << "\n";
	    return nullptr;
    }

    if(size != 0 && size <= f_size){
        text_size = size;
    }else{
        text_size = f_size;
    }

    if(offset != 0){
        fseek(f,offset * sizeof(char),SEEK_CUR);
        if((f_size - offset) < size){
            text_size = f_size - offset;
        }
    }
    int text_chunk = 128 * 1024 * 1024;
    if(text_size < text_chunk) {
        text_chunk = text_size;
    }
    char *subject_string = new char[text_chunk];

    char* dtextptr;
    
    cudaMalloc((void**)&dtextptr, text_size * sizeof(char));

    long nbytes;

    for(long i = 0; i < (text_size + text_chunk - 1) / text_chunk; i++){//number of chunks
        
        if(feof(f)){
            std::cout << "premature end of file" << "\n";
            break;
        }

        long right_bound = (i+1) * text_chunk < text_size ? (i+1) * text_chunk : text_size;
        long left_bound = i * text_chunk;
        nbytes = fread(subject_string,sizeof(char),right_bound-(left_bound),f);
        cudaMemcpy((void*)(dtextptr + left_bound),subject_string,nbytes,cudaMemcpyHostToDevice);

    }

    delete[](subject_string);
    fclose(f);

    return dtextptr;
}

void write_from_device(char** dresult_buf,int text_size){

    int text_chunk = 128 * 1024 * 1024;
    if(text_size < text_chunk) {
        text_chunk = text_size;
    }

    char* result_buf = new char[text_chunk];


    for(int i = 0; i < (text_size + text_chunk - 1) / text_chunk; i++){ //number of chunks

        int right_bound = (i+1) * text_chunk < text_size ? (i+1) * text_chunk : text_size;
        int left_bound = i * text_chunk;

        cudaMemcpy((void*)(result_buf),((*dresult_buf)+left_bound),(right_bound-(left_bound))*sizeof(char),cudaMemcpyDeviceToHost);
        
        for (int i = 0; i < (right_bound-left_bound); i++) {
            std::cout << result_buf[i];
        }

    }
    std::cout << "\n";
    delete[] (result_buf);

}

__global__ void match(char* pattern, int pattern_size, char* text, long text_size, char* result_buf) {


    long t_id = threadId();

    if(t_id < text_size){
        int matched = 1;
        result_buf[t_id] = '0';

        if(t_id < text_size - pattern_size + 1){
            
            for(int i = 0; i < pattern_size; i++) {
                if(text[t_id + i] != pattern[i]) {
                    matched = -1;
                    return;
                }
            }
            if(matched == 1) {
                result_buf[t_id] = '1';
            }             
        }
                     

    }
}

__global__ void match_shared(char* pattern, int pattern_size, char* text, long text_size, char* result_buf) {

    long t_id = threadId();
    __shared__ char spattern [128];
    if(threadIdx.x < pattern_size) {
        spattern[threadIdx.x] = pattern[threadIdx.x];
    }
    __syncthreads();

    if(t_id < text_size){
        
        int matched = 1;
        result_buf[t_id] = '0';

        if(t_id < text_size - pattern_size + 1){
            
            for(int i = 0; i < pattern_size; i++) {
                if(text[t_id + i] != spattern[i]) {
                    matched = -1;
                    return;
                }
            }
            if(matched == 1) {
                result_buf[t_id] = '1';
            }             
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
                    break;
                }
            }

            p_offset += p_sizes[i]; 
            
            if(matched != -1) {
                result_buf[t_id] = i;
            }
        }             
    }
}

__global__ void match_chunk_shared(char* pattern, int pattern_size, int chunk_size ,char* text, long text_size, char* result_buf) {

    long t_id = threadId();
    __shared__ char spattern [128];
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

            result_buf[left_bound + i] = '0';
            int matched = 1;
            if(i < text_size - left_bound - pattern_size + 1){
                #pragma unroll
                for(int j = 0; j < pattern_size; j++) {

                    if(text[left_bound + i + j] != spattern[j]) {
                        matched = -1;
                        break;
                    }
                }

                if(matched == 1) {
                    result_buf[left_bound + i] = '1';
                }
            }
        }
                             
    }
}

__global__ void match_chunk(char* pattern, int pattern_size, int chunk_size ,char* text, long text_size, char* result_buf) {

    long t_id = threadId();
    long left_bound = t_id * chunk_size;
    // int right_bound = left_bound + chunk_size + pattern_size - 1 >= text_size ? text_size  
                                                                        //  : left_bound + chunk_size + pattern_size - 1;

    if(left_bound < text_size){
        for (long i = 0; i < chunk_size && left_bound + i < text_size; i++) {

            result_buf[left_bound + i] = '0';
            int matched = 1;
            
            for(int j = 0; j < pattern_size; j++) {

                if(text[left_bound + i + j] != pattern[j]) {
                    matched = -1;
                    break;
                }
            }

            if(matched == 1) {
                result_buf[left_bound + i] = '1';
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

__global__ void kmp_chunk(int* prefix_table, char* pattern,int pattern_size,char* text, long text_size, char* result_buf,int chunk){
    
    long t_id = threadId();

    long left_bound = t_id * chunk;
    long right_bound = left_bound + chunk + pattern_size - 1 < text_size ? left_bound + chunk + pattern_size - 1 : text_size;

    int ams = 0;

    for(long i = left_bound; i < right_bound; i++){
        
        if (i < left_bound + chunk) {
            result_buf[i] = '0';
        }

        while(ams > 0 && pattern[ams] != text[i]){
            ams = prefix_table[ams-1];
        }

        if(text[i] == pattern[ams]){
            ams += 1;
        }
        if(ams == pattern_size) {
            result_buf[i-pattern_size + 1] = '1';
            ams = prefix_table[ams-1];
        }


    }
}


__global__ void kmp_nochunk(int* prefix_table, char* pattern,int pattern_size,char* text, int text_size, char* result_buf,int chunk){
    
    long t_id = threadId();

    long left_bound = t_id * chunk;
    long right_bound = left_bound + chunk + pattern_size - 1 < text_size ? left_bound + chunk + pattern_size - 1 : text_size;

    int ams = 0;

    for(long i = left_bound; i < right_bound; i++){
        
        if (i < left_bound + chunk) {
            result_buf[i] = '0';
        }

        while(ams > 0 && pattern[ams] != text[i]){
            ams = prefix_table[ams-1];
        }

        if(text[i] == pattern[ams]){
            ams += 1;
        }
        if(ams == pattern_size) {
            result_buf[i-pattern_size + 1] = '1';
            ams = prefix_table[ams-1];
        }


    }
}


void multipattern_match(int p_number,std::vector<std::string> vpatterns, char* file_name){

    int* sizes = new int[vpatterns.size()];
    int len = 0;
    for(int i = 0; i < vpatterns.size(); i++) {
        sizes[i] = vpatterns[i].length();
        len += sizes[i];    
    }

    char* patterns = new char[len];
    
    int offset = 0;

    char* dpatterns;
    int* dsizes;
    
    cudaMalloc((void**)&dsizes, (vpatterns.size())*sizeof(int));
    cudaMemcpy((void*)dsizes, sizes, (vpatterns.size())*sizeof(int), cudaMemcpyHostToDevice); 
    
    cudaMalloc((void**)&dpatterns, len * sizeof(char));
    
    for(int i = 0; i < vpatterns.size(); i++){
        cudaMemcpy((void*)(dpatterns + offset*sizeof(char)),vpatterns[i].c_str(),vpatterns[i].size(),cudaMemcpyHostToDevice);
        offset+=sizes[i];
    }

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
    
    dim3 block(block_size);
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
    cudaDeviceSynchronize();
    time.stop();
    delete[](sizes);
    delete[](patterns);
    delete[](subject_string);
    
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

void match_naive(std::string pattern, std::string subject_string_filename, int nochunk, int size, int offset){ //nochunk == 0 => nochunk

    if (pattern.size() > 128) {
        std::cout << "pattern should be less then or eq 128 bytes\n";
        return;
    }

    auto pattern_size = pattern.size();
    
    char* dtextptr;
    long text_size;

    if((dtextptr = read_file(subject_string_filename,text_size,size,offset)) == nullptr){
        std::cout << "error opening file" << "\n";
        return;
    }
    
    char *dpattern;
    cudaMalloc((void**)&dpattern, pattern_size * sizeof(char));
    cudaMemcpy((void*)dpattern,pattern.c_str(),pattern_size * sizeof(char),cudaMemcpyHostToDevice); 

    char* dresult_buf;
    
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(char));
    
    int chunk = 256;

    dim3 block(block_size);
    long grid_size;
    long gsqrt;
    am::timer time;
    std::cout << "running ..." << "\n";
    time.start();
    
    if(nochunk){
        grid_size = (text_size + (long)block.x - 1L) / (long)block.x;
        gsqrt = (int)sqrt(grid_size) + 1;
        dim3 grid(gsqrt,gsqrt);
        match<<<grid,block>>>(dpattern,pattern_size,dtextptr,text_size,dresult_buf);
        cudaDeviceSynchronize();
        time.stop();
    } else{
        grid_size = (((text_size + (long)chunk - (long)1) / (long)chunk) + (long)block.x - 1L) / (long)block.x;
        gsqrt = (int)sqrt(grid_size) + 1;
        dim3 grid(gsqrt,gsqrt);
        match_chunk<<<grid,block>>>(dpattern,pattern_size,chunk,dtextptr,text_size,dresult_buf);
        cudaDeviceSynchronize();
        time.stop();
    }

    std::cout << "running time " << time.milliseconds() << " ms" << std::endl;
    
    write_from_device(&dresult_buf,text_size);
    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
    cudaFree(dpattern);

}



void match_naive_shared(std::string pattern, std::string subject_string_filename, int nochunk,int size, int offset){ //nochunk == 0 => nochunk

    if (pattern.size() > 128) {
        std::cout << "pattern should be less then or eq 128 bytes\n";
        return;
    }

    char* dtextptr;
    long text_size;
    if((dtextptr = read_file(subject_string_filename,text_size,size,offset)) == nullptr){
        std::cout << "error opening file" << "\n";
        return;
    }

    auto pattern_size = pattern.size();
    char *dpattern;
    cudaMalloc((void**)&dpattern, pattern_size * sizeof(char));
    cudaMemcpy((void*)dpattern,pattern.c_str(),pattern_size * sizeof(char),cudaMemcpyHostToDevice); 

    char* dresult_buf;
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(char));
    
    int chunk = 256;

    dim3 block(block_size);
    long grid_size;
    long gsqrt;
    am::timer time;
    std::cout << "running ..." << "\n";
    time.start();
    
    if(nochunk){
        grid_size = (text_size + (long)block.x - 1L) / (long)block.x;
        gsqrt = (int)sqrt(grid_size) + 1;
        dim3 grid(gsqrt,gsqrt);
        match_shared<<<grid,block>>>(dpattern,pattern_size,dtextptr,text_size,dresult_buf);
        cudaDeviceSynchronize();
        time.stop();
    } else{
        grid_size = (((text_size + (long)chunk - (long)1) / (long)chunk) + (long)block.x - 1L) / (long)block.x;
        gsqrt = (int)sqrt(grid_size) + 1;
        dim3 grid(gsqrt,gsqrt);
        match_chunk_shared<<<grid,block>>>(dpattern,pattern_size,chunk,dtextptr,text_size,dresult_buf);
        cudaDeviceSynchronize();
        time.stop();
    }

    std::cout << "running time " << time.milliseconds() << " ms" << std::endl;    

    write_from_device(&dresult_buf,text_size);
    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
    cudaFree(dpattern);
      
}


void match_kmp(std::string pattern, std::string subject_string_filename, int nochunk,int size,int offset){ //nochunk == 0 => nochunk

    auto pattern_size = pattern.size();
    
    char* dtextptr;
    long text_size;
    if((dtextptr = read_file(subject_string_filename,text_size,size,offset)) == nullptr){
        std::cout << "error opening file" << "\n";
        return;
    }
    
    char *dpattern;
    cudaMalloc((void**)&dpattern, pattern_size * sizeof(char));
    cudaMemcpy((void*)dpattern,pattern.c_str(),pattern_size * sizeof(char),cudaMemcpyHostToDevice); 

    int* prefix_table = new int[pattern_size];
    prefix(pattern.c_str(),pattern_size,prefix_table);
    int* dprefix_table;

    cudaMalloc((void**)&dprefix_table, pattern_size * sizeof(int));
    cudaMemcpy((void*)dprefix_table,prefix_table,pattern_size * sizeof(int),cudaMemcpyHostToDevice); 
    delete[](prefix_table);

    char* dresult_buf;
    // std::cout << "text length : " << text_size << "\n";
    //think about data transfer;
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(char));
    
    int chunk = 256;

    dim3 block(block_size);
    long grid_size;
    long gsqrt;
    am::timer time;
    std::cout << "running ..." << "\n";
    time.start();
    
    if(nochunk){
        grid_size = (text_size + (long)block.x - 1L) / (long)block.x;
        gsqrt = (int)sqrt(grid_size) + 1;
        dim3 grid(gsqrt,gsqrt);
        kmp_nochunk<<<grid,block>>>(dprefix_table,dpattern,pattern_size,dtextptr,text_size,dresult_buf,chunk);
        cudaDeviceSynchronize();
        time.stop();
    } else{
        grid_size = (((text_size + (long)chunk - (long)1) / (long)chunk) + (long)block.x - 1L) / (long)block.x;
        gsqrt = (int)sqrt(grid_size) + 1;
        dim3 grid(gsqrt,gsqrt);
        kmp_chunk<<<grid,block>>>(dprefix_table,dpattern,pattern_size,dtextptr,text_size,dresult_buf,chunk);
        cudaDeviceSynchronize();
        time.stop();
    }
    std::cout << "running time " << time.milliseconds() << " ms" << std::endl;

    write_from_device(&dresult_buf,text_size);
    
    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
    cudaFree(dpattern);
    cudaFree(dprefix_table); 
}


__constant__ char c_pattern[128]; //might be as fast as registers, but not in this case =)

__global__ void match_chunk_const(int pattern_size, int chunk_size ,char* text, long text_size, char* result_buf) {

    long t_id = threadId();
    long left_bound = t_id * chunk_size;
    // int right_bound = left_bound + chunk_size + pattern_size - 1 >= text_size ? text_size  
                                                                        //  : left_bound + chunk_size + pattern_size - 1;

    if(left_bound < text_size){
        for (long i = 0; i < chunk_size && left_bound + i < text_size; i++) {

            result_buf[left_bound + i] = '0';
            int matched = 1;

            for(int j = 0; j < pattern_size; j++) {
                
                if(text[left_bound + i + j] != c_pattern[j]) {
                    matched = -1;
                    break;
                }
            }

            if(matched == 1) {
                result_buf[left_bound + i] = '1';
            }
        }
                             
    }
}

__global__ void match_const(int pattern_size, char* text, long text_size, char* result_buf) {

    long t_id = threadId();

    if(t_id < text_size){
        int matched = 1;
        result_buf[t_id] = '0';
        if(t_id < text_size - pattern_size + 1){

            for(int i = 0; i < pattern_size; i++) {
                if(text[t_id + i] != c_pattern[i]) {
                    matched = -1;
                    return;
                }
            }
            if(matched == 1) {
                result_buf[t_id] = '1';
            }             
        }
                     

    }
}

__constant__ int c_prefix[128];

__global__ void kmp_chunk_const(int pattern_size,char* text, int text_size, char* result_buf,int chunk){
    
    long t_id = threadId();

    long left_bound = t_id * chunk;
    long right_bound = left_bound + chunk + pattern_size - 1 < text_size ? left_bound + chunk + pattern_size - 1 : text_size;

    int ams = 0;

    for(long i = left_bound; i < right_bound; i++){
        
        if (i < left_bound + chunk) {
            result_buf[i] = '0';
        }

        while(ams > 0 && c_pattern[ams] != text[i]){
            ams = c_prefix[ams-1];
        }

        if(text[i] == c_pattern[ams]){
            ams += 1;
        }
        if(ams == pattern_size) {
            result_buf[i-pattern_size + 1] = '1';
            ams = c_prefix[ams-1];
        }


    }
}

void match_naive_const(std::string pattern, std::string subject_string_filename, int nochunk,int size, int offset){
    
    if (pattern.size() > 128) {
        std::cout << "pattern should be less then or eq 128 bytes\n";
        return;
    }

    auto pattern_size = pattern.size(); // <= 128
    cudaMemcpyToSymbol(c_pattern,(void*)pattern.c_str(),pattern.size()*sizeof(char));

    // int* prefix_table = new int[pattern_size];
    // prefix(pattern.c_str(),pattern_size,prefix_table);
    // cudaMemcpyToSymbol(c_prefix,(void*)prefix_table,pattern.size()*sizeof(int));
    // delete[](prefix_table);

    long text_size;//TODO

    char* dtextptr;
    if((dtextptr = read_file(subject_string_filename,text_size,size,offset)) == nullptr){
        std::cout << "error opening file" << "\n";
        return;
    }
    //think about data transfer;
    char* dresult_buf;
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(char));
    

    int chunk = 256;

    dim3 block(block_size);
    long grid_size;
    long gsqrt;
    am::timer time;
    std::cout << "running ..." << "\n";
    time.start();
    
    if(nochunk){
        grid_size = (text_size + (long)block.x - 1L) / (long)block.x;
        gsqrt = (int)sqrt(grid_size) + 1;
        dim3 grid(gsqrt,gsqrt);
        match_const<<<grid,block>>>(pattern_size,dtextptr,text_size,dresult_buf);
        cudaDeviceSynchronize();
        time.stop();
    } else{
        grid_size = (((text_size + (long)chunk - (long)1) / (long)chunk) + (long)block.x - 1L) / (long)block.x;
        gsqrt = (int)sqrt(grid_size) + 1;
        dim3 grid(gsqrt,gsqrt);
        match_chunk_const<<<grid,block>>>(pattern_size,chunk,dtextptr,text_size,dresult_buf);
        cudaDeviceSynchronize();
        time.stop();
    }

    std::cout << "running time " << time.milliseconds() << " ms" << std::endl;

    write_from_device(&dresult_buf,text_size);
    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
}

void match_kmp_const(std::string pattern, std::string subject_string_filename, int nochunk,int size, int offset){
    
    if (pattern.size() > 128) {
        std::cout << "pattern should be less then or eq 128 bytes\n";
        return;
    }

    auto pattern_size = pattern.size(); // <= 128
    cudaMemcpyToSymbol(c_pattern,(void*)pattern.c_str(),pattern.size()*sizeof(char));

    int* prefix_table = new int[pattern_size];
    prefix(pattern.c_str(),pattern_size,prefix_table);
    cudaMemcpyToSymbol(c_prefix,(void*)prefix_table,pattern.size()*sizeof(int));
    delete[](prefix_table);

    long text_size;//TODO

    char* dtextptr;
    if((dtextptr = read_file(subject_string_filename,text_size,size,offset)) == nullptr){
        std::cout << "error opening file" << "\n";
        return;
    }
    //think about data transfer;
    char* dresult_buf;
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(char));
    

    int chunk = 256;

    dim3 block(block_size);
    long grid_size;
    long gsqrt;
    am::timer time;
    std::cout << "running ..." << "\n";
    time.start();
    
    if(nochunk){
        grid_size = (text_size + (long)block.x - 1L) / (long)block.x;
        gsqrt = (int)sqrt(grid_size) + 1;
        dim3 grid(gsqrt,gsqrt);
        match_const<<<grid,block>>>(pattern_size,dtextptr,text_size,dresult_buf);
        cudaDeviceSynchronize();
        time.stop();
    } else{
        grid_size = (((text_size + (long)chunk - (long)1) / (long)chunk) + (long)block.x - 1L) / (long)block.x;
        gsqrt = (int)sqrt(grid_size) + 1;
        dim3 grid(gsqrt,gsqrt);
        kmp_chunk_const<<<grid,block>>>(pattern_size,dtextptr,text_size,dresult_buf,chunk);
        cudaDeviceSynchronize();
        time.stop();
    }

    std::cout << "running time " << time.milliseconds() << " ms" << std::endl;

    write_from_device(&dresult_buf,text_size);
    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
}

int main(int argc, char** argv) {

    
    int size = 0;
    int offset = 0;
    int type = 0;
    
    cxxopts::Options options("as", " - example command line options");

    options.add_options()("p,pattern","pattern to look for",cxxopts::value<std::string>())
                         ("f,filename","filename/devicename to look for in",cxxopts::value<std::string>())
                         ("s,size", "size of data to read",cxxopts::value<int>(size)->default_value("0"))
                         ("o,offset", "offset of data to read",cxxopts::value<int>(offset)->default_value("0"))
                         ("a,algorithm","algorithm to look for with",cxxopts::value<std::string>())
                         ("t,type","type of algorithm: 0 stands for nochunk-based and 1 for chunk-based",cxxopts::value<int>(type));
    // std::string subject_string_filename("data/subject.txt");

    auto result = options.parse(argc, argv);

    if(result.count("algorithm") && result.count("type") && result.count("pattern") && result.count("filename")){
        auto alg_name = result["algorithm"].as<std::string>();
        auto filename = result["filename"].as<std::string>();
        auto patterns = read_pattern(result["pattern"].as<std::string>());
        std::string pattern; 
        if(patterns.size() == 1){
            pattern = patterns[0];
        } //if contains \x00 --- considered empty
        if(type == 1 || type == 0){
            if(alg_name == "naive"){
                match_naive(pattern,filename,type,size,offset);
            }else if(alg_name == "naivec"){
                match_naive_const(pattern,filename,type,size,offset);
            }else if(alg_name == "naivesh"){
                match_naive_shared(pattern,filename,type,size,offset);
            }else if(alg_name == "kmp"){
                match_kmp_const(pattern,filename,0,size,offset);
            }
        }else{
            std::cout << "type should be either 1 or 0" << "\n";
        }
    }else{
        std::cout << "algorithm name shoud be specified with --algorithm=name and type with --type=type" << "\n";
    }    

    return 0;
}
