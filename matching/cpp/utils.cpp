#include <iostream>
#include <stdlib.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fstream>
#include <math.h>

#include "utils.hpp"
#include "cuda_runtime.h"

size_t get_file_size(std::string filename)
{
    // struct stat stat_buf;
    // int rc = stat(filename.c_str(), &stat_buf);
    // return rc == 0 ? stat_buf.st_size : -1;
    int fd = open(filename.c_str(),O_RDONLY);  //;
    size_t size = lseek(fd, 0, SEEK_END);
    close(fd);
    return size;
}

std::vector<std::string> read_pattern(std::string filename){
    
    std::ifstream file(filename,std::ios::binary);
    std::vector<std::string> res = std::vector<std::string>();
 
    if (!file) 
    {
        std::cout << "error openning pattern file" << "\n"; 
        return res;
    // TODO: assign item_name based on line (or if the entire line is 
    // the item name, replace line with item_name in the code above)
    }
    while(!file.eof()){

        std::string str;
        std::getline(file,str,'\0');
        res.push_back(str);
    }

    return res;

}

char* read_file(std::string filename, size_t &text_size, size_t size, size_t offset){
    
    size_t f_size = get_file_size(filename);//TODO
    if(f_size == -1){
        std::cout << "bad_size" << "\n";
        return nullptr;
    }
    //read file
    FILE *f;
    if((f = fopen(filename.c_str(), "rb")) == NULL){
	    std::cout << "can not open file" << filename << "\n";
	    return nullptr;
    }

    if(size != 0 && size <= f_size){
        text_size = size;
    }else{
        text_size = f_size;
    }

    if(offset != 0){
        fseek(f,offset * sizeof(char),SEEK_CUR);
        if((f_size - offset) < size){
            text_size = f_size - offset;
        }
    }
    int text_chunk = 128 * 1024 * 1024;
    if(text_size < text_chunk) {
        text_chunk = text_size;
    }
    char *subject_string = new char[text_chunk];

    char* dtextptr;
    
    cudaMalloc((void**)&dtextptr, text_size * sizeof(char));

    size_t nbytes;

    for(size_t i = 0; i < (text_size + text_chunk - 1) / text_chunk; i++){//number of chunks
        
        if(feof(f)){
            std::cout << "premature end of file" << "\n";
            break;
        }

        size_t right_bound = (i+1) * text_chunk < text_size ? (i+1) * text_chunk : text_size;
        size_t left_bound = i * text_chunk;
        nbytes = fread(subject_string,sizeof(char),right_bound-(left_bound),f);
        cudaMemcpy((void*)(dtextptr + left_bound),subject_string,nbytes,cudaMemcpyHostToDevice);

    }

    delete[](subject_string);
    fclose(f);

    return dtextptr;
}

void write_from_device(char** dresult_buf,size_t text_size){

    int text_chunk = 128 * 1024 * 1024;
    if(text_size < text_chunk) {
        text_chunk = text_size;
    }

    char* result_buf = new char[text_chunk];


    for(size_t i = 0; i < (text_size + text_chunk - 1) / text_chunk; i++){ //number of chunks

        size_t right_bound = (i+1) * text_chunk < text_size ? (i+1) * text_chunk : text_size;
        size_t left_bound = i * text_chunk;

        cudaMemcpy((void*)(result_buf),((*dresult_buf)+left_bound),(right_bound-(left_bound))*sizeof(char),cudaMemcpyDeviceToHost);
        
        for (size_t i = 0; i < (right_bound-left_bound); i++) {
            std::cout << (int)(result_buf[i]);
        }

    }
    std::cout << "\n";
    delete[] (result_buf);

}