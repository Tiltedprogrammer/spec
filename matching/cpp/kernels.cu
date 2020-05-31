#include "kernels.hpp"
#include "utils.hpp"
//CPU timer
#include "../include/timer.h"

#include <iostream>
#include <fstream>


typedef struct Template{

    char array[32] = {0};
    int size;

}Template;

#define block_size BLOCK_SIZE

__device__ long threadId(){
    
    long blockId = (long)blockIdx.y * (long)gridDim.x + (long)blockIdx.x;
    long threadId = blockId * (long)blockDim.x + (long)threadIdx.x;
    return threadId;

}

__global__ void match(char* pattern, int pattern_size, char* text, long text_size, char* result_buf) {


    long t_id = threadId();

    if(t_id < text_size){
        int matched = 1;

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

__global__ void match_multy(const char* __restrict__ patterns, int* p_sizes, int p_number,int max_len, const char* __restrict__ text, long text_size, int* result_buf) {

    long t_id = threadId();

    if(t_id < text_size){
        
        int p_offset = 0;
        int matched = 1;
        int match_result = 0;

        if(t_id < text_size - max_len + 1){
        
            // result_buf[t_id] = 0;

            for(int i = 0; i < p_number; i++) {//for each pattern
                matched = 1;
                // if(t_id < text_size - p_sizes[i] + 1) {
                    int size = p_sizes[i];
                    for(int j = 0; j < size; j++) {
                    
                        if((int)text[t_id + j] != (int)patterns[j+p_offset]) {
                            matched = -1;
                            break;
                        }
                    } 
                
                    if(matched == 1) {
                        match_result = i+1; // 0 stands for missmatch
                    }
                // }
                p_offset += size;
            }
        }else {
                for(int i = 0; i < p_number; i++) {//for each pattern
                    matched = 1;
                    int size = p_sizes[i];
                    if(t_id < text_size - size + 1) {
                        for(int j = 0; j < size; j++) {
                        
                            if(text[t_id + j] != patterns[j+p_offset]) {
                                matched = -1;
                                break;
                            }
                        } 
                    
                        if(matched == 1) {
                            match_result = i+1; // 0 stands for missmatch
                        }
                    }
                    p_offset += size;                
            }
        }
        result_buf[t_id] = match_result;             
    }
}

//maximum 64 patterns with 8192 total length
__constant__ char mpatterns[1024]; //40 * 1024
__constant__ int cp_sizes[2248];

__global__ void match_multy_const(int p_number, int max_len, char* text, long text_size, int* result_buf) {

    long t_id = threadId();

    if(t_id < text_size){
        int p_offset = 0;
        int matched = 1;
        int match_result = 0;
        // result_buf[t_id] = 0;

        if(t_id < text_size - max_len + 1){

            for(int i = 0; i < p_number; i++) {//for each pattern
                matched = 1;
                // if(t_id < text_size - cp_sizes[i] + 1){
                    for(int j = 0; j < cp_sizes[i]; j++) {
                
                        if(text[t_id + j] != mpatterns[j + p_offset]) {
                            matched = -1;
                            break;
                        }
                    } 
                
                    if(matched == 1) {
                        match_result = i+1; // 0 stands for missmatch
                    }
                // }
                p_offset += cp_sizes[i];
            }
        }else {
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
                        match_result = i+1; // 0 stands for missmatch
                    }
                }
                p_offset += cp_sizes[i];
            }
        }
        result_buf[t_id] = match_result;             
    }
}


