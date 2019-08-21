#include <string>
#include <iostream>

#define RUNTIME_ENABLE_JIT
#include <anydsl_runtime.h>

// Generated from fun.impala
#include "fun.inc"

void println(int a) {
    printf("%i\n",a);
}


int main(int argc, char** argv) {
    
    std::string pattern = "abcdefg00";
    // pattern.resize(32);
    auto pattern_size = 7; 
        
    std::string dummy_fun;

    //maybe asyncronous read from disk and jit;
    dummy_fun += "extern fn dummy(text : &[u8], text_size : i32, result_buf : &mut[i32]) -> (){\n";
    //chage get42_cuda to get42 for cpu version
    dummy_fun += "  string_match(Pattern { array : \"" + pattern + "\", size : "
              + std::to_string(pattern_size) + "}, text, text_size,result_buf,32);}";

    std::string program = std::string((char*)fun_impala) + dummy_fun;
    auto key = anydsl_compile(program.c_str(),program.size(),0);
    typedef void (*function) (const char*, int, const int *);
    auto call = reinterpret_cast<function>(anydsl_lookup_function(key,"dummy"));
    
    int* result_buf;
    std::string text;
    std::cin >> text;
    auto text_size = text.length();
    std::cout << "text length : " << text_size << "\n";
    char* textptr;
    //think about data transfer;
    cudaMalloc((void**)&textptr, text_size + 1);
    cudaMemcpy((void*)textptr,text.c_str(),text_size + 1,cudaMemcpyHostToDevice);
    cudaMallocManaged((void**)&result_buf, text_size);
    
    cudaMemset((void*)result_buf, -1, text_size * sizeof(int));
    for (int i = 0; i < text_size; i++) {
        std::cout << result_buf[i];
    }
    std::cout << "\n";
    
    call(textptr,text_size,result_buf);

    for (int i = 0; i < text_size; i++) {
        std::cout << result_buf[i];
    }
    std::cout << "\n";
    
    cudaFree(result_buf);

    return 0;
}