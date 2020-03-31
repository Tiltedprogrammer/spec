/*
 *  Copyright 2011 Chen-Hsiung Liu, Lung-Sheng Chien, Cheng-Hung Lin,and Shih-Chieh Chang
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

/*
 * The example shows following operations:
 *
 * 1) Including the header file PFAC.h which resides in directory $(PFAC_LIB_ROOT)/include.
 *    This header file is necessary because it contains declaration of APIs.
 *
 * 2) Initializing the PFAC library by creating a PFAC handle 
 *    (PFAC binds to a GPU context implicitly. If an user wants to bind a specific GPU, 
 *    he must call cudaSetDevice() explicitly before calling PFAC_create() ).
 *
 * 3) Reading patterns from a file and PFAC would create transition table both on the CPU side and the GPU side.
 *
 * 4) Dumping transition table to "table.txt", the content of table is shown in Figure 1 of user guide.
 *
 * 5) Reading an input stream from a file.
 *
 * 6) Performing matching process by calling the PFAC_matchFromHost() function.
 *
 * 7) Showing matched results.
 *
 * 8) Destroying the PFAC handle.
 *
 *
 */
 
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

    spec_match_from_host(handle,h_inputString,input_size,h_matched_result,6);

        
    PFAC_status = PFAC_destroy( handle ) ;
    assert( PFAC_STATUS_SUCCESS == PFAC_status );
    
    free(h_inputString);
    free(h_matched_result); 
            
    return 0;
}


