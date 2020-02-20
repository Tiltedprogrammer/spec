# spec
A repository that contain some benchmarks for partial evaluation of different GPU application scenarios leveraging [AnyDSL framework](https://anydsl.github.io/ "AnyDSL project") and CUDA.

# Implementations
* Multiple string matching:
  * Three naive implementations in CUDA using *global*, *constant* and *shared* memory respectively to store the patterns
  * Implementation utilizing partial evaluation to "store" the patterns
 * Image separable convolution
   * Separable convolution taken from NVIDIA's SDK with contant memory to store the filter
   * Implementation utilizing partial evaluation to "store" the filter
   
 # Partial evaluation
 *Partial evaluation* or *program specialization* is a well-known optimization technique that given a program and part of its input data, called *static*, specializes the program with respect to the data, producing another, optimized, program which if given only the remaining part of input data, called *dynamic*, yeilds the same results as the original program would have produced being executed given both parts of the input data.

Considering optimization of GPU memory accesses, partial evaluation is able to embed statically known array values directly into the code. More precisely, it allows the values to be accessed via instruction cache rather than through issuing load instructions.

For example, the following CUDA kernel:

```C
__global__ void match_multy(char* patterns, int* p_sizes, int p_number, char* text, long text_size, char* result_buf) {

    long t_id = threadId();

    if(t_id < text_size){
        int p_offset = 0;
        int matched = 1;
        
        result_buf[t_id] = 0;

        for(int i = 0; i < p_number; i++) {//for each pattern
            matched = 1;
            if(t_id < text_size - p_sizes[i] + 1) {
                for(int j = 0; j < p_sizes[i]; j++) {
                
                    if(text[t_id + j] != patterns[j+p_offset]) {
                        matched = -1;
                        break;
                    }
                } 
            
                if(matched == 1) {
                    result_buf[t_id] = i+1; // 0 stands for missmatch
                }
            }
            p_offset += p_sizes[i];
        }             
    }
}
```
compiles to something like this:

![alt text](https://i.ibb.co/7Y8xzWm/Screenshot-from-2020-02-18-23-21-18.png)

However, since ```*patterns``` are fixed at runtime, partial evaluation could be applied resulting in the following residual compiled code:

![alt text](https://i.ibb.co/s2pQnqF/Screenshot-from-2020-02-18-23-28-54.png)

# Build instructions
