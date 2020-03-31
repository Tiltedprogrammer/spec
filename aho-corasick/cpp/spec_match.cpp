
#include <cuda_runtime.h>
#include "spec-kernels/ImpalaKernels.hpp"

#include "spec_match.hpp"


#include <iostream>

 

#define RUNTIME_ENABLE_JIT
#include <anydsl_runtime.h>

// Generated from spec_match.impala
#include "spec_match.inc"


#define CudaCheckError()    __cudaCheckError( __FILE__, __LINE__ )

inline void __cudaCheckError( const char *file, const int line )
{
    cudaError err = cudaGetLastError();
    if ( cudaSuccess != err )
    {
        fprintf( stderr, "cudaCheckError() failed at %s:%i : %s\n",
                 file, line, cudaGetErrorString( err ) );
        exit( -1 );
    }

    // More careful checking. However, this will affect performance.
    // Comment away if needed.
    err = cudaDeviceSynchronize();
    if( cudaSuccess != err )
    {
        fprintf( stderr, "cudaCheckError() with sync failed at %s:%i : %s\n",
                 file, line, cudaGetErrorString( err ) );
        exit( -1 );
    }
    return;
}
// #include "/home/bolkonskiy322_gmail_com/specialization/spec/build/aho-corasick/cpp/spec_match.inc"

int spec_match_from_host(PFAC_handle_t handle, char* h_input_string, size_t input_size, int* h_matched_result, int algorithm){
    
    // platform is GPU    
    char *d_input_string  = NULL;
    int *d_matched_result = NULL;

    // n_hat = number of integers of input string
    int n_hat = (input_size + sizeof(int)-1)/sizeof(int) ;

    // allocate memory for input string and result
    // basic unit of d_input_string is integer
    cudaError_t cuda_status1 = cudaMalloc((void **) &d_input_string,        n_hat*sizeof(int) );
    cudaError_t cuda_status2 = cudaMalloc((void **) &d_matched_result, input_size*sizeof(int) );
    if ( (cudaSuccess != cuda_status1) || (cudaSuccess != cuda_status2) ){
    	  if ( NULL != d_input_string   ) { cudaFree(d_input_string); }
    	  if ( NULL != d_matched_result ) { cudaFree(d_matched_result); }
        return 1;
    }

    // copy input string from host to device
    cuda_status1 = cudaMemcpy(d_input_string, h_input_string, input_size, cudaMemcpyHostToDevice);
    if ( cudaSuccess != cuda_status1 ){
        cudaFree(d_input_string); 
        cudaFree(d_matched_result);
        return 1 ;
    }

    //pass impala program below + construct table string
    if(algorithm == 1){ //impala naive opt
        spec_match_from_device<1>( handle, d_input_string, input_size,
            d_matched_result ) ;
    } else if (algorithm == 2){ //impala spec compressed
        spec_match_from_device<2>( handle, d_input_string, input_size,
            d_matched_result ) ;
    } else if (algorithm == 3){
        spec_match_from_device<3>( handle, d_input_string, input_size,
            d_matched_result ) ;
    } else if (algorithm == 4) { //impala Corasick stand alone
        spec_match_from_device<4>(handle, d_input_string, input_size,d_matched_result);
    } else if (algorithm == 5) {// impala naive
        spec_match_from_device<5>(handle, d_input_string, input_size,d_matched_result);
    } else if (algorithm == 6) { //naive opt
        spec_match_from_device<6>(handle, d_input_string, input_size,d_matched_result);
    } else if (algorithm == 7) {
        spec_match_from_device<7>(handle, d_input_string, input_size,d_matched_result);
    } else if (algorithm == 8) {
        spec_match_from_device<8>(handle, d_input_string, input_size,d_matched_result);
    }
    // if ( PFAC_STATUS_SUCCESS != PFAC_status ){
    //     cudaFree(d_input_string);
    //     cudaFree(d_matched_result);
    //     return PFAC_status ;
    // }

    // copy the result data from device to host

    cuda_status1 = cudaMemcpy(h_matched_result, d_matched_result, input_size*sizeof(int), cudaMemcpyDeviceToHost);
    if ( cudaSuccess != cuda_status1 ){
        cudaFree(d_input_string);
        cudaFree(d_matched_result);
        return 1;
    }


    cudaFree(d_input_string);
    cudaFree(d_matched_result);

    return 0 ;

}


