#include <iostream>
#include <stdio.h>

extern "C" {
    void println(char * str){
        puts(str);
    }
}

extern "C" void hello();

int main(int argc, char** argv) {
    
    hello(); 
}