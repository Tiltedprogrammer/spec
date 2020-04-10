#include "../spec_match.hpp"
#include "ImpalaKernels.hpp"


#define MANUAL_EXPAND_2( X )   { X ; X ; }
#define MANUAL_EXPAND_4( X )   { MANUAL_EXPAND_2( MANUAL_EXPAND_2( X ) )  }


#define  SUBSEG_MATCH_NOTEX( j, match ) \
    pos = t_id + j * THREAD_BLOCK_SIZE ;\
    if ( pos < bdy_ ){ \
        if (pos < bdy - 9 + 1 && s_char[pos] == 0x14\
                              && s_char[pos + 1] == 'f'\
                              && s_char[pos + 2] == 't'\
                              && s_char[pos + 3] == 'y'\
                              && s_char[pos + 4] == 'p'\
                              && s_char[pos + 5] == 'i'\
                              && s_char[pos + 6] == 's'\
                              && s_char[pos + 7] == 'o'\
                              && s_char[pos + 8] == 'm'){\
                              match = 1;}\
        if (pos < bdy - 9 + 1 && s_char[pos] == 0x18\
                              && s_char[pos + 1] == 'f'\
                              && s_char[pos + 2] == 't'\
                              && s_char[pos + 3] == 'y'\
                              && s_char[pos + 4] == 'p'\
                              && s_char[pos + 5] == '3'\
                              && s_char[pos + 6] == 'g'\
                              && s_char[pos + 7] == 'p'\
                              && s_char[pos + 8] == '5'){\
                              match = 2;}\
        if (pos < bdy - 16 + 1 && s_char[pos] == 0x1a\
                               && s_char[pos + 1] == 'E'\
                               && s_char[pos + 2] == 0xdf\
                               && s_char[pos + 3] == 0xa3\
                               && s_char[pos + 4] == 0x93\
                               && s_char[pos + 5] == 'B'\
                               && s_char[pos + 6] == 0x82\
                               && s_char[pos + 7] == 0x88\
                               && s_char[pos + 8] == 'm'\
                               && s_char[pos + 9] == 'a'\
                               && s_char[pos + 10] == 't'\
                               && s_char[pos + 11] == 'r'\
                               && s_char[pos + 12] == 'o'\
                               && s_char[pos + 13] == 's'\
                               && s_char[pos + 14] == 'k'\
                               && s_char[pos + 15] == 'a'){\
                               match = 3;}\
        if (pos < bdy - 3 + 1 && s_char[pos] == 0x1f\
                              && s_char[pos + 1] == 0x8b\
                              && s_char[pos + 2] == 0x08){\
                              match = 4;}\
        if (pos < bdy - 4 + 1 && s_char[pos] == '%'\
                              && s_char[pos + 1] == 'P'\
                              && s_char[pos + 2] == 'D'\
                              && s_char[pos + 3] == 'F'){\
                              match = 5;}\
        if (pos < bdy - 6 + 1 && s_char[pos] == 0x37\
                              && s_char[pos + 1] == 0x7a\
                              && s_char[pos + 2] == 0xbc\
                              && s_char[pos + 3] == 0xaf\
                              && s_char[pos + 4] == 0x27\
                              && s_char[pos + 5] == 0x1c){\
                              match = 6;}\
        if (pos < bdy - 4 + 1 && s_char[pos] == '8'\
                              && s_char[pos + 1] == 'B'\
                              && s_char[pos + 2] == 'P'\
                              && s_char[pos + 3] == 'S'){\
                              match = 7;}\
        if (pos < bdy - 8 + 1 && s_char[pos] == '<'\
                              && s_char[pos + 1] == '!'\
                              && s_char[pos + 2] == 'd'\
                              && s_char[pos + 3] == 'o'\
                              && s_char[pos + 4] == 'c'\
                              && s_char[pos + 5] == 't'\
                              && s_char[pos + 6] == 'y'\
                              && s_char[pos + 7] == 'p'){\
                              match = 8;}\
        if (pos < bdy - 3 + 1 && s_char[pos] == 'C'\
                              && s_char[pos + 1] == 'W'\
                              && s_char[pos + 2] == 'S'){\
                              match = 9;}\
        if (pos < bdy - 3 + 1 && s_char[pos] == 'F'\
                              && s_char[pos + 1] == 'W'\
                              && s_char[pos + 2] == 'S'){\
                              match = 10;}\
        if (pos < bdy - 6 + 1 && s_char[pos] == 'G'\
                              && s_char[pos + 1] == 'I'\
                              && s_char[pos + 2 ] == 'F'\
                              && s_char[pos + 3] == '8'\
                              && s_char[pos + 4] == '7'\
                              && s_char[pos + 5] == 'a'){\
                              match = 11;}\
        if (pos < bdy - 6 + 1 && s_char[pos] == 'G'\
                              && s_char[pos + 1] == 'I'\
                              && s_char[pos + 2 ] == 'F'\
                              && s_char[pos + 3] == '8'\
                              && s_char[pos + 4] == '9'\
                              && s_char[pos + 5] == 'a'){\
                              match = 12;}\
        if (pos < bdy - 3 + 1 && s_char[pos] == 'I'\
                              && s_char[pos + 1] == ' '\
                              && s_char[pos + 2] == 'I'){\
                              match = 13;}\
        if (pos < bdy - 3 + 1 && s_char[pos] == 'I'\
                              && s_char[pos + 1] == 'D'\
                              && s_char[pos + 2] == '3'){\
                              match = 14;}\
        if (pos < bdy - 2 + 1 && s_char[pos] == 'M'\
                              && s_char[pos + 1] == 'Z'){\
                              match = 15;}\
        if (pos < bdy - 37 + 1 && s_char[pos] == 'M'\
                               && s_char[pos + 1] == 'i'\
                               && s_char[pos + 2] == 'c'\
                               && s_char[pos + 3] == 'r'\
                               && s_char[pos + 4] == 'o'\
                               && s_char[pos + 5] == 's'\
                               && s_char[pos + 6] == 'o'\
                               && s_char[pos + 7] == 'f'\
                               && s_char[pos + 8] == 't'\
                               && s_char[pos + 9] == ' '\
                               && s_char[pos + 10] == 'V'\
                               && s_char[pos + 11] == 'i'\
                               && s_char[pos + 12] == 's'\
                               && s_char[pos + 13] == 'u'\
                               && s_char[pos + 14] == 'a'\
                               && s_char[pos + 15] == 'l'\
                               && s_char[pos + 16] == ' '\
                               && s_char[pos + 17] == 'S'\
                               && s_char[pos + 18] == 't'\
                               && s_char[pos + 19] == 'u'\
                               && s_char[pos + 20] == 'd'\
                               && s_char[pos + 21] == 'i'\
                               && s_char[pos + 22] == 'o'\
                               && s_char[pos + 23] == ' '\
                               && s_char[pos + 24] == 'S'\
                               && s_char[pos + 25] == 'o'\
                               && s_char[pos + 26] == 'l'\
                               && s_char[pos + 27] == 'u'\
                               && s_char[pos + 28] == 't'\
                               && s_char[pos + 29] == 'i'\
                               && s_char[pos + 30] == 'o'\
                               && s_char[pos + 31] == 'n'\
                               && s_char[pos + 32] == ' '\
                               && s_char[pos + 33] == 'F'\
                               && s_char[pos + 34] == 'i'\
                               && s_char[pos + 35] == 'l'\
                               && s_char[pos + 36] == 'e'){\
                               match = 16;}\
        if (pos < bdy - 15 + 1 && s_char[pos] == 'O'\
                               && s_char[pos + 1] == 'P'\
                               && s_char[pos + 2] == 'L'\
                               && s_char[pos + 3] == 'D'\
                               && s_char[pos + 4] == 'a'\
                               && s_char[pos + 5] == 't'\
                               && s_char[pos + 6] == 'a'\
                               && s_char[pos + 7] == 'b'\
                               && s_char[pos + 8] == 'a'\
                               && s_char[pos + 9] == 's'\
                               && s_char[pos + 10] == 'e'\
                               && s_char[pos + 11] == 'F'\
                               && s_char[pos + 12] == 'i'\
                               && s_char[pos + 13] == 'l'\
                               && s_char[pos + 14] == 'e'){\
                               match = 17;}\
        if (pos < bdy - 8 + 1 && s_char[pos] == 'P'\
                              && s_char[pos + 1] == 'A'\
                              && s_char[pos + 2] == 'G'\
                              && s_char[pos + 3]  == 'E'\
                              && s_char[pos + 4] == 'D'\
                              && s_char[pos + 5] == 'U'\
                              && s_char[pos + 6] == '6'\
                              && s_char[pos + 7] == '4'){\
                              match = 18;}\
        if (pos < bdy - 4 + 1 && s_char[pos] == 'P'\
                              && s_char[pos + 1] == 'K'\
                              && s_char[pos + 2] == 0x03\
                              && s_char[pos + 3] == 0x04){\
                              match = 19;}\
        if (pos < bdy - 8 + 1 && s_char[pos] == 'P'\
                              && s_char[pos + 1] == 'K'\
                              && s_char[pos + 2] == 0x05\
                              && s_char[pos + 3] == 0x06\
                              && s_char[pos + 4] == 'P'\
                              && s_char[pos + 5] == 'K'\
                              && s_char[pos + 6] == 0x07\
                              && s_char[pos + 7] == 0x08){\
                              match = 20;}\
        if (pos < bdy - 13 + 1 && s_char[pos] == 'R'\
                               && s_char[pos + 1] == 'e'\
                               && s_char[pos + 2] == 't'\
                               && s_char[pos + 3] == 'u'\
                               && s_char[pos + 4] == 'r'\
                               && s_char[pos + 5] == 'n'\
                               && s_char[pos + 6] == '-'\
                               && s_char[pos + 7] == 'P'\
                               && s_char[pos + 8] == 'a'\
                               && s_char[pos + 9] == 't'\
                               && s_char[pos + 10] == 'h'\
                               && s_char[pos + 11] == ':'\
                               && s_char[pos + 12] == ' '){\
                               match = 21;}\
        if (pos < bdy - 15 + 1 && s_char[pos] == '['\
                               && s_char[pos + 1] == 'W'\
                               && s_char[pos + 2] == 'i'\
                               && s_char[pos + 3] == 'n'\
                               && s_char[pos + 4] == 'd'\
                               && s_char[pos + 5] == 'o'\
                               && s_char[pos + 6] == 'w'\
                               && s_char[pos + 7] == 's'\
                               && s_char[pos + 8] == ' '\
                               && s_char[pos + 9] == 'L'\
                               && s_char[pos + 10] == 'a'\
                               && s_char[pos + 11] == 't'\
                               && s_char[pos + 12] == 'i'\
                               && s_char[pos + 13] == 'n'\
                               && s_char[pos + 14] == ' '){\
                               match = 22;}\
        if (pos < bdy - 8 + 1 && s_char[pos] == 'f'\
                        && s_char[pos + 1] == 't'\
                        && s_char[pos + 2] == 'y'\
                        && s_char[pos + 3] == 'p'\
                        && s_char[pos + 4] == 'M'\
                        && s_char[pos + 5] == 'S'\
                        && s_char[pos + 6] == 'N'\
                        && s_char[pos + 7] == 'V'){\
                        match = 23;}\
        if (pos < bdy - 16 + 1 && s_char[pos] == 0x7c\
                               && s_char[pos + 1] == 0x4b\
                               && s_char[pos + 2] == 0xc3\
                               && s_char[pos + 3] == 0x74\
                               && s_char[pos + 4] == 0xe1\
                               && s_char[pos + 5] == 0xc8\
                               && s_char[pos + 6] == 0x53\
                               && s_char[pos + 7] == 0xa4\
                               && s_char[pos + 8] == 0x79\
                               && s_char[pos + 9] == 0xb9\
                               && s_char[pos + 10] == 0x01\
                               && s_char[pos + 11] == 0x1d\
                               && s_char[pos + 12] == 0xfc\
                               && s_char[pos + 13] == 0x4f\
                               && s_char[pos + 14] == 0xdd\
                               && s_char[pos + 15] == 0x13){\
                               match = 24;}\
        if (pos < bdy - 28 + 1 && s_char[pos] == 0x7e\
                               && s_char[pos + 1] == 'E'\
                               && s_char[pos + 2] == 'S'\
                               && s_char[pos + 3] == 'D'\
                               && s_char[pos + 4] == 'w'\
                               && s_char[pos + 5] == 0xf6\
                               && s_char[pos + 6] == 0x85\
                               && s_char[pos + 7] == '>'\
                               && s_char[pos + 8] == 0xbf\
                               && s_char[pos + 9] == 'j'\
                               && s_char[pos + 10] == 0xd2\
                               && s_char[pos + 11] == 0x11\
                               && s_char[pos + 12] == 'E'\
                               && s_char[pos + 13] == 'a'\
                               && s_char[pos + 14] == 's'\
                               && s_char[pos + 15] == 'y'\
                               && s_char[pos + 16] == ' '\
                               && s_char[pos + 17] == 'S'\
                               && s_char[pos + 18] == 't'\
                               && s_char[pos + 19] == 'r'\
                               && s_char[pos + 20] == 'e'\
                               && s_char[pos + 21] == 'e'\
                               && s_char[pos + 22] == 't'\
                               && s_char[pos + 23] == ' '\
                               && s_char[pos + 24] == 'D'\
                               && s_char[pos + 25] == 'r'\
                               && s_char[pos + 26] == 'a'\
                               && s_char[pos + 27] == 'w'){\
                               match = 25;}\
        if (pos < bdy - 16 + 1 && s_char[pos] == 0xbe\
                               && s_char[pos + 1] == 0xba\
                               && s_char[pos + 2] == 0xfe\
                               && s_char[pos + 3] == 0xca\
                               && s_char[pos + 4] == 0x0f\
                               && s_char[pos + 5] == 'P'\
                               && s_char[pos + 6] == 'a'\
                               && s_char[pos + 7] == 'l'\
                               && s_char[pos + 8] == 'm'\
                               && s_char[pos + 9] == 'S'\
                               && s_char[pos + 10] == 'G'\
                               && s_char[pos + 11] == ' '\
                               && s_char[pos + 12] == 'D'\
                               && s_char[pos + 13] == 'a'\
                               && s_char[pos + 14] == 't'\
                               && s_char[pos + 15] == 'a'){\
                               match = 26;}\
        if (pos < bdy - 8 + 1 && s_char[pos] == 0xd0\
                              && s_char[pos + 1] == 0xcf\
                              && s_char[pos + 2] == 0x11\
                              && s_char[pos + 3] == 0xe0\
                              && s_char[pos + 4] == 0xa1\
                              && s_char[pos + 5] == 0xb1\
                              && s_char[pos + 6] == 0x1a\
                              && s_char[pos + 7] == 0xe1){\
                              match = 27;}\
    }

__global__ void match_naive_opt_spec_manual(const int* __restrict__ d_input_string, int input_size, int n_hat, int num_blocks_minus1, int* d_match_result) {
    
    int t_id = threadIdx.x;
    int gbid = blockIdx.y * gridDim.x + blockIdx.x;

    int start = gbid * THREAD_BLOCK_SIZE + t_id ;
    int pos;
    int inputChar;
    int match[4] = {0,0,0,0};
    __shared__ int s_input[ THREAD_BLOCK_SIZE + EXTRA_SIZE_PER_TB];
    
    unsigned char *s_char;
    
    if ( gbid > num_blocks_minus1 ){
        return ; // whole block is outside input stream
    }

    s_char = (unsigned char *)s_input;

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

void matchNaiveSpecManualOptWrapper(dim3 grid, dim3 block,const int* d_input_string, int input_size, int n_hat, int num_blocks_minus1, int* d_match_result){
    RUN((match_naive_opt_spec_manual<<<grid,block>>>(d_input_string,input_size,n_hat,num_blocks_minus1,d_match_result)))
}