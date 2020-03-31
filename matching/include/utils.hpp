#ifndef UTILS_HPP
#define UTILS_HPP 

#include <string>
#include <vector>


size_t get_file_size(std::string filename);

std::vector<std::string> read_pattern(std::string filename);

char* read_file(std::string filename,size_t &text_size,size_t size = 0, size_t offset = 0);

void write_from_device(char** dresult_buf,size_t text_size);


#endif