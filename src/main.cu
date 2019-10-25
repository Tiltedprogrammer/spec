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
#include "cxxopts.hpp"

#define block_size 1024

extern "C" void string_match_nope(const char*,int,short int,char*,long,char*,int,int,int);
// extern "C" void match_kmp(const char*,int,short int,char*,long,char*,int,int,int);


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

void write_from_device(char** dresult_buf,long text_size){

    int text_chunk = 128 * 1024 * 1024;
    
    if(text_size < text_chunk) {
        text_chunk = text_size;
    }

    char* result_buf = new char[text_chunk];


    for(long i = 0; i < (text_size + text_chunk - 1) / text_chunk; i++){ //number of chunks

        long right_bound = (i+1) * text_chunk < text_size ? (i+1) * text_chunk : text_size;
        long left_bound = i * text_chunk;

        cudaMemcpy((void*)(result_buf),((*dresult_buf)+left_bound),(right_bound-(left_bound))*sizeof(char),cudaMemcpyDeviceToHost);
        
        for (long i = 0; i < (right_bound-left_bound); i++) {
            std::cout << result_buf[i];
        }

    }
    std::cout << "\n";
    delete[] (result_buf);

}


void match_pe(std::string subject_string_filename,long size, long offset,std::string program_) {
    
        
    std::string program = std::string((char*)fun_impala) + program_;

    std::cout << "compiling ... " << std::flush;
    am::timer time;
    // time.start();

    auto key = anydsl_compile(program.c_str(),program.size(),0);
    typedef void (*function) (const char*, long, char *);
    auto call = reinterpret_cast<function>(anydsl_lookup_function(key,"dummy"));
    
    if (call == nullptr) {
        std::cout << "compiliacion failed\n";
        return;
    } else {
        std::cout << "succesfully compiled\n";
    }

    long text_size;
    char* dtextptr;
    if((dtextptr = read_file(subject_string_filename,text_size,size,offset))==nullptr){
        std::cout << "error reading file" << "\n";
        return;
    }

    char* dresult_buf;
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(char));
    
    std::cout << "running ... " << "\n";
    time.start();
    
    call(dtextptr,text_size,dresult_buf);
    cudaDeviceSynchronize();

    time.stop();
    std::cout << "running time " << time.milliseconds() << " ms" << std::endl;

    write_from_device(&dresult_buf,text_size);
    
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
    
    long text_size;
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

