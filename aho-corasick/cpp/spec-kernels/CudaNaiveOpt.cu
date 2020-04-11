#include "../spec_match.hpp"
#include "ImpalaKernels.hpp"


#define MANUAL_EXPAND_2( X )   { X ; X ; }
#define MANUAL_EXPAND_4( X )   { MANUAL_EXPAND_2( MANUAL_EXPAND_2( X ) )  }


#define  SUBSEG_MATCH_NOTEX( j, match ) \
    pos = t_id + j * THREAD_BLOCK_SIZE ;\
    if ( pos < bdy_ ){\
        if (pos < bdy - max_len + 1){\
            int offset = 0;\
            for (int i = 0; i < p_num; i++){\
                int pos_in = pos;\
                int matched = 1;\
                for(int ii = 0; ii < p_sizes[i]; ii++) {\
                        inputChar = s_char[pos_in];\
                        if (inputChar != d_patterns[offset + ii]){\
                            matched = 0;\
                            break;\
                        }\
                        pos_in += 1;\
                }\
                offset += p_sizes[i];\
                if (matched != 0) {\
                    match = i + 1;\
                }\
            }\
        }else{\
                int offset = 0;\
                for (int i = 0; i < p_num; i++){\
                    int pos_in = pos;\
                    int matched = 1;\
                    if (pos_in < bdy - p_sizes[i] + 1) {\
                        for(int ii = 0; ii < p_sizes[i]; ii++) {\
                            inputChar = s_char[pos_in];\
                            if (inputChar != d_patterns[offset + ii]){\
                                matched = 0;\
                                break;\
                            }\
                            pos_in += 1;\
                        }\
                    }else {\
                        matched = 0;\
                    }\
                    offset += p_sizes[i];\
                    if (matched != 0) {\
                        match = i + 1;\
                    }\
                }\
        }\
    }

__global__ void match_naive_opt(const char* __restrict__ d_patterns, int* p_sizes, int p_num, const int* __restrict__ d_input_string, int input_size, int n_hat, int num_blocks_minus1, int max_len, int* d_match_result) {
    
    int t_id = threadIdx.x;
    int gbid = blockIdx.y * gridDim.x + blockIdx.x;

    int start = gbid * THREAD_BLOCK_SIZE + t_id ;
    int pos;
    int inputChar;
    int match[4] = {0,0,0,0};
    __shared__ int s_input[ THREAD_BLOCK_SIZE + EXTRA_SIZE_PER_TB];
    
    char *s_char;
    
    if ( gbid > num_blocks_minus1 ){
        return ; // whole block is outside input stream
    }

    s_char = (char *)s_input;

    // read global data to shared memory
    if ( start < n_hat ){
        s_input[t_id] = d_input_string[start];
    }

    start += THREAD_BLOCK_SIZE ;
    if ( (start < n_hat) && (t_id < EXTRA_SIZE_PER_TB) ){
        s_input[t_id + THREAD_BLOCK_SIZE] = d_input_string[start];
    }
    __syncthreads();

    int bdy_ = input_size - ( gbid * THREAD_BLOCK_SIZE * 4 );
    int bdy = (EXTRA_SIZE_PER_TB + THREAD_BLOCK_SIZE) * 4 > bdy_ ? bdy_ : (EXTRA_SIZE_PER_TB + THREAD_BLOCK_SIZE) * 4;

    int j = 0 ;

    MANUAL_EXPAND_4( SUBSEG_MATCH_NOTEX(j, match[j]) ; j++ ;)
    

    // write 4 results  match[0:3] to global d_match_result[0:input_size)
    // one thread block processes (BLOCKSIZE * 4) substrings
    start = gbid * (THREAD_BLOCK_SIZE * 4) + t_id ;

    if ( gbid < num_blocks_minus1 ){
        #pragma unroll
        for (int j = 0 ; j < 4 ; j++ ){
            d_match_result[start] = match[j];
            start += THREAD_BLOCK_SIZE;
        }
    }else{
        int j = 0 ;
        MANUAL_EXPAND_4( if (start>=input_size) return ; d_match_result[start] = match[j]; \
        j++ ; start += THREAD_BLOCK_SIZE ; )
    } 


}

void matchNaiveOptWrapper(dim3 grid, dim3 block,const char* d_patterns, int* p_sizes, int p_num, const int* d_input_string, int input_size, int n_hat, int num_blocks_minus1,int max_len, int* d_match_result){
    RUN((match_naive_opt<<<grid,block>>>(d_patterns,p_sizes,p_num,d_input_string,input_size,n_hat,num_blocks_minus1,max_len,d_match_result)))
}