#include <iostream> 
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
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

#include "spec_match.hpp"


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

    // turn off texture mem
    PFAC_setTextureMode(handle, PFAC_TEXTURE_OFF ); 
    
    // step 2: read patterns and dump transition table 
    PFAC_status = PFAC_readPatternFromFile( handle, (char*)patternFile.c_str()) ;
    if ( PFAC_STATUS_SUCCESS != PFAC_status ){
        printf("Error: fails to read pattern from file, %s\n", PFAC_getErrorString(PFAC_status) );
        exit(1) ;	
    }
    
    // std::cout << "# of patterns " << handle->numOfPatterns << "\n";
   
    //step 3: prepare input stream
    FILE* fpin = fopen( inputFile.c_str(), "rb");
    assert ( NULL != fpin ) ;
    
    // // obtain file size
    // fseek (fpin , 0 , SEEK_END);
    // input_size = ftell (fpin);
    // rewind (fpin);
    
    // // allocate memory to contain the whole file
    h_inputString = (char *) malloc (sizeof(char)*input_size);
    assert( NULL != h_inputString );
 
    h_matched_result = (int *) malloc (sizeof(int)*input_size);
    assert( NULL != h_matched_result );
    memset( h_matched_result, 0, sizeof(int)*input_size ) ;
     
    // // copy the file into the buffer
    input_size = fread (h_inputString, 1, input_size, fpin);
    fclose(fpin);

    PFAC_status = PFAC_matchFromHost( handle, h_inputString, input_size, h_matched_result ) ;
    if ( PFAC_STATUS_SUCCESS != PFAC_status ){
        printf("Error: fails to PFAC_matchFromHost, %s\n", PFAC_getErrorString(PFAC_status) );
        exit(1) ;	
    }

    int match_cout = 0;
    for (int i = 0; i < input_size; i++) {
        if(h_matched_result[i] != 0) match_cout++;
    }
    std::cout << "Match count: " << match_cout << std::endl;

    // free(h_matched_result);
    // h_matched_result = NULL;
     
   

    PFAC_status = PFAC_destroy( handle ) ;
    assert( PFAC_STATUS_SUCCESS == PFAC_status );
    
    free(h_inputString);
    free(h_matched_result); 
            
    return 0;
}

