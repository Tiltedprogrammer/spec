multiple_match_const_unroll
__device__ long threadId(){
long blockId = (long)blockIdx.y * (long)gridDim.x + (long)blockIdx.x;
long threadId = blockId * (long)blockDim.x + (long)threadIdx.x;
return threadId;
}
__constant__ int mpatterns[128*64];
__global__
void multiple_match_const_unroll(char* text, long text_size, char* result_buf) {
    long t_id = threadId();
    if(t_id < text_size){
       int p_offset = 0;
       int matched = 1;
       int match_result = 0;
       if(t_id < text_size -16 + 1){
        matched = 1;
        #pragma unroll
      for(int j = 0; j < 3; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
             matched = -1;
             break;
          }
      }
      if(matched == 1) {
          match_result = 0+1;
      }
      p_offset += 3;
      matched = 1;
      #pragma unroll
      for(int j = 0; j < 3; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
             matched = -1;
             break;
          }
      }
      if(matched == 1) {
          match_result = 1+1;
      }
      p_offset += 3;
      matched = 1;
      #pragma unroll
      for(int j = 0; j < 16; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
             matched = -1;
             break;
          }
      }
      if(matched == 1) {
          match_result = 2+1;
      }
      p_offset += 16;
      matched = 1;
      #pragma unroll
      for(int j = 0; j < 16; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
             matched = -1;
             break;
          }
      }
      if(matched == 1) {
          match_result = 3+1;
      }
      p_offset += 16;
      matched = 1;
      #pragma unroll
      for(int j = 0; j < 16; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
             matched = -1;
             break;
          }
      }
      if(matched == 1) {
          match_result = 4+1;
      }
      p_offset += 16;
      matched = 1;
      #pragma unroll
      for(int j = 0; j < 5; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
             matched = -1;
             break;
          }
      }
      if(matched == 1) {
          match_result = 5+1;
      }
      p_offset += 5;
      matched = 1;
      #pragma unroll
      for(int j = 0; j < 6; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
             matched = -1;
             break;
          }
      }
      if(matched == 1) {
          match_result = 6+1;
      }
      p_offset += 6;
      matched = 1;
      #pragma unroll
      for(int j = 0; j < 3; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
             matched = -1;
             break;
          }
      }
      if(matched == 1) {
          match_result = 7+1;
      }
      p_offset += 3;
      matched = 1;
      #pragma unroll
      for(int j = 0; j < 4; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
             matched = -1;
             break;
          }
      }
      if(matched == 1) {
          match_result = 8+1;
      }
      p_offset += 4;
      matched = 1;
      #pragma unroll
      for(int j = 0; j < 4; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
             matched = -1;
             break;
          }
      }
      if(matched == 1) {
          match_result = 9+1;
      }
      p_offset += 4;
      matched = 1;
      #pragma unroll
      for(int j = 0; j < 3; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
             matched = -1;
             break;
          }
      }
      if(matched == 1) {
          match_result = 10+1;
      }
      p_offset += 3;
      matched = 1;
      #pragma unroll
      for(int j = 0; j < 5; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
             matched = -1;
             break;
          }
      }
      if(matched == 1) {
          match_result = 11+1;
      }
      p_offset += 5;
      matched = 1;
      #pragma unroll
      for(int j = 0; j < 3; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
             matched = -1;
             break;
          }
      }
      if(matched == 1) {
          match_result = 12+1;
      }
      p_offset += 3;
      matched = 1;
      #pragma unroll
      for(int j = 0; j < 7; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
             matched = -1;
             break;
          }
      }
      if(matched == 1) {
          match_result = 13+1;
      }
      p_offset += 7;
      matched = 1;
      #pragma unroll
      for(int j = 0; j < 4; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
             matched = -1;
             break;
          }
      }
      if(matched == 1) {
          match_result = 14+1;
      }
      p_offset += 4;
      matched = 1;
      #pragma unroll
      for(int j = 0; j < 8; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
             matched = -1;
             break;
          }
      }
      if(matched == 1) {
          match_result = 15+1;
      }
      p_offset += 8;
      matched = 1;
      #pragma unroll
      for(int j = 0; j < 5; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
             matched = -1;
             break;
          }
      }
      if(matched == 1) {
          match_result = 16+1;
      }
      p_offset += 5;
      matched = 1;
      #pragma unroll
      for(int j = 0; j < 5; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
             matched = -1;
             break;
          }
      }
      if(matched == 1) {
          match_result = 17+1;
      }
      p_offset += 5;
      matched = 1;
      #pragma unroll
      for(int j = 0; j < 4; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
             matched = -1;
             break;
          }
      }
      if(matched == 1) {
          match_result = 18+1;
      }
      p_offset += 4;
      matched = 1;
      #pragma unroll
      for(int j = 0; j < 8; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
             matched = -1;
             break;
          }
      }
      if(matched == 1) {
          match_result = 19+1;
      }
      p_offset += 8;
   }else{
      matched = 1;
      if(t_id < text_size - 3 + 1){
      #pragma unroll
      for(int j = 0; j < 3; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
              matched = -1;
              break;
          }
      }
      if(matched == 1) {
         match_result = 0+1;
      }
}
      p_offset += 3;
      matched = 1;
      if(t_id < text_size - 3 + 1){
      #pragma unroll
      for(int j = 0; j < 3; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
              matched = -1;
              break;
          }
      }
      if(matched == 1) {
         match_result = 1+1;
      }
}
      p_offset += 3;
      matched = 1;
      if(t_id < text_size - 16 + 1){
      #pragma unroll
      for(int j = 0; j < 16; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
              matched = -1;
              break;
          }
      }
      if(matched == 1) {
         match_result = 2+1;
      }
}
      p_offset += 16;
      matched = 1;
      if(t_id < text_size - 16 + 1){
      #pragma unroll
      for(int j = 0; j < 16; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
              matched = -1;
              break;
          }
      }
      if(matched == 1) {
         match_result = 3+1;
      }
}
      p_offset += 16;
      matched = 1;
      if(t_id < text_size - 16 + 1){
      #pragma unroll
      for(int j = 0; j < 16; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
              matched = -1;
              break;
          }
      }
      if(matched == 1) {
         match_result = 4+1;
      }
}
      p_offset += 16;
      matched = 1;
      if(t_id < text_size - 5 + 1){
      #pragma unroll
      for(int j = 0; j < 5; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
              matched = -1;
              break;
          }
      }
      if(matched == 1) {
         match_result = 5+1;
      }
}
      p_offset += 5;
      matched = 1;
      if(t_id < text_size - 6 + 1){
      #pragma unroll
      for(int j = 0; j < 6; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
              matched = -1;
              break;
          }
      }
      if(matched == 1) {
         match_result = 6+1;
      }
}
      p_offset += 6;
      matched = 1;
      if(t_id < text_size - 3 + 1){
      #pragma unroll
      for(int j = 0; j < 3; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
              matched = -1;
              break;
          }
      }
      if(matched == 1) {
         match_result = 7+1;
      }
}
      p_offset += 3;
      matched = 1;
      if(t_id < text_size - 4 + 1){
      #pragma unroll
      for(int j = 0; j < 4; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
              matched = -1;
              break;
          }
      }
      if(matched == 1) {
         match_result = 8+1;
      }
}
      p_offset += 4;
      matched = 1;
      if(t_id < text_size - 4 + 1){
      #pragma unroll
      for(int j = 0; j < 4; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
              matched = -1;
              break;
          }
      }
      if(matched == 1) {
         match_result = 9+1;
      }
}
      p_offset += 4;
      matched = 1;
      if(t_id < text_size - 3 + 1){
      #pragma unroll
      for(int j = 0; j < 3; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
              matched = -1;
              break;
          }
      }
      if(matched == 1) {
         match_result = 10+1;
      }
}
      p_offset += 3;
      matched = 1;
      if(t_id < text_size - 5 + 1){
      #pragma unroll
      for(int j = 0; j < 5; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
              matched = -1;
              break;
          }
      }
      if(matched == 1) {
         match_result = 11+1;
      }
}
      p_offset += 5;
      matched = 1;
      if(t_id < text_size - 3 + 1){
      #pragma unroll
      for(int j = 0; j < 3; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
              matched = -1;
              break;
          }
      }
      if(matched == 1) {
         match_result = 12+1;
      }
}
      p_offset += 3;
      matched = 1;
      if(t_id < text_size - 7 + 1){
      #pragma unroll
      for(int j = 0; j < 7; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
              matched = -1;
              break;
          }
      }
      if(matched == 1) {
         match_result = 13+1;
      }
}
      p_offset += 7;
      matched = 1;
      if(t_id < text_size - 4 + 1){
      #pragma unroll
      for(int j = 0; j < 4; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
              matched = -1;
              break;
          }
      }
      if(matched == 1) {
         match_result = 14+1;
      }
}
      p_offset += 4;
      matched = 1;
      if(t_id < text_size - 8 + 1){
      #pragma unroll
      for(int j = 0; j < 8; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
              matched = -1;
              break;
          }
      }
      if(matched == 1) {
         match_result = 15+1;
      }
}
      p_offset += 8;
      matched = 1;
      if(t_id < text_size - 5 + 1){
      #pragma unroll
      for(int j = 0; j < 5; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
              matched = -1;
              break;
          }
      }
      if(matched == 1) {
         match_result = 16+1;
      }
}
      p_offset += 5;
      matched = 1;
      if(t_id < text_size - 5 + 1){
      #pragma unroll
      for(int j = 0; j < 5; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
              matched = -1;
              break;
          }
      }
      if(matched == 1) {
         match_result = 17+1;
      }
}
      p_offset += 5;
      matched = 1;
      if(t_id < text_size - 4 + 1){
      #pragma unroll
      for(int j = 0; j < 4; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
              matched = -1;
              break;
          }
      }
      if(matched == 1) {
         match_result = 18+1;
      }
}
      p_offset += 4;
      matched = 1;
      if(t_id < text_size - 8 + 1){
      #pragma unroll
      for(int j = 0; j < 8; j++) {
          if(text[t_id + j] != mpatterns[j + p_offset]) {
              matched = -1;
              break;
          }
      }
      if(matched == 1) {
         match_result = 19+1;
      }
}
      p_offset += 8;
   }
result_buf[t_id] = match_result;
}
}