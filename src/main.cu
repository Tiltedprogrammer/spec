#include <cstdio>
#include <string>
#include <iostream>
#include <sys/mman.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fstream>
#include <stdlib.h>



#define RUNTIME_ENABLE_JIT
#include <anydsl_runtime.h>

// Generated from fun.impala
#include "fun.inc"
#include "timer.h"

void match_naive_cuda(std::string pattern, std::string text) {
    
    if (pattern.size() > 31) { //actual maximum is 32 for now
        std::cout << "pattern should be less then or eq 31 bytes\n";
        return;
    }

    auto pattern_size = pattern.size();
    pattern.resize(31,'0'); 
        
    std::string dummy_fun;

    //maybe asyncronous read from disk and jit;
    dummy_fun += "extern fn dummy(text : &[u8], text_size : i32, result_buf : &mut[i32]) -> (){\n";

    dummy_fun += "  string_match(Template { array : \"" + pattern + "\", size : "
              + std::to_string(pattern_size) + "},32i8 ,text, text_size,result_buf,256,256)}"; //;

    std::string program = std::string((char*)fun_impala) + dummy_fun;

    
    auto key = anydsl_compile(program.c_str(),program.size(),0);
    typedef void (*function) (const char*, int, const int *);
    auto call = reinterpret_cast<function>(anydsl_lookup_function(key,"dummy"));
    
    if (call == nullptr) {
        std::cout << "compiliacion failed\n";
        return;
    }
    
    auto text_size = text.length();
    int* result_buf = new int[text_size];
    int* dresult_buf;
    char* dtext;
    //think about data transfer;
    cudaMalloc((void**)&dtext, text_size * sizeof(char));
    cudaMemcpy((void*)dtext,text.c_str(),text_size * sizeof(char),cudaMemcpyHostToDevice);
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(int));
    
    call(dtext,text_size,dresult_buf);
    
    cudaMemcpy((void*)result_buf,dresult_buf,text_size*sizeof(int),cudaMemcpyDeviceToHost);

    for (int i = 0; i < text_size; i++) {
        std::cout << result_buf[i];
    }
    std::cout << "\n";
    
    cudaFree(dresult_buf);
    cudaFree(dtext);
    delete[] (result_buf);

}

long GetFileSize(std::string filename)
{
    struct stat stat_buf;
    int rc = stat(filename.c_str(), &stat_buf);
    return rc == 0 ? stat_buf.st_size : -1;
}


void match_pe(std::string pattern, std::string subject_string_filename) {
    
    if (pattern.size() > 31) {
        std::cout << "pattern should be less then or eq 31 bytes\n";
        return;
    }
    auto pattern_size = pattern.size();
    pattern.resize(31,'0'); 
        
    std::string dummy_fun;

    //maybe asyncronous read from disk and jit;
    dummy_fun += "extern fn dummy(text : &[u8], text_size : i32, result_buf : &mut[i32]) -> (){\n";

    dummy_fun += "  string_match_pseudoKMP(Template { array : \"" + pattern + "\", size : "
              + std::to_string(pattern_size) + "},32i8 ,text, text_size,result_buf,256,256)}"; //;

    std::string program = std::string((char*)fun_impala) + dummy_fun;

    std::cout << "compiling ... " << std::flush;
    am::timer time;
    // time.start();

    auto key = anydsl_compile(program.c_str(),program.size(),0);
    typedef void (*function) (const char*, int, const int *);
    auto call = reinterpret_cast<function>(anydsl_lookup_function(key,"dummy"));
    
    if (call == nullptr) {
        std::cout << "compiliacion failed\n";
        return;
    } else {
        std::cout << "succesfully compiled\n";
    }

    // time.stop();
    // std::cout << "compilation time " << time.milliseconds() << " ms" << std::endl;
    

    auto text_size = GetFileSize(subject_string_filename) - 1;//TODO
    
    //read file
    FILE *f = fopen(subject_string_filename.c_str(), "rb");
    // fseek(f, 0, SEEK_END);
    // long fsize = ftell(f);
    // fseek(f, 0, SEEK_SET);  /* same as rewind(f); */

    char *subject_string = new char[text_size];
    fread(subject_string, 1, text_size, f);
    fclose(f);

    // string[fsize] = 0;
    // int fdin,fdout;
    // if (fdin = open(subject_string_filename.c_str(),O_RDONLY) < 0) {
        // std::cout << "can't open file" << subject_string_filename << "\n";
        // return;
    // }
    // char *subject_string = new char[text_size];
    // read(fdin,(void*)subject_string,text_size);
    
    std::cout << "\n";
    int* result_buf = new int[text_size];
    int* dresult_buf;
    char* dtext;
    //think about data transfer;
    cudaMalloc((void**)&dtext, text_size * sizeof(char));
    cudaMemcpy((void*)dtext,subject_string,text_size * sizeof(char),cudaMemcpyHostToDevice);
    delete[](subject_string);
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(int));
    
    // for(int i = 0; i < text_size; i++) {
        // result_buf[i] = -1;
    // }
    // cudaMemset((void*)dresult_buf, -1, text_size*sizeof(int));
    
    // call(text.c_str(),text_size,result_buf);
    // time.reset();
    std::cout << "running ... " << "\n";
    time.start();
    
    call(dtext,text_size,dresult_buf);

    time.stop();
    std::cout << "running time " << time.milliseconds() << " ms" << std::endl;

    cudaMemcpy((void*)result_buf,dresult_buf,text_size*sizeof(int),cudaMemcpyDeviceToHost);

    for (int i = 0; i < text_size; i++) {
        std::cout << result_buf[i];
    }
    std::cout << "\n";
    
    cudaFree(dresult_buf);
    cudaFree(dtext);
    delete[] (result_buf);
}


