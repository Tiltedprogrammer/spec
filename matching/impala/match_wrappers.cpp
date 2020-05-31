#include <vector>
#include <string>
#include <iostream>

//CUDA
#include "cuda_runtime.h"

#define RUNTIME_ENABLE_JIT
#include <anydsl_runtime.h>

// Generated from fun.impala
// #include "fun.inc"
#include "fun.inc"
//cpu timer
#include "timer.h"

#include "match_wrappers.hpp"
#include "utils.hpp"


void match_pe(std::string pattern, std::string subject_string_filename, long size, long offset, int verbose,std::vector<std::pair<int,int>> &res, int res_to_vec) {
    
    std::string pattern_embedded;
    for(auto ch: pattern){
        pattern_embedded += std::to_string((int)ch);
        pattern_embedded += "u8,";
    }
    pattern_embedded.pop_back();

    std::string r_naive_spec;

    r_naive_spec += "extern fn dummy(text : &[u8], text_size : i64, result_buf : &mut[u8]) -> (){\n";

    r_naive_spec += "  string_match_pseudoKMP([" + pattern_embedded + "],"
              + std::to_string(pattern.size()) + ",32i8 ,text, text_size,result_buf," + std::to_string(BLOCK_SIZE) + ",256)}"; //;

    std::string program = std::string((char*)fun_impala) + r_naive_spec;

    std::cout << "compiling ... " << std::endl;
    am::timer time;
    time.start();
    auto key = anydsl_compile(program.c_str(),program.size(),0);
    time.stop();
    typedef void (*function) (const char*, long, char *);
    auto call = reinterpret_cast<function>(anydsl_lookup_function(key,"dummy"));
    
    if (call == nullptr) {
        std::cout << "compilation failed\n";
        return;
    }

    std::cout << "Compile time: " << time.milliseconds() << std::endl;

    size_t text_size;
    char* dtextptr;
    if((dtextptr = read_file(subject_string_filename,text_size,size,offset))==nullptr){
        std::cout << "error reading file" << "\n";
        return;
    }


    char* dresult_buf;
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(char));
    cudaMemset(dresult_buf,0,text_size);
    
    call(dtextptr,text_size,dresult_buf);
    cudaDeviceSynchronize();


    if(res_to_vec){
        char * h_match_result = new char[text_size];
        cudaMemcpy(h_match_result,dresult_buf,text_size * sizeof(char),cudaMemcpyDeviceToHost);
        for (int i = 0; i < text_size; i++){
            if (h_match_result[i]){
                // printf("At position %4d, match pattern %d\n", i, (int)h_match_result[i]);
                res.push_back(std::pair<int,int>(i,(int)h_match_result[i]));
            }
        }
    }
    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
}


void match_pe_kmp(std::string pattern, std::string subject_string_filename, long size, long offset, int verbose,std::vector<std::pair<int,int>> &res, int res_to_vec) {
    
    std::string pattern_embedded;
    for(auto ch: pattern){
        pattern_embedded += std::to_string((int)ch);
        pattern_embedded += "u8,";
    }
    pattern_embedded.pop_back();

    std::string r_naive_spec;

    r_naive_spec += "\nextern fn dummy(text : &[u8], text_size : i64, result_buf : &mut[i32]) -> (){\n";

    r_naive_spec += "  match_kmp([" + pattern_embedded + "],"
              + std::to_string(pattern.size()) + ",text, text_size,result_buf," + std::to_string(BLOCK_SIZE) + ",256)}"; //;

    std::string program = std::string((char*)fun_impala) + r_naive_spec;
    auto key = anydsl_compile(program.c_str(),program.size(),0);
    typedef void (*function) (const char*, long, int *);
    auto call = reinterpret_cast<function>(anydsl_lookup_function(key,"dummy"));
    
    if (call == nullptr) {
        std::cout << "compiliacion failed\n";
        return;
    } else {
        std::cout << "succesfully compiled\n";
    }

    size_t text_size;
    char* dtextptr;
    if((dtextptr = read_file(subject_string_filename,text_size,size,offset))==nullptr){
        std::cout << "error reading file" << "\n";
        return;
    }

    int* dresult_buf;
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(int));
    cudaMemset(dresult_buf,0,text_size * sizeof(int));
    
    
    call(dtextptr,text_size,dresult_buf);
    cudaDeviceSynchronize();

    if(res_to_vec){
        int * h_match_result = new int[text_size];
        cudaMemcpy(h_match_result,dresult_buf,text_size * sizeof(int),cudaMemcpyDeviceToHost);
        for (int i = 0; i < text_size; i++){
            if (h_match_result[i]){
                // printf("At position %4d, match pattern %d\n", i, (int)h_match_result[i]);
                res.push_back(std::pair<int,int>(i,h_match_result[i]));
            }
        }
    }

    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
}


