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

#define block_size BLOCK_SIZE

extern "C" void string_match_nope(const char*,int,short int,char*,long,char*,int,int,int);
extern "C" void string_match_multiple(const char *, const int *,short,const char*, long,char *,int);
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

        long right_bound = (i+1) * text_chunk < text_size ? (i+1) * text_chunk : text_size;
        long left_bound = i * text_chunk;

        cudaMemcpy((void*)(result_buf),((*dresult_buf)+left_bound),(right_bound-(left_bound))*sizeof(char),cudaMemcpyDeviceToHost);
        
        for (long i = 0; i < (right_bound-left_bound); i++) {
            std::cout << (int)result_buf[i];
        }

    }
    std::cout << "\n";
    delete[] (result_buf);

}


void match_pe(std::string subject_string_filename,long size, long offset,std::string program_, int verbose) {
    
        
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

    if(verbose){
       
        write_from_device(&dresult_buf,text_size);
    
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
void match_nope(std::string subject_string_filename,std::string pattern,int pattern_size, int nochunk, Function f,long size,long offset,int verbose) {
    
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

    std::string dummy_fun;

    //maybe asyncronous read from disk and jit;
    dummy_fun += "extern fn dummy(patterns : &[u8], sizes : &[i32], size : u8, text : &[u8], text_size : i64, result_buf : &mut[u8],block_size : i32) -> (){\n";

    dummy_fun += "  string_match_multiple_nope(patterns, sizes,size,text,text_size,result_buf,block_size);}"; //;
    

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
    call(dpatterns,dsizes,vpatterns.size(),dtextptr,text_size,dresult_buf,block_size);
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

void match_pe_pointer_multipattern(std::vector<std::string> vpatterns, std::string subject_string_filename, long size, long offset, int verbose) {
    
    std::string sizes;

    int len = 0;
    sizes = std::to_string(vpatterns[0].size());
    for(int i = 1; i < vpatterns.size(); i++) {
        sizes += "," + std::to_string(vpatterns[i].size());
        len +=  vpatterns[i].size();   
    }
    
    char* dtextptr;
    long text_size;

    if((dtextptr = read_file(subject_string_filename,text_size,size,offset)) == nullptr){
        std::cout << "error opening file" << "\n";
        return;
    }

    std::string dummy_fun;

    std::string patterns;
    for (auto &vp : vpatterns) patterns += vp;
    //maybe asyncronous read from disk and jit;
    dummy_fun += "extern fn dummy(text : &[u8], text_size : i64, result_buf : &mut[u8]) -> (){\n";

    dummy_fun += "  string_match_multiple(\"" + patterns + "\","
              + "["+ sizes + "]" + "," + std::to_string(vpatterns.size()) + "u8,text, text_size,result_buf,"+std::to_string(block_size)+")}"; //;

    std::string program = std::string((char*)fun_impala) + dummy_fun;

    std::cout << "compiling ... " << std::flush;
    am::timer time;
    time.start();

    auto key = anydsl_compile(program.c_str(),program.size(),0);
    time.stop();
    std::cout << "compilation time " << time.milliseconds() << std::endl;
    time.reset();
    typedef void (*function) (const char*, long, const char *);
    auto call = reinterpret_cast<function>(anydsl_lookup_function(key,"dummy"));
    
    if (call == nullptr) {
        std::cout << "compiliacion failed\n";
        return;
    } else {
        std::cout << "succesfully compiled\n";
    }

    std::cout << "\n";
    
    char* dresult_buf;
    
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(char));
    //think about data transfer;
  
    std::cout << "running ... " << "\n";
    time.start();
    
    call(dtextptr,text_size,dresult_buf);
    cudaDeviceSynchronize();

    time.stop();
    std::cout << "running time " << time.milliseconds() << " ms" << std::endl;

    if(verbose){
        write_from_device(&dresult_buf,text_size);
    }
    
    cudaFree(dresult_buf);
    cudaFree(dtextptr);
}


//TODO template method

//TODO refactor with fun that takes impala program as input

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
        auto patterns = read_pattern(result["pattern"].as<std::string>());
        std::string pattern;
        if(patterns.size() >= 1){
            pattern = patterns[0];
        
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

        if(type == 0){
            if(alg_name == "r_naive_spec"){
                match_pe(filename,size,offset,r_naive_spec,verbose);
            }else if(alg_name == "kmp"){
                match_pe(filename,size,offset,match_KMP_chunk,verbose);
            }else if(alg_name == "cleankmp"){
                // match_nope(filename,pattern,pattern_size,0,match_kmp,size,offset);
            }else if(alg_name == "cleanpe"){
                match_pe(filename,size,offset,match_naive_chunk,verbose);
            }else if(alg_name == "mcleanpe"){
                match_pe_pointer_multipattern(patterns,filename,size,offset,verbose);
            }else{
                std::cout << "no such algorithm" << "\n";
            }
        }else if(type == 1){
            if(alg_name == "r_naive_spec"){
                match_pe(filename,size,offset,match_pseudoKMP_nochunk,verbose);
            }else if(alg_name == "kmp"){
                match_pe(filename,size,offset,match_KMP_nochunk,verbose);
            }else if(alg_name == "cleankmp"){
                match_nope(filename,pattern,pattern_size,1,string_match_nope,size,offset,verbose);
            }else if(alg_name == "cleanpe"){
                match_pe(filename,size,offset,match_naive_nochunk,verbose);
            }else if(alg_name == "mcleanpe"){
                match_pe_pointer_multipattern(patterns,filename,size,offset,verbose);
            }else if(alg_name == "mcleannope"){
                multipattern_match(patterns,filename,size,offset,verbose);
            }else{
                std::cout << "no such algorithm" << "\n";
            }
        }else {
            std::cout << "type should be either 1 or 0" << "\n";
        }
        }
        }else{
            std::cout << "bad patterns" <<"\n";
        }

    return 0;
}