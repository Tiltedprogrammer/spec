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


//arg parsing
#include "../include/cxxopts.hpp"

#include "cuda_runtime.h"

#include "kernels.hpp"
#include "utils.hpp"

#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }

inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true)
{
   if (code != cudaSuccess) 
   {
      fprintf(stderr,"GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
      if (abort) exit(code);
   }
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
                match_naive_wrapper(pattern,filename,type,size,offset,verbose);
            }else{
                std::cout << "type should be either 1 or 0" << "\n";
            }
        }else if(patterns.size() > 1){

            std::vector<std::pair<int,int>> v;
            
            if(type == 1 || type == 0){
                if(alg_name == "mnaive"){
                    multipattern_match_wrapper(patterns, filename, size, offset, verbose,v,0);
                }else if(alg_name == "mnaivec"){
                    multipattern_match_const_wrapper(patterns, filename, size, offset, verbose,v,0);
                }else if(alg_name == "mnaivesh"){
                    multipattern_match_shared_wrapper(patterns,filename,size,offset,verbose,v,0);
                }else if(alg_name == "mnaivetex"){
                    multipattern_match_texture_wrapper(patterns,filename,size,offset,verbose);
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