void match_naive_single(std::string pattern, std::string subject_string_filename, int nochunk, long size, long offset, int verbose, std::vector<std::pair<int,int>> &res, int res_to_vec) {
    
    std::string pattern_embedded;
    for(auto ch: pattern){
        pattern_embedded += std::to_string((int)ch);
        pattern_embedded += "u8,";
    }
    pattern_embedded.pop_back();

    std::string r_naive_spec;

    r_naive_spec += "\nextern fn dummy(text : &[u8], text_size : i64, result_buf : &mut[u8]) -> (){\n";

    r_naive_spec += "  string_match([" + pattern_embedded + "],"
              + std::to_string(pattern.size()) + ",text, text_size,result_buf," + std::to_string(BLOCK_SIZE) + ",256," + std::to_string(nochunk) + ")}"; //;

    std::string program = std::string((char*)fun_impala) + r_naive_spec;
    auto key = anydsl_compile(program.c_str(),program.size(),0);
    typedef void (*function) (const char*, long, unsigned char *);
    auto call = reinterpret_cast<function>(anydsl_lookup_function(key,"dummy"));
    
    if (call == nullptr) {
        std::cout << "compiliacion failed\n";
        return;
    } else {
        std::cout << "succesfully compiled\n";
    }

    size_t text_size;
    char* dtextptr;
    if((dtextptr = read_file(subject_string_filename,text_size,size,offset)) == nullptr){
        std::cout << "error reading file" << "\n";
        return;
    }

    unsigned char* dresult_buf;
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(char));
    cudaMemset(dresult_buf,0,text_size);
    
    std::cout << "running ... " << "\n";
    
    call(dtextptr,text_size,dresult_buf);
    cudaDeviceSynchronize();

    if(res_to_vec){
        char * h_match_result = new char[text_size];
        cudaMemcpy(h_match_result,dresult_buf,text_size * sizeof(char),cudaMemcpyDeviceToHost);
        for (int i = 0; i < text_size; i++){
            if ((int)h_match_result[i]){
                // printf("At position %4d, match pattern %d\n", i, (int)h_match_result[i]);
                res.push_back(std::pair<int,int>(i,(int)h_match_result[i]));
            }
        }
    }

    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
}

void match_pe_pat(std::string subject_string_filename,std::string program_,std::string pattern, int pattern_size,long size,long offset) {
    
        
    std::string program = std::string((char*)fun_impala) + program_;

    std::cout << "compiling ... " << std::flush;
    am::timer time;
    // time.start();

    auto key = anydsl_compile(program.c_str(),program.size(),0);
    typedef void (*function) (const char*,int,const char*, long, char *);
    auto call = reinterpret_cast<function>(anydsl_lookup_function(key,"dummy"));
    
    if (call == nullptr) {
        std::cout << "compiliacion failed\n";
        return;
    } else {
        std::cout << "succesfully compiled\n";
    }
    
    size_t text_size;
    char* dtextptr;
    if((dtextptr = read_file(subject_string_filename,text_size,size,offset)) == nullptr){
        return;
    }
    
    char* dresult_buf;
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(char));
    
    std::cout << "running ... " << "\n";

    char* d_pat;
    cudaMalloc((void**)&d_pat,pattern_size * sizeof(char));
    cudaMemcpy(d_pat,pattern.c_str(),pattern_size*sizeof(char),cudaMemcpyHostToDevice);
    
    time.start();

    call(d_pat,pattern_size,dtextptr,text_size,dresult_buf);
    cudaDeviceSynchronize();

    time.stop();
    std::cout << "running time " << time.milliseconds() << " ms" << std::endl;

    write_from_device(&dresult_buf,text_size);
    
    cudaFree(d_pat);
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
}

void match_nope(std::string pattern, std::string subject_string_filename, int pattern_size, int nochunk, fun f,long size,long offset,int verbose) {
    
    am::timer time;

    size_t text_size;

    char* dtextptr;
    if((dtextptr = read_file(subject_string_filename,text_size,size,offset)) == nullptr){
        std::cout << "error opening file" << "\n";
        return;
    }

    char* dresult_buf;
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(char));
    
    std::cout << "running ... " << "\n";
    

    char* d_pat;
    cudaMalloc((void**)&d_pat,pattern_size);
    cudaMemcpy(d_pat,pattern.c_str(),pattern_size,cudaMemcpyHostToDevice);
    
    time.start();

    if(nochunk){
        f(d_pat,pattern_size,32,dtextptr,text_size,dresult_buf,512,256,1);
    }else {
        f(d_pat,pattern_size,32,dtextptr,text_size,dresult_buf,512,256,0);
    }
    cudaDeviceSynchronize();
    time.stop();

    std::cout << "running time " << time.milliseconds() << " ms" << std::endl;

    if(verbose){
        write_from_device(&dresult_buf,text_size);
    }

    cudaFree(d_pat);
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
}

