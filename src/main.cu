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


void match_pe_(std::string pattern, std::string subject_string_filename) {
    
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

void match_pe(std::string subject_string_filename,std::string program_) {
    
        
    std::string program = std::string((char*)fun_impala) + program_;

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
    

    int text_size;
    char* dtextptr = read_file(subject_string_filename,text_size);
    
    int* dresult_buf;
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(int));
    
    std::cout << "running ... " << "\n";
    time.start();
    
    call(dtextptr,text_size,dresult_buf);

    time.stop();
    std::cout << "running time " << time.milliseconds() << " ms" << std::endl;

    write_from_device(&dresult_buf,text_size);
    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
}

void prefix_f(std::string pattern, int index){

     std::string dummy_fun;

    //maybe asyncronous read from disk and jit;
    dummy_fun += "extern fn dummy()-> i32{\n";

    dummy_fun += "  prefix_function(\"" + pattern + "\","
              + std::to_string(index) + ")}"; //;

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

    dummy_fun += "  string_match_pseudoKMP_pointer(\"" + pattern + "\","
              + std::to_string(pattern_size) + ",32i8 ,text, text_size,result_buf,256,256)}"; //;

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
    FILE *f; 
    if((f = fopen(subject_string_filename.c_str(), "rb")) == NULL){
	std::cout << "can not oppen file" << subject_string_filename << "\n";
	    return;
    }
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

void match_pe_pointer_multipattern(int p_number,char** argv_patterns, std::string subject_string_filename) {
    
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
        
    std::string dummy_fun;

    //maybe asyncronous read from disk and jit;
    dummy_fun += "extern fn dummy(text : &[u8], text_size : i32, result_buf : &mut[i32]) -> (){\n";

//TODO max_pattern_size
    dummy_fun += "  string_match_pseudoKMP_pointer_multiple( \"" + std::string(patterns) + "\", "
              + "["+ std::to_string(sizes[1]) + "]" + "," + std::to_string(p_number)+",3, text, text_size,result_buf,256,256)}"; //;

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


//TODO template method

//TODO refactor with fun that takes impala program as input

int main(int argc, char** argv) {
    
    // if (argc != 2 ) {
        // std::cout << "pattern string required\n";
        // return 0;
    // }
    std::string pattern = std::string(argv[1]);

    if (pattern.size() > 31) {
        std::cout << "pattern should be less then or eq 31 bytes\n";
        return 0;
    }
    
    auto pattern_size = pattern.size();
    pattern.resize(31,'0'); 
    
    std::string subject = std::string("data/subject.txt");

    std::string match_pseudoKMP;

    match_pseudoKMP += "extern fn dummy(text : &[u8], text_size : i32, result_buf : &mut[i32]) -> (){\n";

    match_pseudoKMP += "  string_match_pseudoKMP(Template { array : \"" + pattern + "\", size : "
              + std::to_string(pattern_size) + "},32i8 ,text, text_size,result_buf,256,256)}"; //;

    std::string match_pseudoKMP_nochunk;

    match_pseudoKMP_nochunk += "extern fn dummy(text : &[u8], text_size : i32, result_buf : &mut[i32]) -> (){\n";

    match_pseudoKMP_nochunk += "  string_match_pseudoKMP_nochunk(Template { array : \"" + pattern + "\", size : "
              + std::to_string(pattern_size) + "},32i8 ,text, text_size,result_buf,256,256)}"; //;

    std::string match_pseudoKMP_nochunk_nope;

    match_pseudoKMP_nochunk_nope += "extern fn dummy(text : &[u8], text_size : i32, result_buf : &mut[i32]) -> (){\n";

    match_pseudoKMP_nochunk_nope += "  string_match_pseudoKMP_nochunk_nope(Template { array : \"" + pattern + "\", size : "
              + std::to_string(pattern_size) + "},32i8 ,text, text_size,result_buf,256,256)}"; //;

    std::string match_pseudoKMP_chunk_nope;

    match_pseudoKMP_chunk_nope += "extern fn dummy(text : &[u8], text_size : i32, result_buf : &mut[i32]) -> (){\n";

    match_pseudoKMP_chunk_nope += "  string_match_pseudoKMP_nope(Template { array : \"" + pattern + "\", size : "
              + std::to_string(pattern_size) + "},32i8 ,text, text_size,result_buf,256,256)}"; //;
    
    std::string match_KMP_chunk;
    match_KMP_chunk += "extern fn dummy(text : &[u8], text_size : i32, result_buf : &mut[i32]) -> (){\n";

    match_KMP_chunk += "  match_kmp(\"" + pattern + "\","
              + std::to_string(pattern_size) + ",32i8 ,text, text_size,result_buf,256,256,0)}"; //;

    std::string match_KMP_nochunk;
    match_KMP_nochunk += "extern fn dummy(text : &[u8], text_size : i32, result_buf : &mut[i32]) -> (){\n";

    match_KMP_nochunk += "  match_kmp(\"" + pattern + "\","
              + std::to_string(pattern_size) + ",32i8 ,text, text_size,result_buf,256,256,1)}"; //;

    std::string match_naive_nochunk;
    match_naive_nochunk += "extern fn dummy(text : &[u8], text_size : i32, result_buf : &mut[i32]) -> (){\n";

    match_naive_nochunk += "  string_match(Template {array :\"" + pattern + "\", size :"
              + std::to_string(pattern_size) + "},"+ std::to_string(pattern_size) + ", 32i8 ,text, text_size,result_buf,256,256,1)}"; //;

    std::string match_naive_chunk;
    match_naive_chunk += "extern fn dummy(text : &[u8], text_size : i32, result_buf : &mut[i32]) -> (){\n";

    match_naive_chunk += "  string_match(Template {array :\"" + pattern + "\", size :"
              + std::to_string(pattern_size) + "},"+ std::to_string(pattern_size) + ", 32i8 ,text, text_size,result_buf,256,256,0)}"; //;
    
    // match_pe_pointer(pattern,subject);
    // match_pe_pointer_multipattern(argc-1,argv,subject);
    // match_pe(subject,match_pseudoKMP);
    auto arg = std::string(argv[2]) + std::string(argv[3]);
    if(arg == "dirty0"){
        match_pe(subject,match_pseudoKMP);
    }else if(arg == "dirty1") {
        match_pe(subject,match_pseudoKMP_nochunk);
    }else if(arg == "kmp0") {
        match_pe(subject,match_KMP_chunk);
    }else if(arg == "kmp1") {
        match_pe(subject,match_KMP_nochunk);
    }else if(arg == "dirtynaive0") {
        match_pe(subject,match_pseudoKMP_chunk_nope);
    }else if(arg == "dirtynaive1") {
        match_pe(subject,match_pseudoKMP_nochunk_nope);
    }else if(arg == "clean0") {
        match_pe(subject,match_naive_chunk);
    }else if(arg == "clean1") {
        match_pe(subject,match_naive_nochunk);
    }else {

    }
    // prefix(pattern,subject);
    // match_pe_nochunk(pattern,subject);
    // std::cout << GetFileSize(std::string("subject.txt"));

    return 0;
}