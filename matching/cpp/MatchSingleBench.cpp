 #include <iostream> 
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// To enable assertions do cmake .. -DCMAKE_BUILD_TYPE=Debug
#include <assert.h>

// split
#include <sstream>
#include <vector>
 
#include <PFAC.h>

#include "PFAC_P.h"

//argparsing
#include "../include/cxxopts.hpp"


// specialized naive
#include "match_wrappers.hpp"
#include "kernels.hpp"

// #include "spec_match.hpp"




std::vector<std::string> split (const std::string &s, char delim) {
    std::vector<std::string> result;
    std::stringstream ss (s);
    std::string item;

    while (getline (ss, item, delim)) {
        result.push_back (item);
    }

    return result;
}

int main(int argc, char **argv)
{
    
    cxxopts::Options options("as", " - example command line options");
    options.add_options()("d,datafile","path to image to a file with subject string",cxxopts::value<std::string>())
                         ("p,patternfile","path to patterns",cxxopts::value<std::string>())
                         ("s,size","size of input data",cxxopts::value<int>())
                         ("b,benchmark","benchmark to run",cxxopts::value<std::string>());

    auto result = options.parse(argc, argv);	  
    // char inputFile[] = "../data_copy/example_input" ;
    if (!(result.count("datafile") && result.count("patternfile") && result.count("size") && result.count("benchmark"))){
        std::cout << "datafile and patterns file are requied as well as size and benchmark" << std::endl;
        return 1;
    }

    auto inputFile = (result["datafile"].as<std::string>());
    auto patternFile = result["patternfile"].as<std::string>();
    auto benchName = result["benchmark"].as<std::string>();
    
    PFAC_handle_t handle ;
    PFAC_status_t PFAC_status ;
    int input_size = result["size"].as<int>();    

    // step 1: create PFAC handle 
    PFAC_status = PFAC_create( &handle ) ;
    assert( PFAC_STATUS_SUCCESS == PFAC_status );

    // turn off texture mem
    PFAC_setTextureMode(handle, PFAC_TEXTURE_OFF ); 
    
    // step 2: read patterns and dump transition table 
    PFAC_status = PFAC_readPatternFromFile( handle, (char*)patternFile.c_str()) ;
    if ( PFAC_STATUS_SUCCESS != PFAC_status ){
        printf("Error: fails to read pattern from file, %s\n", PFAC_getErrorString(PFAC_status) );
        exit(1) ;	
    }
    

    // free(h_matched_result);
    // free(h_inputString);
    // h_matched_result = NULL;
     
    assert(handle->numOfPatterns == 1);
    
    std::string pattern = std::string(handle->rowPtr[0],handle->patternLen_table[1]);

    std::vector<std::pair<int,int>> resCuda;

    if(benchName == "kspec") {
        match_pe(pattern,inputFile,input_size,0,0,resCuda,1);
    } else if(benchName == "nspecc"){
        match_naive_single(pattern,inputFile,0,input_size,0,0,resCuda,1);
    } else if(benchName == "nspec"){
        match_naive_single(pattern,inputFile,1,input_size,0,0,resCuda,1);
    } else if(benchName == "nglobalc"){
        match_naive_wrapper(pattern,inputFile,0,input_size,0,resCuda,1);
    } else if(benchName == "nglobal"){
        match_naive_wrapper(pattern,inputFile,1,input_size,0,resCuda,1);
    } else if(benchName == "nconstc"){
        match_naive_constant_wrapper(pattern,inputFile,0,input_size,0,resCuda,1);
    } else if(benchName == "nconst"){
        match_naive_constant_wrapper(pattern,inputFile,1,input_size,0,resCuda,1);
    } else if(benchName == "kglobal"){
        match_kmp(pattern,inputFile,0,input_size,0,0,resCuda,1);
    } else if(benchName == "kconst"){
        match_kmp(pattern,inputFile,1,input_size,0,0,resCuda,1);
    } else {
        std::cout << "No benchmark found" << std::endl;
        return 0;
    }


    std::cout << "Match count: " << resCuda.size() << std::endl;
     

    PFAC_status = PFAC_destroy( handle ) ;
    assert( PFAC_STATUS_SUCCESS == PFAC_status );
                
    return 0;
}