void prefix_f(std::string pattern, int index){

     std::string dummy_fun;

    //maybe asyncronous read from disk and jit;
    dummy_fun += "extern fn dummy()-> i32{\n";

    dummy_fun += "  prefix_function(\"" + pattern + "\","
              + std::to_string(index) + ",0,0)}"; //;

    std::string program = std::string((char*)fun_impala) + dummy_fun;

    std::cout << "compiling ... " << std::flush;
    am::timer time;
    // time.start();

    auto key = anydsl_compile(program.c_str(),program.size(),0);
    typedef int (*function) ();
    auto call = reinterpret_cast<function>(anydsl_lookup_function(key,"dummy"));
    
    if (call == nullptr) {
        std::cout << "compiliacion failed\n";
        return;
    } else {
        std::cout << "succesfully compiled\n";
    }
    std::cout << call() << "\n";

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

    std::string dummy_fun;

    //maybe asyncronous read from disk and jit;
    dummy_fun += "extern fn dummy(patterns : &[u8], sizes : &[i32], size : u8, text : &[u8], text_size : i64, result_buf : &mut[u8],BLOCK_SIZE : i32) -> (){\n";

    dummy_fun += "  string_match_multiple_nope(patterns, sizes,size,text,text_size,result_buf,BLOCK_SIZE);}"; //;
    

    std::string program = std::string((char*)fun_impala) + dummy_fun;

    std::cout << "compiling ... " << std::flush;
    am::timer time;
    time.start();

    auto key = anydsl_compile(program.c_str(),program.size(),0);
    time.stop();
    std::cout << "compilation time " << time.milliseconds() << std::endl;
    time.reset();
    typedef void (*function) (const char*,const int*,short,const char*, long, const char *,int);
    auto call = reinterpret_cast<function>(anydsl_lookup_function(key,"dummy"));
    
    if (call == nullptr) {
        std::cout << "compiliacion failed\n";
        return;
    } else {
        std::cout << "succesfully compiled\n";
    }

    std::cout << "\n";


    std::cout << "running ..." << "\n";
    time.start();
    call(dpatterns,dsizes,vpatterns.size(),dtextptr,text_size,dresult_buf,BLOCK_SIZE);
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

void match_pe_pointer_multipattern(std::vector<std::string> vpatterns, std::string subject_string_filename, long size, long offset, int verbose, std::vector<std::pair<int,int>> &res, int res_to_vec) {
    
    std::string sizes;

    int len = 0;
    int max_len = vpatterns[0].size();
    sizes = std::to_string(vpatterns[0].size());
    for(int i = 1; i < vpatterns.size(); i++) {
        sizes += "," + std::to_string(vpatterns[i].size());
        len +=  vpatterns[i].size();
        if (max_len < vpatterns[i].size()){
            max_len = vpatterns[i].size();
        }   
    }
    
    char* dtextptr;
    size_t text_size;

    if((dtextptr = read_file(subject_string_filename,text_size,size,offset)) == nullptr){
        std::cout << "error opening file" << "\n";
        return;
    }

    std::string dummy_fun;

    std::string patterns;
    for (auto &vp : vpatterns){
            for(auto ch : vp){
                patterns += std::to_string((int)ch);
                patterns += "u8,";
            }
    }
    patterns.pop_back(); //remove last ',';

    int num_blocks = (text_size + BLOCK_SIZE - 1) / BLOCK_SIZE;
    
    dim3 dimGrid;
    int p = num_blocks >> 15 ;
    dimGrid.x = num_blocks ;
    if ( p ){
        dimGrid.x = 1<<15 ;
        dimGrid.y = p+1 ;
    }
    //maybe asyncronous read from disk and jit;
    dummy_fun += "extern fn dummy(text : &[u8], text_size : i64, result_buf : &mut[i32], gx : i32, gy : i32) -> (){\n";

    dummy_fun += "  string_match_multiple([" + patterns + "],"
              + "["+ sizes + "]" + "," + std::to_string(vpatterns.size()) + "," + std::to_string(max_len) + ",text, text_size,result_buf,"+std::to_string(BLOCK_SIZE) + ",gx,gy)}"; //;

    std::string program = std::string((char*)fun_impala) + dummy_fun;

    std::cout << "compiling ... " << std::flush;
    am::timer time;
    time.start();

    auto key = anydsl_compile(program.c_str(),program.size(),0);
    time.stop();
    std::cout << "compilation time " << time.milliseconds() << std::endl;
    time.reset();
    typedef void (*function) (const char*, long, const int *,int,int);
    auto call = reinterpret_cast<function>(anydsl_lookup_function(key,"dummy"));
    
    if (call == nullptr) {
        std::cout << "compiliacion failed\n";
        return;
    }

    
    int* dresult_buf;
    
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(int));
    //think about data transfer;
    
    call(dtextptr,text_size,dresult_buf,dimGrid.x,dimGrid.y);
    cudaDeviceSynchronize();

    if(res_to_vec){
        int * h_match_result = new int[text_size];
        cudaMemcpy(h_match_result,dresult_buf,text_size * sizeof(int),cudaMemcpyDeviceToHost);
        for (int i = 0; i < text_size; i++){
            if (h_match_result[i]){
                // printf("At position %4d, match pattern %d\n", i, (int)h_match_result[i]);
                res.push_back(std::pair<int,int>(i,(int)h_match_result[i]));
            }
        }
    }
    
    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
}