
// Patterns:
// AB
// ABE
// ABG
// BEDE
// ED

void match_naive_opt_spec_manual_corasick_jit(const int* __restrict__ d_input_string, int input_size, int n_hat, int num_blocks_minus1, int* d_match_result) {
    const int THREAD_BLOCK_SIZE = 256;
    const int EXTRA_SIZE_PER_TB = 128;
    int t_id = threadIdx.x;
    int gbid = blockIdx.y * gridDim.x + blockIdx.x;
    int start = gbid * THREAD_BLOCK_SIZE + t_id;
    int inputChar;
    int pos;
    __shared__ int s_input[ THREAD_BLOCK_SIZE + EXTRA_SIZE_PER_TB];
    unsigned char *s_char;
    if ( gbid > num_blocks_minus1 ){
        return ;
    }
    s_char = (unsigned char *)s_input;
    if ( start < n_hat ){
        s_input[t_id] = d_input_string[start];
    }
    start += THREAD_BLOCK_SIZE ;
    if ( (start < n_hat) && (t_id < EXTRA_SIZE_PER_TB) ){
        s_input[t_id + THREAD_BLOCK_SIZE] = d_input_string[start];
    }
    __syncthreads();
    int bdy = input_size - ( gbid * THREAD_BLOCK_SIZE * 4 );
    start = gbid * (THREAD_BLOCK_SIZE * 4) + t_id ;
    for (int j = 0; j < 4; j++) {
        int match = 0;
        pos = t_id + j * THREAD_BLOCK_SIZE;
        if (pos < bdy){
            inputChar = s_char[pos];
            switch(inputChar){
              case 65:
                if(++pos < bdy){
                  inputChar = s_char[pos];
                  switch(inputChar) {
                    case 66:
                      match = 1;
                      if(++pos < bdy){
                        inputChar = s_char[pos];
                        switch(inputChar) {
                          case 69:
                            match = 2;
                            break;
                          case 71:
                            match = 3;
                            break;
                        }
                      }
                      break; 
                    }
                }
                break;
              case 66:
                if(++pos < bdy){
                  inputChar = s_char[pos];
                  switch(inputChar) {
                    case 69:
                      if(++pos < bdy){
                        inputChar = s_char[pos];
                        switch(inputChar) {
                          case 68:
                            if(++pos < bdy){
                              inputChar = s_char[pos];
                              switch(inputChar) {
                                case 69:
                                match = 4;
                                break;
                              }
                            }
                            break;
                        }
                      }
                      break;
                    }
                }
                break;
              case 69:
                  if(++pos < bdy){
                    inputChar = s_char[pos];
                    switch(inputChar) {
                      case 68:
                      match = 5;
                      break;
                    }
                  }
                  break;
            }
}
if (gbid < num_blocks_minus1) {
    d_match_result[start] = match;
    start += THREAD_BLOCK_SIZE;
}else {
     if (start >= input_size){
         return;
     }
     d_match_result[start] = match;
     start += THREAD_BLOCK_SIZE;
}
}
}