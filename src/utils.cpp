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
    int size = argc - 1;
    auto c_array = new char[size];
    for (size_t i = 0; i < size; i++)
    {
        char elem = *(argv[i+1]);
        c_array[i] = elem;
    }

    std::string c(c_array);
    
    std::string dummy_fun;
    //retrives value with key == 7
    dummy_fun += "extern fn dummy(vals : &[u8]) -> (){\n";
    //chage get42_cuda to get42 for cpu version
    dummy_fun += "  let b = get42_cuda(Keys { array:\""+ c + "\"},vals,'7');\n";
    dummy_fun += "  print_char(b);";
    dummy_fun += "  print_string(\"\n\");}";

    std::string program = std::string((char*)fun_impala) + dummy_fun;
    auto key = anydsl_compile(program.c_str(),program.size(),0);
    typedef char (*function) (const char*);
    auto call = reinterpret_cast<function>(anydsl_lookup_function(key,"dummy"));
    call("abcdefghi");


    delete c_array;
    
    return 0;
}