template<typename Function>
void match_nope(std::string subject_string_filename,std::string pattern,int pattern_size, int nochunk, Function f,long size,long offset) {
    
    am::timer time;

    long text_size;

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

    write_from_device(&dresult_buf,text_size);
    
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

void match_pe_pointer_multipattern(int p_number,std::vector<std::string> vpatterns, std::string subject_string_filename) {
    
    int* sizes = new int[p_number];
    int len = 0;
    for(int i = 1; i < p_number+1; i++) {
        auto str = std::string(vpatterns[i]);
        sizes[i-1] = str.length();
        len += str.length();    
    }

    char* patterns = new char[len];
    
    int offset = 0;

    for(int i = 0; i < p_number; i++){

        for(int j = 0; j < sizes[i]; j++){
            patterns[offset+j] = vpatterns[i+1][j];
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
    
   
    long size = 0;
    long offset = 0;
    int type = 0;
    
    cxxopts::Options options("as", " - example command line options");

    options.add_options()("p,pattern","pattern to look for",cxxopts::value<std::string>())
                         ("f,filename","filename/devicename to look for in",cxxopts::value<std::string>())
                         ("s,size", "size of data to read",cxxopts::value<long>(size)->default_value("0"))
                         ("o,offset", "offset of data to read",cxxopts::value<long>(offset)->default_value("0"))
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
        }else{
            std::cout << "bad pattern/failed to read file" << "\n";
            return 0;
        }

        auto pattern_size = pattern.size();
    // pattern.resize(31,'0'); 

        std::string r_naive_spec;

        r_naive_spec += "extern fn dummy(text : &[u8], text_size : i64, result_buf : &mut[u8]) -> (){\n";

        r_naive_spec += "  string_match_pseudoKMP(\"" + pattern + "\","
              + std::to_string(pattern_size) + ",32i8 ,text, text_size,result_buf," + std::to_string(block_size) + ",256)}"; //;

        std::string match_pseudoKMP_nochunk;

        match_pseudoKMP_nochunk += "extern fn dummy(text : &[u8], text_size : i64, result_buf : &mut[u8]) -> (){\n";

        match_pseudoKMP_nochunk += "  string_match_pseudoKMP_nochunk(\"" + pattern + "\","
              + std::to_string(pattern_size) + ",32i8 ,text, text_size,result_buf," + std::to_string(block_size) + ",256)}"; //;

        std::string match_pseudoKMP_nochunk_nope;

        match_pseudoKMP_nochunk_nope += "extern fn dummy(text : &[u8], text_size : i64, result_buf : &mut[u8]) -> (){\n";

        match_pseudoKMP_nochunk_nope += "  string_match_pseudoKMP_nochunk_nope(\"" + pattern + "\", "
              + std::to_string(pattern_size) + ",32i8 ,text, text_size,result_buf," + std::to_string(block_size) + ",256)}"; //;

        std::string match_pseudoKMP_chunk_nope;

        match_pseudoKMP_chunk_nope += "extern fn dummy(text : &[u8], text_size : i64, result_buf : &mut[u8]) -> (){\n";

        match_pseudoKMP_chunk_nope += "  string_match_pseudoKMP_nope(\"" + pattern + "\","
              + std::to_string(pattern_size) + ",32i8 ,text, text_size,result_buf," + std::to_string(block_size) + ",256)}"; //;
    
        std::string match_KMP_chunk;
        match_KMP_chunk += "extern fn dummy(text : &[u8], text_size : i64, result_buf : &mut[u8]) -> (){\n";

        match_KMP_chunk += "  match_kmp(\"" + pattern + "\","
              + std::to_string(pattern_size) + ",32i8 ,text, text_size,result_buf," + std::to_string(block_size) + ",256,0)}"; //;

        std::string match_KMP_nochunk;
        match_KMP_nochunk += "extern fn dummy(text : &[u8], text_size : i64, result_buf : &mut[u8]) -> (){\n";

        match_KMP_nochunk += "  match_kmp(\"" + pattern + "\","
              + std::to_string(pattern_size) + ",32i8 ,text, text_size,result_buf," + std::to_string(block_size) + ",256,1)}"; //;

        std::string match_naive_nochunk;
        match_naive_nochunk += "extern fn dummy(text : &[u8], text_size : i64, result_buf : &mut[u8]) -> (){\n";

        match_naive_nochunk += "  string_match(\"" + pattern + "\","
              + std::to_string(pattern_size) + ", 32i8 ,text, text_size,result_buf," + std::to_string(block_size) + ",256,1)}"; //;

        std::string match_naive_chunk;
        match_naive_chunk += "extern fn dummy(text : &[u8], text_size : i64, result_buf : &mut[u8]) -> (){\n";

        match_naive_chunk += "  string_match(\"" + pattern + "\","
              + std::to_string(pattern_size) + ", 32i8 ,text, text_size,result_buf," + std::to_string(block_size) + ",256,0)}"; //;
    


        std::string match_naive_nochunk_nope;
        match_naive_nochunk_nope += "extern fn dummy(pattern : &[u8],p_size : i32,text : &[u8], text_size : i64, result_buf : &mut[u8]) -> (){\n";

        match_naive_nochunk_nope += "  $string_match_nope($pattern,p_size, 32i8 ,text, text_size,result_buf," + std::to_string(block_size) + ",256,1)}"; //;

        std::string match_naive_chunk_nope;
        match_naive_chunk_nope += "extern fn dummy(pattern : &[u8],p_size : i32,text : &[u8], text_size : i64, result_buf : &mut[u8]) -> (){\n";

        match_naive_chunk_nope += "  $string_match_nope($pattern, p_size, 32i8 ,text, text_size,result_buf," + std::to_string(block_size) + ",256,0)}"; //;



        std::string match_pseudoKMP_chunk_nope_annotated;

        match_pseudoKMP_chunk_nope_annotated += "extern fn dummy(pattern : &[u8],p_size : i32,text : &[u8], text_size : i64, result_buf : &mut[u8]) -> (){\n";

        match_pseudoKMP_chunk_nope_annotated += "  string_match_pseudoKMP_nope(pattern,p_size,32i8 ,text, text_size,result_buf," + std::to_string(block_size) + ",256)}"; //;


        std::string match_pseudoKMP_nochunk_nope_annotated;

        match_pseudoKMP_nochunk_nope_annotated += "extern fn dummy(pattern : &[u8],p_size : i32,text : &[u8], text_size : i64, result_buf : &mut[u8]) -> (){\n";

        match_pseudoKMP_nochunk_nope_annotated += "  string_match_pseudoKMP_nochunk_nope(pattern,p_size,32i8 ,text, text_size,result_buf," + std::to_string(block_size) + ",256)}"; //;         

        if (pattern.size() > 128) {
            std::cout << "pattern should be less then or eq 128 bytes\n";
            return 0;
        }
        if(type == 0){
            if(alg_name == "r_naive_spec"){
                match_pe(filename,size,offset,r_naive_spec);
            }else if(alg_name == "kmp"){
                match_pe(filename,size,offset,match_KMP_chunk);
            }else if(alg_name == "cleankmp"){
                // match_nope(filename,pattern,pattern_size,0,match_kmp,size,offset);
            }else if(alg_name == "cleanpe"){
                match_pe(filename,size,offset,match_naive_chunk);
            }
        }else if(type == 1){
            if(alg_name == "r_naive_spec"){
                match_pe(filename,size,offset,match_pseudoKMP_nochunk);
            }else if(alg_name == "kmp"){
                match_pe(filename,size,offset,match_KMP_nochunk);
            }else if(alg_name == "cleankmp"){
                match_nope(filename,pattern,pattern_size,1,string_match_nope,size,offset);
            }else if(alg_name == "cleanpe"){
                match_pe(filename,size,offset,match_naive_nochunk);
            }
        }else {
            std::cout << pattern << " " << pattern.size() << "\n";
            std::cout << "type should be either 1 or 0" << "\n";
        }
    }

    return 0;
}