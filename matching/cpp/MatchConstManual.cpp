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



int main(int argc, char **argv)
{
    
    cxxopts::Options options("as", " - example command line options");
    options.add_options()("d,datafile","path to image to a file with subject string",cxxopts::value<std::string>())
                         ("p,patternfile","path to patterns",cxxopts::value<std::string>())
                         ("s,size","size of input data",cxxopts::value<int>());

    auto result = options.parse(argc, argv);	  
    // char inputFile[] = "../data_copy/example_input" ;
    if (!(result.count("datafile") && result.count("patternfile") && result.count("size"))){
        std::cout << "datafile and patterns file are requied as well as size" << std::endl;
        return 1;
    }

    auto inputFile = (result["datafile"].as<std::string>());
    // char patternFile[] = "../pattern/example_pattern" ;
    auto patternFile = result["patternfile"].as<std::string>();
    PFAC_handle_t handle ;
    PFAC_status_t PFAC_status ;
    int input_size = result["size"].as<int>();    
    char *h_inputString = NULL ;
    int  *h_matched_result = NULL ;

    // step 1: create PFAC handle 
    PFAC_status = PFAC_create( &handle ) ;
    assert( PFAC_STATUS_SUCCESS == PFAC_status );

    // step 2: read patterns and dump transition table 
    PFAC_status = PFAC_readPatternFromFile( handle, (char*)patternFile.c_str()) ;
    if ( PFAC_STATUS_SUCCESS != PFAC_status ){
        printf("Error: fails to read pattern from file, %s\n", PFAC_getErrorString(PFAC_status) );
        exit(1) ;	
    }
    
    

    std::vector<std::string> vpatterns;

    for (int i = 0; i < handle->numOfPatterns; i++) {
        vpatterns.push_back(std::string(handle->rowPtr[i],handle->patternLen_table[i+1]));
    }


    std::vector<std::pair<int,int>> resImpala;

    // multipattern_match_wrapper(vpatterns,inputFile,input_size,0,0,resImpala,1);
    // multipattern_match_const_wrapper(vpatterns,inputFile,input_size,0,0,resImpala,1);
    // multipattern_match_const_sizes_wrapper(vpatterns,inputFile,input_size,0,0,resImpala,1);
    // match_pe_pointer_multipattern(vpatterns,inputFile,input_size,0,0,resImpala,1);
    multipattern_match_const_unroll_wrapper(vpatterns,inputFile,input_size,0,0,resImpala,1);

    std::cout << "Match count: " << resImpala.size() << std::endl;
    
    PFAC_status = PFAC_destroy( handle ) ;
    assert( PFAC_STATUS_SUCCESS == PFAC_status );
            
    return 0;
}
