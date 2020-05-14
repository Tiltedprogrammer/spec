#include <rmm/rmm.h>
#include <NVStrings.h>
#include <iostream>
#include <vector>
#include <string>

int main(int argc, char** argv){

    std::vector<std::string> v_str;
    v_str.push_back("Mr and Mrs Dursley, of number four, Privet Drive, were proud to say "
                     "that they were perfectly normal, thank you very much.");
    v_str.push_back(" They were the last people you’d expect to be involved in anything"
                    "strange or mysterious, because they just didn’t hold with such nonsense. ");
    v_str.push_back("Mr Dursley was the director of a firm called Grunnings, which made drills.");

    
    return 0;

}