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

//CPU timer
#include "../include/timer.h"
//arg parsing
#include "../include/cxxopts.hpp"


#define block_size BLOCK_SIZE

#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true)
{
   if (code != cudaSuccess) 
   {
      fprintf(stderr,"GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
      if (abort) exit(code);
   }
}

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
    
    std::ifstream file(filename,std::ios::binary);
    std::vector<std::string> res = std::vector<std::string>();
 
    if (!file) 
    {
        std::cout << "error openning pattern file" << "\n"; 
        return res;
    // TODO: assign item_name based on line (or if the entire line is 
    // the item name, replace line with item_name in the code above)
    }
    while(!file.eof()){

        std::string str;
        std::getline(file,str,'\0');
        res.push_back(str);
    }

    return res;

}

char* read_file(std::string filename,long &text_size,long size = 0, long offset = 0){
    
    long f_size = GetFileSize(filename);//TODO
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

void write_from_device(char** dresult_buf,long text_size){

    int text_chunk = 128 * 1024 * 1024;
    if(text_size < text_chunk) {
        text_chunk = text_size;
    }

    char* result_buf = new char[text_chunk];


    for(long i = 0; i < (text_size + text_chunk - 1) / text_chunk; i++){ //number of chunks

        int right_bound = (i+1) * text_chunk < text_size ? (i+1) * text_chunk : text_size;
        int left_bound = i * text_chunk;

        cudaMemcpy((void*)(result_buf),((*dresult_buf)+left_bound),(right_bound-(left_bound))*sizeof(char),cudaMemcpyDeviceToHost);
        
        for (long i = 0; i < (right_bound-left_bound); i++) {
            std::cout << (int)(result_buf[i]);
        }

    }
    std::cout << "\n";
    delete[] (result_buf);

}

__global__ void match(char* pattern, int pattern_size, char* text, long text_size, char* result_buf) {


    long t_id = threadId();

    if(t_id < text_size){
        int matched = 1;
        result_buf[t_id] = 0;

        if(t_id < text_size - pattern_size + 1){
            
            for(int i = 0; i < pattern_size; i++) {
                if(text[t_id + i] != pattern[i]) {
                    matched = -1;
                    return;
                }
            }
            if(matched == 1) {
                result_buf[t_id] = 1;
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
        result_buf[t_id] = 0;

        if(t_id < text_size - pattern_size + 1){
            
            for(int i = 0; i < pattern_size; i++) {
                if(text[t_id + i] != spattern[i]) {
                    matched = -1;
                    return;
                }
            }
            if(matched == 1) {
                result_buf[t_id] = 1;
            }             
        }
                     
    }
}

__global__ void match_multy(char* patterns, int* p_sizes, int p_number, char* text, long text_size, char* result_buf) {

    long t_id = threadId();

    if(t_id < text_size){
        int p_offset = 0;
        int matched = 1;
        
        result_buf[t_id] = 0;

        for(int i = 0; i < p_number; i++) {//for each pattern
            matched = 1;
            if(t_id < text_size - p_sizes[i] + 1) {
                for(int j = 0; j < p_sizes[i]; j++) {
                
                    if(text[t_id + j] != patterns[j+p_offset]) {
                        matched = -1;
                        break;
                    }
                } 
            
                if(matched == 1) {
                    result_buf[t_id] = i+1; // 0 stands for missmatch
                }
            }
            p_offset += p_sizes[i];
        }             
    }
}

__constant__ char mpatterns[128*64];
__constant__ int cp_sizes[64];
__global__ void match_multy_const(int p_number, char* text, long text_size, char* result_buf) {

    long t_id = threadId();

    if(t_id < text_size){
        int p_offset = 0;
        int matched = 1;
        result_buf[t_id] = 0;

        for(int i = 0; i < p_number; i++) {//for each pattern
            matched = 1;
            if(t_id < text_size - cp_sizes[i] + 1){
                for(int j = 0; j < cp_sizes[i]; j++) {
            
                    if(text[t_id + j] != mpatterns[j + p_offset]) {
                        matched = -1;
                        
                        break;
                    }
                } 
            
                if(matched == 1) {
                    result_buf[t_id] = i+1; // 0 stands for missmatch
                }
            }
            p_offset += cp_sizes[i];
        }             
    }
}

__global__ void match_multy_shared(char* patterns, int* p_sizes, int p_number,int p_len, char* text, long text_size, char* result_buf){
    
    //assume that blockSize >= p_len
    extern __shared__ char sPatterns[];
    if (threadIdx.x < p_len){
        sPatterns[threadIdx.x] = patterns[threadIdx.x];
    }
    __syncthreads();

    long t_id = threadId();

    if(t_id < text_size){

        int p_offset = 0;
        int matched = 1;

        result_buf[t_id] = 0;

        for(int i = 0; i < p_number; i++) {//for each pattern
            matched = 1;
            if(t_id < text_size - p_sizes[i] + 1){
                for(int j = 0; j < p_sizes[i]; j++) {
            
                    if(text[t_id + j] != sPatterns[j + p_offset]) {
                        matched = -1;
                        
                        break;
                    }
                } 
            
                if(matched == 1) {
                    result_buf[t_id] = i+1; // 0 stands for missmatch
                }
            }
            p_offset += p_sizes[i];
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

            result_buf[left_bound + i] = 0;
            int matched = 1;
            if(i < text_size - left_bound - pattern_size + 1){

                for(int j = 0; j < pattern_size; j++) {

                    if(text[left_bound + i + j] != spattern[j]) {
                        matched = -1;
                        break;
                    }
                }

                if(matched == 1) {
                    result_buf[left_bound + i] = 1;
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

            result_buf[left_bound + i] = 0;
            int matched = 1;
            
            for(int j = 0; j < pattern_size; j++) {

                if(text[left_bound + i + j] != pattern[j]) {
                    matched = -1;
                    break;
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

__global__ void kmp_chunk(int* prefix_table, char* pattern,int pattern_size,char* text, long text_size, char* result_buf,int chunk){
    
    long t_id = threadId();

    long left_bound = t_id * chunk;
    long right_bound = left_bound + chunk + pattern_size - 1 < text_size ? left_bound + chunk + pattern_size - 1 : text_size;

    int ams = 0;

    for(long i = left_bound; i < right_bound; i++){
        
        if (i < left_bound + chunk) {
            result_buf[i] = 0;
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


__global__ void kmp_nochunk(int* prefix_table, char* pattern,int pattern_size,char* text, int text_size, char* result_buf,int chunk){
    
    long t_id = threadId();

    long left_bound = t_id * chunk;
    long right_bound = left_bound + chunk + pattern_size - 1 < text_size ? left_bound + chunk + pattern_size - 1 : text_size;

    int ams = 0;

    for(long i = left_bound; i < right_bound; i++){
        
        if (i < left_bound + chunk) {
            result_buf[i] = 0;
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


void multipattern_match(std::vector<std::string> vpatterns, std::string file_name,long size, long offset,int verbose){

    int* sizes = new int[vpatterns.size()];

    int len = 0;
    for(int i = 0; i < vpatterns.size(); i++) {
        sizes[i] = vpatterns[i].size();
        len += sizes[i];    
    }
    
    int loffset = 0;

    char* dpatterns;
    int* dsizes;

    char* dtextptr;
    long text_size;

    if((dtextptr = read_file(file_name,text_size,size,offset)) == nullptr){
        std::cout << "error opening file" << "\n";
        return;
    }
    
    cudaMalloc((void**)&dsizes, (vpatterns.size())*sizeof(int));
    cudaMemcpy((void*)dsizes, sizes, (vpatterns.size())*sizeof(int), cudaMemcpyHostToDevice); 
    
    cudaMalloc((void**)&dpatterns, len * sizeof(char));
    
    for(int i = 0; i < vpatterns.size(); i++){
        cudaMemcpy((void*)(dpatterns + loffset*sizeof(char)),vpatterns[i].c_str(),vpatterns[i].size(),cudaMemcpyHostToDevice);
        loffset += sizes[i];
    }
    
    char* dresult_buf;
    
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(char));
    
    //nochunk only
    dim3 block(block_size);
    long grid_size;
    long gsqrt;
    am::timer time;
    std::cout << "running ..." << "\n";
    time.start();

    grid_size = (text_size + (long)block.x - 1L) / (long)block.x;
    gsqrt = (int)sqrt(grid_size) + 1;
    dim3 grid(gsqrt,gsqrt);
    match_multy<<<grid,block>>>(dpatterns,dsizes,vpatterns.size(),dtextptr,text_size,dresult_buf);
    cudaDeviceSynchronize();
    time.stop();

    
    delete[](sizes);
    
    
    std::cout << "running time " << time.milliseconds() << " ms" << std::endl;
    
    if(verbose){
        write_from_device(&dresult_buf,text_size);
    }
    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
    cudaFree(dpatterns);
    cudaFree(dsizes);
    // cudaEventDestroy(start);
    // cudaEventDestroy(stop);  
}

void multipattern_match_const(std::vector<std::string> vpatterns, std::string file_name,long size, long offset,int verbose){

    int* sizes = new int[vpatterns.size()];

    int len = 0;
    for(int i = 0; i < vpatterns.size(); i++) {
        sizes[i] = vpatterns[i].size();
        len += sizes[i];     
    }
    
    int loffset = 0;

    // char* dpatterns;
    // int* dsizes;

    char* dtextptr;
    long text_size;

    if((dtextptr = read_file(file_name,text_size,size,offset)) == nullptr){
        std::cout << "error opening file" << "\n";
        return;
    }
    
    // cudaMalloc((void**)&dsizes, (vpatterns.size())*sizeof(int));
    
    cudaMemcpyToSymbol(cp_sizes, sizes, vpatterns.size() * sizeof(int)); 
    
    
    
    // cudaMalloc((void**)&dpatterns, len * sizeof(char));
    
    for(int i = 0; i < vpatterns.size(); i++){
        cudaMemcpyToSymbol(mpatterns,vpatterns[i].c_str(),vpatterns[i].size(),loffset);
        loffset += sizes[i];
    }
    
    char* dresult_buf;
    
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(char));
    
    //nochunk only
    dim3 block(block_size);
    long grid_size;
    long gsqrt;
    am::timer time;
    std::cout << "running ..." << "\n";
    time.start();

    grid_size = (text_size + (long)block.x - 1L) / (long)block.x;
    gsqrt = (int)sqrt(grid_size) + 1;
    dim3 grid(gsqrt,gsqrt);
    match_multy_const<<<grid,block>>>(vpatterns.size(),dtextptr,text_size,dresult_buf);
    cudaDeviceSynchronize();
    time.stop();

    
    delete[](sizes);
    
    
    std::cout << "running time " << time.milliseconds() << " ms" << std::endl;
    
    if(verbose){
        write_from_device(&dresult_buf,text_size);
    }
    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
    // cudaFree(dpatterns);
    // cudaFree(dsizes);
    // cudaEventDestroy(start);
    // cudaEventDestroy(stop);
}

void multipattern_match_shared(std::vector<std::string> vpatterns, std::string file_name,long size, long offset,int verbose){

    int* sizes = new int[vpatterns.size()];

    int len = 0;
    for(int i = 0; i < vpatterns.size(); i++) {
        sizes[i] = vpatterns[i].size();
        len += sizes[i];    
    }
    
    int loffset = 0;

    char* dpatterns;
    int* dsizes;

    char* dtextptr;
    long text_size;

    if((dtextptr = read_file(file_name,text_size,size,offset)) == nullptr){
        std::cout << "error opening file" << "\n";
        return;
    }
    
    cudaMalloc((void**)&dsizes, (vpatterns.size())*sizeof(int));
    cudaMemcpy((void*)dsizes, sizes, (vpatterns.size())*sizeof(int), cudaMemcpyHostToDevice); 
    
    cudaMalloc((void**)&dpatterns, len * sizeof(char));
    
    for(int i = 0; i < vpatterns.size(); i++){
        cudaMemcpy((void*)(dpatterns + loffset*sizeof(char)),vpatterns[i].c_str(),vpatterns[i].size(),cudaMemcpyHostToDevice);
        loffset += sizes[i];
    }
    
    char* dresult_buf;
    
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(char));
    
    //nochunk only
    dim3 block(block_size);
    long grid_size;
    long gsqrt;
    am::timer time;
    std::cout << "running ..." << "\n";
    time.start();

    grid_size = (text_size + (long)block.x - 1L) / (long)block.x;
    gsqrt = (int)sqrt(grid_size) + 1;
    dim3 grid(gsqrt,gsqrt);
    match_multy_shared<<<grid,block,len * sizeof(char)>>>(dpatterns,dsizes,vpatterns.size(),len,dtextptr,text_size,dresult_buf);
    cudaDeviceSynchronize();
    time.stop();

    
    delete[](sizes);
    
    
    std::cout << "running time " << time.milliseconds() << " ms" << std::endl;
    
    if(verbose){
        write_from_device(&dresult_buf,text_size);
    }
    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
    cudaFree(dpatterns);
    cudaFree(dsizes);
    // cudaEventDestroy(start);
    // cudaEventDestroy(stop);  
}

void match_naive(std::string pattern, std::string subject_string_filename, int nochunk, long size, long offset,int verbose){ //nochunk == 0 => nochunk

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
    
    if(verbose){
        write_from_device(&dresult_buf,text_size);
    }

    cudaFree(dresult_buf);
    cudaFree(dtextptr);
    cudaFree(dpattern);

}



void match_naive_shared(std::string pattern, std::string subject_string_filename, long nochunk,long size, int offset,int verbose){ //nochunk == 0 => nochunk

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

    if(verbose){
        write_from_device(&dresult_buf,text_size);
    }

    cudaFree(dresult_buf);
    cudaFree(dtextptr);
    cudaFree(dpattern);
      
}


void match_kmp(std::string pattern, std::string subject_string_filename, int nochunk,long size,long offset,int verbose){ //nochunk == 0 => nochunk

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

    if(verbose){
        write_from_device(&dresult_buf,text_size);
    }
    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
    cudaFree(dpattern);
    cudaFree(dprefix_table); 
}


__constant__ char c_pattern[128*64]; //might be as fast as registers, but not in this case =)

__global__ void match_chunk_const(int pattern_size, int chunk_size ,char* text, long text_size, char* result_buf) {

    long t_id = threadId();
    long left_bound = t_id * chunk_size;
    // int right_bound = left_bound + chunk_size + pattern_size - 1 >= text_size ? text_size  
                                                                        //  : left_bound + chunk_size + pattern_size - 1;

    if(left_bound < text_size){
        for (long i = 0; i < chunk_size && left_bound + i < text_size; i++) {

            result_buf[left_bound + i] = 0;
            int matched = 1;

            for(int j = 0; j < pattern_size; j++) {
                
                if(text[left_bound + i + j] != c_pattern[j]) {
                    matched = -1;
                    break;
                }
            }

            if(matched == 1) {
                result_buf[left_bound + i] = 1;
            }
        }
                             
    }
}

__global__ void match_const(int pattern_size, char* text, long text_size, char* result_buf) {

    long t_id = threadId();

    if(t_id < text_size){
        int matched = 1;
        result_buf[t_id] = 0;
        if(t_id < text_size - pattern_size + 1){

            for(int i = 0; i < pattern_size; i++) {
                if(text[t_id + i] != c_pattern[i]) {
                    matched = -1;
                    return;
                }
            }
            if(matched == 1) {
                result_buf[t_id] = 1;
            }             
        }
                     

    }
}

__constant__ int c_prefix[128*64];

__global__ void kmp_chunk_const(int pattern_size,char* text, int text_size, char* result_buf,int chunk){
    
    long t_id = threadId();

    long left_bound = t_id * chunk;
    long right_bound = left_bound + chunk + pattern_size - 1 < text_size ? left_bound + chunk + pattern_size - 1 : text_size;

    int ams = 0;

    for(long i = left_bound; i < right_bound; i++){
        
        if (i < left_bound + chunk) {
            result_buf[i] = 0;
        }

        while(ams > 0 && c_pattern[ams] != text[i]){
            ams = c_prefix[ams-1];
        }

        if(text[i] == c_pattern[ams]){
            ams += 1;
        }
        if(ams == pattern_size) {
            result_buf[i-pattern_size + 1] = 1;
            ams = c_prefix[ams-1];
        }


    }
}

void match_naive_const(std::string pattern, std::string subject_string_filename, int nochunk,long size, long offset,int verbose){
    

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

    if(verbose){
        write_from_device(&dresult_buf,text_size);
    }
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
}

void match_kmp_const(std::string pattern, std::string subject_string_filename, int nochunk,long size, long offset,int verbose){

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

    if(verbose){
        write_from_device(&dresult_buf,text_size);
    }

    cudaFree(dresult_buf);
    cudaFree(dtextptr);
}

int main(int argc, char** argv) {

    
    long size = 0;
    long offset = 0;
    int type = 0;
    int verbose = 1;
    
    cxxopts::Options options("as", " - example command line options");

    options.add_options()("p,pattern","pattern to look for",cxxopts::value<std::string>())
                         ("f,filename","filename/devicename to look for in",cxxopts::value<std::string>())
                         ("s,size", "size of data to read",cxxopts::value<long>(size)->default_value("0"))
                         ("o,offset", "offset of data to read",cxxopts::value<long>(offset)->default_value("0"))
                         ("a,algorithm","algorithm to look for with",cxxopts::value<std::string>())
                         ("t,type","type of algorithm: 0 stands for nochunk-based and 1 for chunk-based",cxxopts::value<int>(type))
                         ("v,verbose","print result or not 0 stands for 'No' 1 for 'Yes'",cxxopts::value<int>(verbose));
    // std::string subject_string_filename("data/subject.txt");

    auto result = options.parse(argc, argv);

    if(result.count("algorithm") && result.count("type") && result.count("pattern") && result.count("filename") && result.count("verbose")){
        auto alg_name = result["algorithm"].as<std::string>();
        auto filename = result["filename"].as<std::string>();
        //patterns are separated with \x00
        auto patterns = read_pattern(result["pattern"].as<std::string>());
        std::string pattern; 
        if(patterns.size() == 1){
            pattern = patterns[0];
 //if contains \x00 --- considered empty
            if(type == 1 || type == 0){
                if(alg_name == "naive"){
                    match_naive(pattern,filename,type,size,offset,verbose);
                }else if(alg_name == "naivec"){
                    match_naive_const(pattern,filename,type,size,offset,verbose);
                }else if(alg_name == "naivesh"){
                    match_naive_shared(pattern,filename,type,size,offset,verbose);
                }else if(alg_name == "kmpc"){
                    match_kmp_const(pattern,filename,0,size,offset,verbose);
                }else if(alg_name == "kmp"){
                    match_kmp(pattern,filename,0,size,offset,verbose);
                }
            }else{
                std::cout << "type should be either 1 or 0" << "\n";
            }
        }else if(patterns.size() > 1){
            if(type == 1 || type == 0){
                if(alg_name == "mnaive"){
                    multipattern_match(patterns, filename, size, offset, verbose);
                    
                }else if(alg_name == "mnaivec"){
                    multipattern_match_const(patterns, filename, size, offset, verbose);
                }else if(alg_name == "mnaivesh"){
                    multipattern_match_shared(patterns,filename,size,offset,verbose);
                }
            }
        }else{
            std::cout << "bad patterns" << "\n";
        }
    }else{
        std::cout << "algorithm name shoud be specified with --algorithm=name and type with --type=type" << "\n";
        }    

    return 0;
}
