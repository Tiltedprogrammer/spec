#include <string>
#include <iostream>

#define RUNTIME_ENABLE_JIT
#include <anydsl_runtime.h>

// Generated from fun.impala
#include "fun.inc"


int main(int argc, char** argv) {
    
    // if (argc != 2 ) {
        // std::cout << "pattern string required\n";
        // return 0;
    // }
    std::string pattern = std::string(argv[1]);

    if (pattern.size() > 31) {
        std::cout << "pattern should be less then or eq 31 bytes\n";
        return 0;
    }
    auto pattern_size = pattern.size();
    pattern.resize(31,'0'); 
    std::cout << pattern_size << "\n";
    std::cout << pattern << "\n";
        
    std::string dummy_fun;

    //maybe asyncronous read from disk and jit;
    dummy_fun += "extern fn dummy(text : &[u8], text_size : i32, result_buf : &mut[i32]) -> (){\n";
    
    dummy_fun += "  string_match(Template { array : \"" + pattern + "\", size : "
              + std::to_string(pattern_size) + "},32i8 ,text, text_size,result_buf,256,256)}"; //;

    std::string program = std::string((char*)fun_impala) + dummy_fun;
    auto key = anydsl_compile(program.c_str(),program.size(),0);
    typedef void (*function) (const char*, int, const int *);
    auto call = reinterpret_cast<function>(anydsl_lookup_function(key,"dummy"));
    if (call == nullptr) {
        std::cout << "compiliacion failed\n";
        return 0;
    }
    
    std::string text = std::string(argv[2]);
    // std::cin >> text;
    auto text_size = text.length();
    int* result_buf = new int[text_size];
    int* dresult_buf;
    char* dtext;
    //think about data transfer;
    cudaMalloc((void**)&dtext, text_size * sizeof(char));
    cudaMemcpy((void*)dtext,text.c_str(),text_size * sizeof(char),cudaMemcpyHostToDevice);
    cudaMalloc((void**)&dresult_buf, text_size * sizeof(int));
    
    // for(int i = 0; i < text_size; i++) {
        // result_buf[i] = -1;
    // }
    // cudaMemset((void*)dresult_buf, -1, text_size*sizeof(int));
    
    // call(text.c_str(),text_size,result_buf);
    call(dtext,text_size,dresult_buf);
    cudaMemcpy((void*)result_buf,dresult_buf,text_size*sizeof(int),cudaMemcpyDeviceToHost);

    for (int i = 0; i < text_size; i++) {
        std::cout << result_buf[i];
    }
    std::cout << "\n";
    
    cudaFree(dresult_buf);
    cudaFree(dtext);
    delete[] (result_buf);

    return 0;
}