void match_pe_pointer(std::string pattern, std::string subject_string_filename) {
    
    if (pattern.size() > 31) {
        std::cout << "pattern should be less then or eq 31 bytes\n";
        return;
    }
    auto pattern_size = pattern.size();
    // pattern.resize(31,'0'); 
        
    std::string dummy_fun;

    //maybe asyncronous read from disk and jit;
    dummy_fun += "extern fn dummy(text : &[u8], text_size : i32, result_buf : &mut[i32]) -> (){\n";

    dummy_fun += "  string_match_pseudoKMP_pointer( \"" + pattern + "\", "
              + std::to_string(pattern_size) + ",text, text_size,result_buf,256,256)}"; //;

    std::string program = std::string((char*)fun_impala) + dummy_fun;

    std::cout << "compiling ... " << std::flush;
    am::timer time;
    // time.start();

    auto key = anydsl_compile(program.c_str(),program.size(),0);
    typedef void (*function) (const char*, int, const int *);
    auto call = reinterpret_cast<function>(anydsl_lookup_function(key,"dummy"));
    
    if (call == nullptr) {
        std::cout << "compiliacion failed\n";
        return;
    } else {
        std::cout << "succesfully compiled\n";
    }

    // time.stop();
    // std::cout << "compilation time " << time.milliseconds() << " ms" << std::endl;
    

    auto text_size = GetFileSize(subject_string_filename) - 1;//TODO
    
    //read file
    FILE *f = fopen(subject_string_filename.c_str(), "rb");
    // fseek(f, 0, SEEK_END);
    // long fsize = ftell(f);
    // fseek(f, 0, SEEK_SET);  /* same as rewind(f); */

    char *subject_string = new char[text_size];
    fread(subject_string, 1, text_size, f);
    fclose(f);

    // string[fsize] = 0;
    // int fdin,fdout;
    // if (fdin = open(subject_string_filename.c_str(),O_RDONLY) < 0) {
        // std::cout << "can't open file" << subject_string_filename << "\n";
        // return;
    // }
    // char *subject_string = new char[text_size];
    // read(fdin,(void*)subject_string,text_size);
    
    std::cout << "\n";
    int* result_buf = new int[text_size];
    int* dresult_buf;
    char* dtext;
    //think about data transfer;
    cudaMalloc((void**)&dtext, text_size * sizeof(char));
    cudaMemcpy((void*)dtext,subject_string,text_size * sizeof(char),cudaMemcpyHostToDevice);
    delete[](subject_string);
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(int));
    
    // for(int i = 0; i < text_size; i++) {
        // result_buf[i] = -1;
    // }
    // cudaMemset((void*)dresult_buf, -1, text_size*sizeof(int));
    
    // call(text.c_str(),text_size,result_buf);
    // time.reset();
    std::cout << "running ... " << "\n";
    time.start();
    
    call(dtext,text_size,dresult_buf);

    time.stop();
    std::cout << "running time " << time.milliseconds() << " ms" << std::endl;

    cudaMemcpy((void*)result_buf,dresult_buf,text_size*sizeof(int),cudaMemcpyDeviceToHost);

    for (int i = 0; i < text_size; i++) {
        std::cout << result_buf[i];
    }
    std::cout << "\n";
    
    cudaFree(dresult_buf);
    cudaFree(dtext);
    delete[] (result_buf);
}



int main(int argc, char** argv) {
    
    // if (argc != 2 ) {
        // std::cout << "pattern string required\n";
        // return 0;
    // }
    std::string pattern = std::string(argv[1]);
    std::string subject = std::string("data/subject.txt");
    
    // match_naive_cuda(pattern,text);
    match_pe_pointer(pattern,subject);
    // std::cout << GetFileSize(std::string("subject.txt"));

    return 0;
}