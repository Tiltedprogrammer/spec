# spec
A repository that contain some benchmarks for partial evaluation of different GPU application scenarios leveraging [AnyDSL framework](https://anydsl.github.io/ "AnyDSL project") and CUDA. Benchmarks are available as Python notebooks.

# Implementations
* Multiple string matching:
  * Three naive implementations in CUDA using *global*, *constant* and *shared* memory respectively to store the patterns
  * Implementation utilizing partial evaluation to "store" the patterns
 * Image separable convolution
   * Separable convolution taken from NVIDIA's SDK with constant memory to store the filter
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

The observed transformation results in the following performance of naive GPU pattern matching (evaluated using 16 file signatures as patterns and raw disk data as a subject string on GTX 1070):

![alt text](https://i.ibb.co/zsMSSgp/Screenshot-from-2020-02-10-00-08-30.png)

The performance gain occured due to poor access patterns to each memory space aggravated by thread divergence. Poor access patterns induce either sequential loading or fetching redundant memory to satisfy alignment and fetch size. E.g. actual amount of memory transered for GTX 1070 matching with patterns in global memory and for partially evaluated version are depicted below (subject string size is 2.9GB raw disk data, patterns total length is about 160B) 

* Global memory version:

![alt text](https://i.ibb.co/qsr6hGy/Bbis3h-Bn-2-Q.jpg)

* Partially evaluated one:

![alt text](https://i.ibb.co/RDCFWqc/GXT6x7-MJ4p-Q.jpg)

Thus, in case when e.g. constant memory achieves its best perforamance, partial evaluation hardly makes the application significantly faster. For example, considering *Separable Convolution Filter* implementation from *NVIDIA's* SDK, where filter kernel resides in constant memory and has the best access pattern, the relocation of the kernel performed by partial evaluation has the following effect:

![alt text](https://i.ibb.co/J7yHSHr/Screenshot-from-2020-02-19-20-55-26.png)


# Build instructions

## Dependencies
* Working installation of [AnyDSL framework](https://github.com/AnyDSL/anydsl)

   AnyDSL should be installed with ```RUNTIME_JIT:=true``` option set in ```config.sh```
* Working installation of NVIDIA CUDA with all paths set up
* Convolution filtering depends on *libjpeg*, e.g. ```sudo apt-get install libjpeg-dev```
* Python 3
* Python Jupyter notebook to view benchmarks
* Python matplotlib, e.g. ```pip3 install -r requirements.txt```

## Build
To build the test applications simply run:
```Bash
mkdir build && cd build && cmake .. -DCMAKE_BUILD_TYPE=Release -DAnyDSL_runtime_DIR="${PATH_TO_ANYDSL_FOLDER}/runtime/build/share/anydsl/cmake/" && make
```
or
```
cmake .. -DAnyDSL_runtime_DIR="${PATH_TO_ANYDSL_FOLDER}/runtime/build/share/anydsl/cmake/"
```
if ```cmake --version``` >= 3.11

To run the coresponding benchmarks, move compiled applications to coresponding benchmarking folder, run jupyter notebook -> Cell->Run All. E.g. for multiple pattern matching:

```Bash
mv build/matching/cpp/match.out ../matching/benchmarking && mv build/matching/impala/match_spec.out ../matching/benchmarking
```
Then open ```matching/benchmarking/MatchingBenchmarking.ipynb```, choose a file with a subject string and pass it to ```Runner```, e.g. one can provide ```/dev/sda1``` as input: ```runner = Runner(...,filename='/dev/sda1',offset=0...)
 ```and click ```Cell -> Run All```
