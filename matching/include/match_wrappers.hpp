#ifndef MATCH_WRAPPERS_HPP
#define MATCH_WRAPPERS_HPP

#include <iostream>
#include <vector>
#include <math.h>
#include <string>


#include <vector>
#include <string>

#ifndef BLOCKSIZE
#define BLOCKSIZE 512
#endif


void match_pe_pointer_multipattern(std::vector<std::string> vpatterns, std::string subject_string_filename, long size, long offset, int verbose, std::vector<std::pair<int,int>> &res, int res_to_vec);
void multipattern_match(std::vector<std::string> vpatterns, std::string file_name,long size, long offset,int verbose);

typedef void (*fun) (const char*,int,short int,char*,long,char*,int,int,int); 
void match_nope(std::string subject_string_filename,std::string pattern,int pattern_size, int nochunk, fun f,long size,long offset,int verbose);

void match_pe_pat(std::string subject_string_filename,std::string program_,std::string pattern, int pattern_size,long size,long offset);

void match_pe(std::string subject_string_filename,long size, long offset,std::string program_, int verbose);



#endif