__global__ void match_multy_const_sizes(const char* __restrict__ patterns, int p_number,int max_len, const char* __restrict__ text, long text_size, char* result_buf) {

    long t_id = threadId();

    if(t_id < text_size){
        
        int p_offset = 0;
        int matched = 1;
        int match_result = 0;

        if(t_id < text_size - max_len + 1){
        
            // result_buf[t_id] = 0;

            for(int i = 0; i < p_number; i++) {//for each pattern
                matched = 1;
                // if(t_id < text_size - p_sizes[i] + 1) {
                    for(int j = 0; j < cp_sizes[i]; j++) {
                    
                        if(text[t_id + j] != patterns[j+p_offset]) {
                            matched = -1;
                            break;
                        }
                    } 
                
                    if(matched == 1) {
                        match_result = i+1; // 0 stands for missmatch
                    }
                // }
                p_offset += cp_sizes[i];
            }
        }else {
                for(int i = 0; i < p_number; i++) {//for each pattern
                    matched = 1;
                    if(t_id < text_size - cp_sizes[i] + 1) {
                        for(int j = 0; j < cp_sizes[i]; j++) {
                        
                            if(text[t_id + j] != patterns[j+p_offset]) {
                                matched = -1;
                                break;
                            }
                        } 
                    
                        if(matched == 1) {
                            match_result = i+1; // 0 stands for missmatch
                        }
                    }
                    p_offset += cp_sizes[i];                
            }
        }
        result_buf[t_id] = match_result;             
    }
}

void multipattern_match_const_wrapper(std::vector<std::string> vpatterns, std::string file_name,size_t size, size_t offset,int verbose,std::vector<std::pair<int,int>> &res ,int res_to_vec){

    int* sizes = new int[vpatterns.size()];

    int len = 0;
    int max = vpatterns[0].size();
    for(int i = 0; i < vpatterns.size(); i++) {
        sizes[i] = vpatterns[i].size();
        max = sizes[i] > max ? sizes[i] : max;
        len += sizes[i];     
    }
    
    int loffset = 0;

    char* dtextptr;
    size_t text_size;

    if((dtextptr = read_file(file_name,text_size,size,offset)) == nullptr){
        std::cout << "error opening file" << "\n";
        return;
    }
    
    cudaMemcpyToSymbol(cp_sizes, sizes, vpatterns.size() * sizeof(int)); 
    
    for(int i = 0; i < vpatterns.size(); i++){
        cudaMemcpyToSymbol(mpatterns,vpatterns[i].c_str(),vpatterns[i].size(),loffset);
        loffset += sizes[i];
    }
    
    int* dresult_buf;
    
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(int));
    
    //nochunk only
    dim3 block(block_size);

    int num_blocks = (text_size + block.x - 1) / block.x;
    int p = num_blocks / 32768;
    dim3 grid;
    if(p > 0) {
        grid.x = 32768;
        grid.y = p + 1;
    } else {
        grid.x = num_blocks;
    }
    RUN((match_multy_const<<<grid,block>>>(vpatterns.size(),max,dtextptr,text_size,dresult_buf)))
    cudaDeviceSynchronize();
    
    delete[](sizes);
    
    if(res_to_vec){
        int * h_match_result = new int[text_size];
        cudaMemcpy(h_match_result,dresult_buf,text_size * sizeof(int),cudaMemcpyDeviceToHost);
        for (int i = 0; i < text_size; i++){
            if (h_match_result[i]){
                res.push_back(std::pair<int,int>(i,h_match_result[i]));
            }
        }

        delete[] (h_match_result);
    }
    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
}