template <int ALGO>
void spec_match_from_device( PFAC_handle_t handle, char *d_input_string, size_t input_size,
    int *d_matched_result ) {

        // n_hat = number of integers of input string
    // LONG??
    int n_hat = (input_size + sizeof(int)-1)/sizeof(int) ;

    // num_blocks = # of thread blocks to cover input stream
    int num_blocks = (n_hat + THREAD_BLOCK_SIZE-1)/THREAD_BLOCK_SIZE ;

    // dim3  dimBlock( THREAD_BLOCK_SIZE, 1 ) ;
    dim3  dimGrid ;

    /* 
     *  hardware limitatin of 2-D grid is (65535, 65535), 
     *  1-D grid is not enough to cover large input stream.
     *  For example, input_size = 1G (input stream has 1Gbyte), then 
     *  num_blocks = # of thread blocks = 1G / 1024 = 1M > 65535
     *
     *  However when using 2-D grid, then number of invoke blocks = dimGrid.x * dimGrid.y 
     *  which is bigger than > num_blocks
     *
     *  we need to check this boundary condition inside kernel because
     *  size of d_nnz_per_block is num_blocks
     *
     *  trick: decompose num_blocks = p * 2^15 + q
     */
     
    int p = num_blocks >> 15 ;
    dimGrid.x = num_blocks ;
    if ( p ){
        dimGrid.x = 1<<15 ;
        dimGrid.y = p+1 ;
    }

    int char_set = 256;

    if(ALGO == 1){

        std::vector<std::string> vpatterns;

        for (int i = 0; i < handle->numOfPatterns; i++) {
            vpatterns.push_back(std::string(handle->rowPtr[i],handle->patternLen_table[i+1]));
        }

        std::string sizes;

        int len = 0;
        sizes = std::to_string(vpatterns[0].size());
        for(int i = 1; i < vpatterns.size(); i++) {
            sizes += "," + std::to_string(vpatterns[i].size());
            len +=  vpatterns[i].size();   
        }
    
        std::string patterns;
        for (auto &vp : vpatterns) patterns += vp;
        //maybe asyncronous read from disk and jit;

        std::string dummy;
        dummy += "extern fn dummy(d_input_string : &[i32], d_match_result : &mut[i32], size : i32, blocks_minus1 : i32, n_hat :i32) -> (){\n";
        dummy += "  spec_match_naive(\"" + patterns +"\"," +
                            "[" + sizes + "]," + 
                            std::to_string(vpatterns.size()) + "i32," +
                            std::to_string(THREAD_BLOCK_SIZE) + ", " +
                            std::to_string(dimGrid.x) + ", " +
                            std::to_string(dimGrid.y) + ", " +
                            std::to_string(EXTRA_SIZE_PER_TB) + ", " +
                            "d_input_string, size, n_hat," +
                            // std::to_string(input_size) + ", " +
                            // std::to_string(n_hat) + ", " +
                            // std::to_string(num_blocks-1) + ", " +
                            "blocks_minus1,d_match_result)\n}\n";


    std::string program = std::string((char*)___impala_spec_match_impala) + dummy;
    
    std::cout << "Compiling ..." << "\n";
    
    auto key = anydsl_compile(program.c_str(),program.size(),0);
    
    typedef void (*function) (const int*,const int *, int, int,int);
    
    auto call = reinterpret_cast<function>(anydsl_lookup_function(key,"dummy"));
    
    if (call == nullptr) {
        std::cout << "compilation failed\n";
        return;
    } else {
        std::cout << "succesfully compiled\n";
    }

    call((int*)d_input_string,d_matched_result,input_size,num_blocks-1,n_hat);

    }
    else if(ALGO == 2){

    std::string PFAC_table_str;

    std::string chars;
    std::string states;
    std::string offsets;
    std::string sizes;
    int offset = 0;


    //num of states is 1 greater than actuall number of states, state number starts from 1;
    //thus offset[0] = 0; where 0 is state with number 1, offset[1] = size..; 
    for (int state = 1; state < handle->numOfStates; state++){
        
        int size = 0;

        offsets += std::to_string(offset);
        offsets += ",";

        for (int i = 0; i < char_set; i++){
            auto entry = handle->h_PFAC_table[state * char_set + i];
            if (entry != TRAP_STATE) {

                size++;

                chars += std::to_string(i);
                chars += ",";

                states += std::to_string(entry);
                states += ",";
            
            }
            // PFAC_table_str += std::to_string(handle->h_PFAC_table[state * char_set + i]);
            // PFAC_table_str += ",";
        }

        sizes += std::to_string(size);
        sizes += ",";
        offset += size;
    }

    // PFAC_table_str.pop_back();
    chars.pop_back();
    states.pop_back();
    offsets.pop_back();
    sizes.pop_back();
    // int char_set = 256;
    

    // fn spec_match(@d_PFAC_table : &[i32],
    // @char_set : i32,
    // @num_states : i32,
    // @blocksize : i32,
    // @gridsize_x : i32,
    // @gridsize_y : i32,
    // @extrasize_tb : i32,
    // d_input_string : &[i32], 
    // @input_size : i32,
    // @n_hat : i32, 
    // @num_finalState : i32, 
    // @initial_state : i32, 
    // @num_blocks_minus1 : i32,
    // d_match_result : &mut[i32]) -> () {
    // run impala kernel <THREAD_BLOCK_SIZE, EXTRA_SIZE_PER_TB, 0, 1> <<< dimGrid, dimBlock >>>
    // std::string dummy;
    // dummy += "extern fn dummy(d_input_string : &[i32], d_match_result : &mut[i32]) -> (){\n";
    // dummy += "  spec_match([" + PFAC_table_str+"]," +
    //                         std::to_string(char_set) + ", " +
    //                         std::to_string(handle->numOfStates) + ", " +
    //                         std::to_string(THREAD_BLOCK_SIZE) + ", " +
    //                         std::to_string(dimGrid.x) + ", " +
    //                         std::to_string(dimGrid.y) + ", " +
    //                         std::to_string(EXTRA_SIZE_PER_TB) + ", " +
    //                         "d_input_string, " +
    //                         std::to_string(input_size) + ", " +
    //                         std::to_string(n_hat) + ", " +
    //                         std::to_string(handle->numOfFinalStates) + ", " +
    //                         std::to_string(handle->initial_state) + ", " +
    //                         std::to_string(num_blocks-1) + ", " +
    //                         "d_match_result)\n}\n";


    std::string dummy;
    dummy += "extern fn dummy(d_input_string : &[i32], d_match_result : &mut[i32], size : i32,blocks_minus1 : i32, n_hat : i32) -> (){\n";
    dummy += "  spec_match_compressed([" + states +"]," +
                            "[" + chars + "]," +
                            "[" + offsets + "]," + 
                            "[" + sizes + "]," +
                            std::to_string(char_set) + ", " +
                            std::to_string(handle->numOfStates) + ", " +
                            std::to_string(THREAD_BLOCK_SIZE) + ", " +
                            std::to_string(dimGrid.x) + ", " +
                            std::to_string(dimGrid.y) + ", " +
                            std::to_string(EXTRA_SIZE_PER_TB) + ", " +
                            "d_input_string, size,n_hat, " +
                            // std::to_string(input_size) + ", " +
                            // std::to_string(n_hat) + ", " +
                            std::to_string(handle->numOfFinalStates) + ", " +
                            std::to_string(handle->initial_state) + ", " +
                            // std::to_string(num_blocks-1) + ", " +
                            "blocks_minus1,d_match_result)\n}\n";


    std::string program = std::string((char*)___impala_spec_match_impala) + dummy;
    
    std::cout << "Compiling ..." << "\n";
    
    auto key = anydsl_compile(program.c_str(),program.size(),0);
    
    typedef void (*function) (const int*,const int *, const int, int,int);
    
    auto call = reinterpret_cast<function>(anydsl_lookup_function(key,"dummy"));
    
    if (call == nullptr) {
        std::cout << "compilation failed\n";
        return;
    } else {
        std::cout << "succesfully compiled\n";
    }

    call((int*)d_input_string,d_matched_result, input_size, num_blocks-1,n_hat);

    } else if (ALGO == 3){
    std::string dummy;
    dummy += "extern fn dummy(d_patterns_table : &[i32],d_input_string : &[i32], d_match_result : &mut[i32], size : i32,blocks_minus1 : i32) -> (){\n";
    dummy += "  spec_match_global(d_patterns_table," +
                            std::to_string(char_set) + ", " +
                            std::to_string(THREAD_BLOCK_SIZE) + ", " +
                            std::to_string(dimGrid.x) + ", " +
                            std::to_string(dimGrid.y) + ", " +
                            std::to_string(EXTRA_SIZE_PER_TB) + ", " +
                            "d_input_string, size, " +
                            // std::to_string(input_size) + ", " +
                            std::to_string(n_hat) + ", " +
                            std::to_string(handle->numOfFinalStates) + ", " +
                            std::to_string(handle->initial_state) + ", " +
                            // std::to_string(num_blocks-1) + ", " +
                            "blocks_minus1,d_match_result)\n}\n";


    std::string program = std::string((char*)___impala_spec_match_impala) + dummy;
    
    std::cout << "Compiling ..." << "\n";
    
    auto key = anydsl_compile(program.c_str(),program.size(),0);
    
    typedef void (*function) (const int*,const int*,const int *, const int, int);
    
    auto call = reinterpret_cast<function>(anydsl_lookup_function(key,"dummy"));
    
    if (call == nullptr) {
        std::cout << "compilation failed\n";
        return;
    } else {
        std::cout << "succesfully compiled\n";
    }

    call(handle->d_PFAC_table,(int*)d_input_string,d_matched_result, input_size,num_blocks-1);
    
    }else if(ALGO == 4) {
        dim3 dimBlock = (THREAD_BLOCK_SIZE); 
        impalaCorasickWrapper(dimGrid, dimBlock,(int*)d_input_string,d_matched_result,input_size,num_blocks-1,n_hat);
    }else if (ALGO == 5) {
        int blocks = (input_size + THREAD_BLOCK_SIZE - 1) / THREAD_BLOCK_SIZE;
        int p_ = blocks >> 15 ;
        dim3 grid;
        grid.x = blocks ;
        if ( p_){
            grid.x = 1<<15 ;
            grid.y = p_+1 ;
        }
        dim3 dimBlock = (THREAD_BLOCK_SIZE);
        impalaNaiveWrapper(grid,dimBlock,(unsigned char *)d_input_string,d_matched_result,input_size);
    }else if (ALGO == 6) {
        dim3 dimBlock = (THREAD_BLOCK_SIZE);
        impalaNaiveOptWrapper(dimGrid,dimBlock,(int*)d_input_string,d_matched_result,input_size,num_blocks-1,n_hat);
    }else if (ALGO == 7) {

        std::vector<std::string> vpatterns;

        for (int i = 0; i < handle->numOfPatterns; i++) {
            vpatterns.push_back(std::string(handle->rowPtr[i],handle->patternLen_table[i+1]));
        }

        std::string sizes;

        int len = 0;
        sizes = std::to_string(vpatterns[0].size());
        for(int i = 1; i < vpatterns.size(); i++) {
            sizes += "," + std::to_string(vpatterns[i].size());
            len +=  vpatterns[i].size();   
        }
    

        std::string dummy;

        std::string patterns;
        for (auto &vp : vpatterns) patterns += vp;

        int blocks = (input_size + THREAD_BLOCK_SIZE - 1) / THREAD_BLOCK_SIZE;

    //maybe asyncronous read from disk and jit;
        dummy += "extern fn dummy(text : &[u8], text_size : i32, result_buf : &mut[i32], blocks : i32) -> (){\n";

        dummy += "  string_match_multiple(\"" + patterns + "\","
              + "["+ sizes + "]" +
               "," + std::to_string(vpatterns.size()) +
               ", text, text_size, result_buf," + 
               std::to_string(THREAD_BLOCK_SIZE) + 
               ", blocks" +
            //    std::to_string(blocks) +
                ")}\n"; //;

        std::string program = std::string((char*)___impala_spec_match_impala) + dummy;

        std::cout << "compiling ... " << std::flush;
    
        auto key = anydsl_compile(program.c_str(),program.size(),0);

        typedef void (*function) (const char*, int, const int *, int);
        auto call = reinterpret_cast<function>(anydsl_lookup_function(key,"dummy"));
    
        if (call == nullptr) {
            std::cout << "compiliacion failed\n";
            return;
        } else {
            std::cout << "succesfully compiled\n";
        }

        std::cout << "\n";
    
        
        call(d_input_string,input_size,d_matched_result,blocks);
        
    } else if(ALGO == 8) {

        std::vector<std::string> vpatterns;

        for (int i = 0; i < handle->numOfPatterns; i++) {
            vpatterns.push_back(std::string(handle->rowPtr[i],handle->patternLen_table[i+1]));
        }

        int* sizes = new int[vpatterns.size()];

        int len = 0;
        for(int i = 0; i < vpatterns.size(); i++) {
            sizes[i] = vpatterns[i].size();
            len += sizes[i];    
        }
    
        int loffset = 0;

        char* d_patterns;
        int* d_sizes;

        cudaMalloc((void**)&d_sizes, (vpatterns.size())*sizeof(int));
        cudaMemcpy((void*)d_sizes, sizes, (vpatterns.size())*sizeof(int), cudaMemcpyHostToDevice); 
    
        cudaMalloc((void**)&d_patterns, len * sizeof(char));
    
        for(int i = 0; i < vpatterns.size(); i++){
            cudaMemcpy((void*)(d_patterns + loffset*sizeof(char)),vpatterns[i].c_str(),vpatterns[i].size(),cudaMemcpyHostToDevice);
            loffset += sizes[i];
        }

        // int num_blocks = (n_hat + THREAD_BLOCK_SIZE - 1) / THREAD_BLOCK_SIZE;
        // // int p = num_blocks / 32768;
        // dim3 grid;

        // if(p > 0) {
        //     grid.x = 32768;
        //     grid.y = p + 1;
        // } else {
        //     grid.x = num_blocks;
        // }
        dim3 dimBlock = (THREAD_BLOCK_SIZE);

        matchNaiveOptWrapper(dimGrid,dimBlock,d_patterns,d_sizes,vpatterns.size(),(int*)d_input_string,input_size,n_hat,num_blocks-1,d_matched_result);

        cudaDeviceSynchronize();
        delete[](sizes);
        cudaFree(d_patterns);
        cudaFree(d_sizes);

    }
    

}
