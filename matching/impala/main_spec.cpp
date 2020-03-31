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


//arg parsing
#include "cxxopts.hpp"

// CUDA
#include "cuda_runtime.h"

#include "utils.hpp"

#include "match_wrappers.hpp"

extern "C" void string_match_nope(const char*,int,short int,char*,long,char*,int,int,int);
extern "C" void string_match_multiple(const char *, const int *,short,const char*, long,char *,int);
// extern "C" void match_kmp(const char*,int,short int,char*,long,char*,int,int,int);



//TODO template method

//TODO refactor with fun that takes impala program as input

int main(int argc, char** argv) {
    
   
    long size = 0;
    long offset = 0;
    int type = 0;
    int verbose = 1;
    // int block_size = BLOCK_SIZE;
    
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

        std::vector<std::pair<int,int>> v;

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
                match_pe_pointer_multipattern(patterns,filename,size,offset,verbose,v,0);
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
                match_pe_pointer_multipattern(patterns,filename,size,offset,verbose,v,0);
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