void multipattern_match_const_unroll_wrapper(std::vector<std::string> vpatterns, std::string file_name,size_t size, size_t offset,int verbose,std::vector<std::pair<int,int>> &res ,int res_to_vec){

    int* sizes = new int[vpatterns.size()];

    int len = 0;
    int max = vpatterns[0].size();
    for(int i = 0; i < vpatterns.size(); i++) {
        sizes[i] = vpatterns[i].size();
        max = sizes[i] > max ? sizes[i] : max;
        len += sizes[i];     
    }
    
    char* dtextptr;
    size_t text_size;

    if((dtextptr = read_file(file_name,text_size,size,offset)) == nullptr){
        std::cout << "error opening file" << "\n";
        return;
    }
    
    int* dresult_buf;
    
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(int));
    
    //nochunk only
    dim3 block(block_size);
    int num_blocks = (text_size + block.x - 1) / block.x;
    int p = num_blocks / 32768;
    dim3 grid;
    if(p > 0) {
        grid.x = 32768;
        grid.y = p + 1;
    } else {
        grid.x = num_blocks;
    }
    std::string kernel;
    
    kernel += "multiple_match_const_unroll\n";
    kernel += "__device__ long threadId(){\n"
              "long blockId = (long)blockIdx.y * (long)gridDim.x + (long)blockIdx.x;\n"
              "long threadId = blockId * (long)blockDim.x + (long)threadIdx.x;\n"
              "return threadId;\n}\n";

    kernel += "__constant__ char mpatterns[1024*40];\n";
    kernel += "__global__\n";
    kernel += "void multiple_match_const_unroll(char* text, long text_size, int* result_buf) {\n";
    kernel += "    long t_id = threadId();\n"

              "    if(t_id < text_size){\n"
            //   "       int p_offset = 0;\n"
              "       int matched = 1;\n"
              "       int match_result = 0;\n"
        // result_buf[t_id] = 0;

              "       if(t_id < text_size -" + std::to_string(max - 1) + "){\n";

    std::string cycle;
    std::string cycle_elem;
    int i = 0;
    int p_offset = 0;
    
    for(auto &vp : vpatterns){
        cycle += "matched = 1;\n";
        cycle += "      if(text[t_id + " + std::to_string(0) + "] != mpatterns[" + std::to_string(p_offset) + "]){\n" //+ std::to_string((int)vp[0]) + "){\n"
                     "      matched = -1;\n"
                     "  }\n"; 
        for(int j = 1; j < vp.size(); j++){
            cycle += "  else if(text[t_id + " + std::to_string(j) + "] != mpatterns[" + std::to_string(p_offset + j) + "]){\n" //+ std::to_string((int)vp[j]) + "){\n"
                     "      matched = -1;\n"
                     "  }\n";
        }
        cycle += "      if(matched == 1) {\n"
                 "          match_result = " + std::to_string(i + 1) + ";\n"
                 "      }\n";
        p_offset += vp.size();
        i++;                
    }
    cycle +="   }else{\n";

    i = 0;
    p_offset = 0;
    for(auto &vp : vpatterns){
        cycle += "matched = 1;\n";
        cycle += "   if(t_id < text_size - " + std::to_string(vp.size() - 1) + "){\n";
        cycle += "      if(text[t_id + " + std::to_string(0) + "] != mpatterns[" + std::to_string(p_offset) + "]){\n" //+ std::to_string((int)vp[0]) + "){\n"
                     "      matched = -1;\n"
                     "  }\n"; 
        for(int j = 1; j < vp.size(); j++){
            cycle += "  else if(text[t_id + " + std::to_string(j) + "] != mpatterns[" + std::to_string(p_offset + j) + "]){\n" //+ std::to_string((int)vp[j]) + "){\n"
                     "      matched = -1;\n"
                     "  }\n";
        }
        cycle += "      if(matched == 1) {\n"
                 "          match_result = " + std::to_string(i + 1) + ";\n"
                 "      }\n}\n";
        p_offset += vp.size();
        i++;                
    }
    cycle +="   }\n";

    kernel += cycle;
    kernel += "result_buf[t_id] = match_result;\n}\n}";

    //dump kernel

    // std::ofstream dump_file;
    
    // dump_file.open("const_kernel_dump");
    // dump_file << kernel;
    // dump_file.close();

    static jitify::JitCache kernel_cache;
    jitify::Program program = kernel_cache.program(kernel);
    using jitify::reflection::type_of;

    auto kernel_instance = program.kernel("multiple_match_const_unroll").instantiate();

    char * cvpatterns = new char[len];
    
    int loffset = 0;

    for(auto &vp : vpatterns){
       for(int j = loffset, i = 0; j < loffset + vp.size(); j++, i++){
           cvpatterns[j] = vp[i];
        }
        loffset += vp.size();
        
    }

    // for(int i = 0; i < vpatterns.size(); i++){
    cuMemcpyHtoD(kernel_instance.get_constant_ptr("mpatterns"), cvpatterns, len);
    //    loffset += sizes[i];
    // }
    CudaCheckError();

    delete[](cvpatterns);


    RUN(kernel_instance.configure(grid, block)
       .launch(dtextptr,text_size,dresult_buf))
    cudaDeviceSynchronize();
    
    delete[](sizes);
    
    if(res_to_vec){
        int * h_match_result = new int[text_size];
        cudaMemcpy(h_match_result,dresult_buf,text_size * sizeof(int),cudaMemcpyDeviceToHost);
        for (int i = 0; i < text_size; i++){
            if (h_match_result[i]){
                res.push_back(std::pair<int,int>(i,h_match_result[i]));
            }
        }

        delete[] (h_match_result);
    }

    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
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
        int match_result = 0;
        int matched = 1;

        // result_buf[t_id] = 0;

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
                    match_result = i+1; // 0 stands for missmatch
                }
            }
            p_offset += p_sizes[i];
        }
        result_buf[t_id] = match_result;             
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

            int matched = 1;
            
            if(left_bound + i + pattern_size - 1 >= text_size){
                matched = -1;
            } else {
                for(int j = 0; j < pattern_size ; j++) {

                    if(text[left_bound + i + j] != pattern[j]) {
                        matched = -1;
                        break;
                    }
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

__global__ void kmp_chunk(int* prefix_table, char* pattern,int pattern_size,char* text, long text_size, char* result_buf,int chunk){
    
    long t_id = threadId();

    long left_bound = t_id * chunk;
    long right_bound = left_bound + chunk + pattern_size - 1 < text_size ? left_bound + chunk + pattern_size - 1 : text_size;

    int ams = 0;

    for(long i = left_bound; i < right_bound; i++){

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

__constant__ char c_pattern[512]; //might be as fast as registers, but not in this case =)

__global__ void match_chunk_const(int pattern_size, int chunk_size ,char* text, long text_size, char* result_buf) {

    long t_id = threadId();
    long left_bound = t_id * chunk_size;
    // int right_bound = left_bound + chunk_size + pattern_size - 1 >= text_size ? text_size  
                                                                        //  : left_bound + chunk_size + pattern_size - 1;

    if(left_bound < text_size){
        for (long i = 0; i < chunk_size && left_bound + i < text_size; i++) {

            int matched = 1;

            if(left_bound + i + pattern_size - 1 >= text_size){
                matched = -1;
            } else {
                for(int j = 0; j < pattern_size ; j++) {

                    if(text[left_bound + i + j] != c_pattern[j]) {
                        matched = -1;
                        break;
                    }
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


__constant__ int c_prefix[128];

__global__ void kmp_chunk_const(int pattern_size,char* text, int text_size, char* result_buf,int chunk){
    
    long t_id = threadId();

    long left_bound = t_id * chunk;
    long right_bound = left_bound + chunk + pattern_size - 1 < text_size ? left_bound + chunk + pattern_size - 1 : text_size;

    int ams = 0;

    for(long i = left_bound; i < right_bound; i++){

        char curChar = text[i];

        while(ams > 0 && c_pattern[ams] != curChar){
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

void multipattern_match_wrapper(std::vector<std::string> vpatterns, std::string file_name,long size, long offset,int verbose,std::vector<std::pair<int,int>> &res ,int res_to_vec){

    int* sizes = new int[vpatterns.size()];

    int len = 0;
    int max = vpatterns[0].size();
    for(int i = 0; i < vpatterns.size(); i++) {
        sizes[i] = vpatterns[i].size();
        max = sizes[i] > max ? sizes[i] : max;
        len += sizes[i];    
    }
    
    int loffset = 0;

    char* dpatterns;
    int* dsizes;

    char* dtextptr;
    size_t text_size;

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
    
    int* dresult_buf;
    
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(int));
    
    //nochunk only
    dim3 block(block_size);

    int num_blocks = (text_size + block.x - 1) / block.x;
    int p = num_blocks / 32768;
    dim3 grid;
    if(p > 0) {
        grid.x = 32768;
        grid.y = p + 1;
    } else {
        grid.x = num_blocks;
    }
    RUN((match_multy<<<grid,block>>>(dpatterns,dsizes,vpatterns.size(),max,dtextptr,text_size,dresult_buf)))
    cudaDeviceSynchronize();

    
    delete[](sizes);

    if(res_to_vec){

        int * h_match_result = new int[text_size];
        cudaMemcpy(h_match_result,dresult_buf,text_size * sizeof(int),cudaMemcpyDeviceToHost);
        for (int i = 0; i < text_size; i++){
            if (h_match_result[i]){
                res.push_back(std::pair<int,int>(i,h_match_result[i]));
            }
        }
        delete[] (h_match_result);
    }
    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
    cudaFree(dpatterns);
    cudaFree(dsizes); 
}


void multipattern_match_const_sizes_wrapper(std::vector<std::string> vpatterns, std::string file_name,long size, long offset,int verbose,std::vector<std::pair<int,int>> &res ,int res_to_vec){

    int* sizes = new int[vpatterns.size()];

    int len = 0;
    int max = vpatterns[0].size();
    for(int i = 0; i < vpatterns.size(); i++) {
        sizes[i] = vpatterns[i].size();
        max = sizes[i] > max ? sizes[i] : max;
        len += sizes[i];    
    }
    
    int loffset = 0;

    char* dpatterns;

    char* dtextptr;
    size_t text_size;

    if((dtextptr = read_file(file_name,text_size,size,offset)) == nullptr){
        std::cout << "error opening file" << "\n";
        return;
    }
    
    cudaMemcpyToSymbol(cp_sizes, sizes, vpatterns.size() * sizeof(int)); 

    cudaMalloc((void**)&dpatterns, len * sizeof(char));
    
    for(int i = 0; i < vpatterns.size(); i++){
        cudaMemcpy((void*)(dpatterns + loffset*sizeof(char)),vpatterns[i].c_str(),vpatterns[i].size(),cudaMemcpyHostToDevice);
        loffset += sizes[i];
    }
    
    char* dresult_buf;
    
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(char));
    
    //nochunk only
    dim3 block(block_size);

    int num_blocks = (text_size + block.x - 1) / block.x;
    int p = num_blocks / 32768;
    dim3 grid;
    if(p > 0) {
        grid.x = 32768;
        grid.y = p + 1;
    } else {
        grid.x = num_blocks;
    }
    match_multy_const_sizes<<<grid,block>>>(dpatterns,vpatterns.size(),max,dtextptr,text_size,dresult_buf);
    cudaDeviceSynchronize();

    
    delete[](sizes);
        
    if(verbose){
        write_from_device(&dresult_buf,text_size);
    }

    if(res_to_vec){

        char * h_match_result = new char[text_size];
        cudaMemcpy(h_match_result,dresult_buf,text_size,cudaMemcpyDeviceToHost);
        for (int i = 0; i < text_size; i++){
            if (h_match_result[i]){
                res.push_back(std::pair<int,int>(i,(int)h_match_result[i]));
            }
        }
        delete[] (h_match_result);
    }
    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
    cudaFree(dpatterns); 
}



void multipattern_match_shared_wrapper(std::vector<std::string> vpatterns, std::string file_name,long size, long offset,int verbose,std::vector<std::pair<int,int>> &res ,int res_to_vec){

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
    size_t text_size;

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

    grid_size = (text_size + (long)block.x - 1L) / (long)block.x;
    gsqrt = (int)sqrt(grid_size) + 1;
    dim3 grid(gsqrt,gsqrt);
    match_multy_shared<<<grid,block,len * sizeof(char)>>>(dpatterns,dsizes,vpatterns.size(),len,dtextptr,text_size,dresult_buf);
    cudaDeviceSynchronize();
    
    delete[](sizes);
    
    if(res_to_vec){
        char * h_match_result = new char[text_size];
        cudaMemcpy(h_match_result,dresult_buf,text_size,cudaMemcpyDeviceToHost);
        for (int i = 0; i < text_size; i++){
            if (h_match_result[i]){
                res.push_back(std::pair<int,int>(i,(int)h_match_result[i]));
            }
        }
        delete[] (h_match_result);
    }
    
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

void match_naive_constant_wrapper(std::string pattern, std::string subject_string_filename, int nochunk, long size, long offset,std::vector<std::pair<int,int>> &res, int res_to_vec){ //nochunk == 0 => nochunk

    auto pattern_size = pattern.size();

    cudaMemcpyToSymbol(c_pattern,pattern.c_str(),pattern_size);
    
    char* dtextptr;
    size_t text_size;

    if((dtextptr = read_file(subject_string_filename,text_size,size,offset)) == nullptr){
        std::cout << "error opening file" << "\n";
        return;
    }
    
    char* dresult_buf;
    
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(char));
    cudaMemset(dresult_buf,0,text_size);
    
    int chunk = 256;

    dim3 block(block_size);
    long grid_size;
    long gsqrt;
    
    if(nochunk){
        grid_size = (text_size + (long)block.x - 1L) / (long)block.x;
        gsqrt = (int)sqrt(grid_size) + 1;
        dim3 grid(gsqrt,gsqrt);
        RUN((match_const<<<grid,block>>>(pattern_size,dtextptr,text_size,dresult_buf)))
        cudaDeviceSynchronize();
    } else{
        grid_size = (((text_size + (long)chunk - (long)1) / (long)chunk) + (long)block.x - 1L) / (long)block.x;
        gsqrt = (int)sqrt(grid_size) + 1;
        dim3 grid(gsqrt,gsqrt);
        RUN((match_chunk_const<<<grid,block>>>(pattern_size,chunk,dtextptr,text_size,dresult_buf)))
        cudaDeviceSynchronize();
    }
    
    if(res_to_vec){
        char * h_match_result = new char[text_size];
        cudaMemcpy(h_match_result,dresult_buf,text_size * sizeof(char),cudaMemcpyDeviceToHost);
        for (int i = 0; i < text_size; i++){
            if (h_match_result[i]){
                res.push_back(std::pair<int,int>(i,(int)h_match_result[i]));
            }
        }
    }

    cudaFree(dresult_buf);
    cudaFree(dtextptr);

}



void match_naive_wrapper(std::string pattern, std::string subject_string_filename, int nochunk, long size, long offset,std::vector<std::pair<int,int>> &res, int res_to_vec){ //nochunk == 0 => nochunk

    auto pattern_size = pattern.size();
    
    char* dtextptr;
    size_t text_size;

    if((dtextptr = read_file(subject_string_filename,text_size,size,offset)) == nullptr){
        std::cout << "error opening file" << "\n";
        return;
    }
    
    char *dpattern;
    cudaMalloc((void**)&dpattern, pattern_size * sizeof(char));
    cudaMemcpy((void*)dpattern,pattern.c_str(),pattern_size * sizeof(char),cudaMemcpyHostToDevice); 

    char* dresult_buf;
    
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(char));
    cudaMemset(dresult_buf,0,text_size);

    int chunk = 256;

    dim3 block(block_size);
    long grid_size;
    long gsqrt;

    if(nochunk){
        grid_size = (text_size + (long)block.x - 1L) / (long)block.x;
        gsqrt = (int)sqrt(grid_size) + 1;
        dim3 grid(gsqrt,gsqrt);
        RUN((match<<<grid,block>>>(dpattern,pattern_size,dtextptr,text_size,dresult_buf)))
        cudaDeviceSynchronize();
    } else{
        grid_size = (((text_size + (long)chunk - (long)1) / (long)chunk) + (long)block.x - 1L) / (long)block.x;
        gsqrt = (int)sqrt(grid_size) + 1;
        dim3 grid(gsqrt,gsqrt);
        RUN((match_chunk<<<grid,block>>>(dpattern,pattern_size,chunk,dtextptr,text_size,dresult_buf)))
        cudaDeviceSynchronize();
        CudaCheckError();
    }
    
    if(res_to_vec){
        char * h_match_result = new char[text_size];
        cudaMemcpy(h_match_result,dresult_buf,text_size * sizeof(char),cudaMemcpyDeviceToHost);
        for (int i = 0; i < text_size; i++){
            if (h_match_result[i]){
                res.push_back(std::pair<int,int>(i,(int)h_match_result[i]));
            }
        }
    }

    cudaFree(dresult_buf);
    cudaFree(dtextptr);
    cudaFree(dpattern);

}

// Texture memory kernel
texture<int,1,cudaReadModeElementType> patterns_tex; 

__global__ void match_tex(int* p_sizes, int p_number, char* text, long text_size, char* result_buf){
    
    long t_id = threadId();

    if(t_id < text_size){
        int p_offset = 0;
        int matched = 1;
        int match_result = 0;
        
        // result_buf[t_id] = 0;

        for(int i = 0; i < p_number; i++) {//for each pattern
            matched = 1;
            if(t_id < text_size - p_sizes[i] + 1) {
                for(int j = 0; j < p_sizes[i]; j++) {
                
                    if(text[t_id + j] != tex1Dfetch(patterns_tex,j+p_offset)) {
                        matched = -1;
                        break;
                    }
                } 
            
                if(matched == 1) {
                    match_result = i+1; // 0 stands for missmatch
                }
            }
            p_offset += p_sizes[i];
        }
        result_buf[t_id] = match_result;             
    }
}

void multipattern_match_texture_wrapper(std::vector<std::string> vpatterns, std::string file_name, long size, long offset,int verbose){ //nochunk == 0 => nochunk

    int* sizes = new int[vpatterns.size()];

    int len = 0;
    for(int i = 0; i < vpatterns.size(); i++) {
        sizes[i] = vpatterns[i].size();
        len += sizes[i];    
    }
    
    int loffset = 0;

    int* dpatterns;
    int* dsizes;

    char* dtextptr;
    size_t text_size;

    if((dtextptr = read_file(file_name,text_size,size,offset)) == nullptr){
        std::cout << "error opening file" << "\n";
        return;
    }
    
    cudaMalloc((void**)&dsizes, (vpatterns.size())*sizeof(int));
    cudaMemcpy((void*)dsizes, sizes, (vpatterns.size())*sizeof(int), cudaMemcpyHostToDevice); 
    
    cudaMalloc((void**)&dpatterns, len * sizeof(int));
    
    for(int i = 0; i < vpatterns.size(); i++){
        std::vector<int> pattern_int;
        // int* pattern_int = new int[vpatterns[i].size()];
        // int j = 0;
        for(auto ch: vpatterns[i]){
            // pattern_int[j]=(int)ch;
            pattern_int.push_back((int)ch);
            // j++;
        }
        cudaMemcpy((void*)(dpatterns + loffset),&pattern_int[0],vpatterns[i].size()*sizeof(int),cudaMemcpyHostToDevice);
        loffset += sizes[i];
    }


    //tex mem
    textureReference *texRefTable ;
    cudaGetTextureReference( (const struct textureReference**)&texRefTable, &patterns_tex);
    cudaChannelFormatDesc channelDesc = cudaCreateChannelDesc<int>();
        // set texture parameters
    patterns_tex.addressMode[0] = cudaAddressModeClamp;
    patterns_tex.addressMode[1] = cudaAddressModeClamp;
    patterns_tex.filterMode     = cudaFilterModePoint;
    patterns_tex.normalized     = 0;
        
    size_t offset_t ;
    cudaBindTexture( &offset_t, (const struct textureReference*) texRefTable,
            (const void*) dpatterns, (const struct cudaChannelFormatDesc*) &channelDesc, 
            len * sizeof(int));
    
    char* dresult_buf;
    
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(char));
    
    //nochunk only
    dim3 block(block_size);
    long grid_size;
    long gsqrt;

    grid_size = (text_size + (long)block.x - 1L) / (long)block.x;
    gsqrt = (int)sqrt(grid_size) + 1;
    dim3 grid(gsqrt,gsqrt);
    match_tex<<<grid,block>>>(dsizes,vpatterns.size(),dtextptr,text_size,dresult_buf);
    cudaDeviceSynchronize();
    
    delete[](sizes);
    
    
    if(verbose){
        write_from_device(&dresult_buf,text_size);
    }

    // if(res_to_vec){

    //     std::cout << "res to vec" << std::endl;

    //     char * h_match_result = new char[text_size];
    //     cudaMemcpy(h_match_result,dresult_buf,text_size,cudaMemcpyDeviceToHost);
    //     for (int i = 0; i < text_size; i++){
    //         if (h_match_result[i]){
    //             res.push_back(std::pair<int,int>(i,(int)h_match_result[i]));
    //         }
    //     }
    // }
    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
    cudaFree(dpatterns);
    cudaFree(dsizes);

    //unbind
    cudaUnbindTexture(patterns_tex);
}



// void match_naive_shared(std::string pattern, std::string subject_string_filename, long nochunk,long size, int offset,int verbose){ //nochunk == 0 => nochunk

//     char* dtextptr;
//     long text_size;
//     if((dtextptr = read_file(subject_string_filename,text_size,size,offset)) == nullptr){
//         std::cout << "error opening file" << "\n";
//         return;
//     }

//     auto pattern_size = pattern.size();
//     char *dpattern;
//     cudaMalloc((void**)&dpattern, pattern_size * sizeof(char));
//     cudaMemcpy((void*)dpattern,pattern.c_str(),pattern_size * sizeof(char),cudaMemcpyHostToDevice); 

//     char* dresult_buf;
//     cudaMalloc((void**)&dresult_buf, text_size * sizeof(char));
    
//     int chunk = 256;

//     dim3 block(block_size);
//     long grid_size;
//     long gsqrt;
//     am::timer time;
//     std::cout << "running ..." << "\n";
//     time.start();
    
//     if(nochunk){
//         grid_size = (text_size + (long)block.x - 1L) / (long)block.x;
//         gsqrt = (int)sqrt(grid_size) + 1;
//         dim3 grid(gsqrt,gsqrt);
//         match_shared<<<grid,block>>>(dpattern,pattern_size,dtextptr,text_size,dresult_buf);
//         cudaDeviceSynchronize();
//         time.stop();
//     } else{
//         grid_size = (((text_size + (long)chunk - (long)1) / (long)chunk) + (long)block.x - 1L) / (long)block.x;
//         gsqrt = (int)sqrt(grid_size) + 1;
//         dim3 grid(gsqrt,gsqrt);
//         match_chunk_shared<<<grid,block>>>(dpattern,pattern_size,chunk,dtextptr,text_size,dresult_buf);
//         cudaDeviceSynchronize();
//         time.stop();
//     }

//     std::cout << "running time " << time.milliseconds() << " ms" << std::endl;    

//     if(verbose){
//         write_from_device(&dresult_buf,text_size);
//     }

//     cudaFree(dresult_buf);
//     cudaFree(dtextptr);
//     cudaFree(dpattern);
      
// }


void match_kmp(std::string pattern, std::string subject_string_filename, int constant, long size, long offset, int verbose, std::vector<std::pair<int,int>> &res, int res_to_vec){ //nochunk == 0 => nochunk

    auto pattern_size = pattern.size();
    
    char* dtextptr;
    size_t text_size;
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

    char* dresult_buf;
    //think about data transfer;
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(char));
    cudaMemset(dresult_buf,0,text_size);
    
    int chunk = 256;

    dim3 block(block_size);
    long grid_size;
    long gsqrt;

    if(constant){
        grid_size = (((text_size + (long)chunk - (long)1) / (long)chunk) + (long)block.x - 1L) / (long)block.x;
        gsqrt = (int)sqrt(grid_size) + 1;
        dim3 grid(gsqrt,gsqrt);
        cudaMemcpyToSymbol(c_pattern,pattern.c_str(),pattern.size());
        cudaMemcpyToSymbol(c_prefix,prefix_table,pattern.size() * sizeof(int));

        RUN((kmp_chunk_const<<<grid,block>>>(pattern_size,dtextptr,text_size,dresult_buf,chunk)))
        cudaDeviceSynchronize();
    } else{
        grid_size = (((text_size + (long)chunk - (long)1) / (long)chunk) + (long)block.x - 1L) / (long)block.x;
        gsqrt = (int)sqrt(grid_size) + 1;
        dim3 grid(gsqrt,gsqrt);
        RUN((kmp_chunk<<<grid,block>>>(dprefix_table,dpattern,pattern_size,dtextptr,text_size,dresult_buf,chunk)))
        cudaDeviceSynchronize();
    }

    if(res_to_vec){
        char * h_match_result = new char[text_size];
        cudaMemcpy(h_match_result,dresult_buf,text_size * sizeof(char),cudaMemcpyDeviceToHost);
        for (int i = 0; i < text_size; i++){
            if (h_match_result[i]){
                res.push_back(std::pair<int,int>(i,(int)h_match_result[i]));
            }
        }
    }

    if(verbose){
        write_from_device(&dresult_buf,text_size);
    }

    delete[](prefix_table);
    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
    cudaFree(dpattern);
    cudaFree(dprefix_table); 
}
