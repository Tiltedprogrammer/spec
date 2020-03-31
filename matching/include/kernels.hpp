#ifndef KERNELS_HPP
#define KERNELS_HPP

#include <vector>
#include <string>

void multipattern_match_const_wrapper(std::vector<std::string> vpatterns, std::string file_name,size_t size, size_t offset,int verbose,std::vector<std::pair<int,int>> &res ,int res_to_vec);

void multipattern_match_wrapper(std::vector<std::string> vpatterns, std::string file_name,long size, long offset,int verbose,std::vector<std::pair<int,int>> &res ,int res_to_vec);

void multipattern_match_shared_wrapper(std::vector<std::string> vpatterns, std::string file_name,long size, long offset,int verbose,std::vector<std::pair<int,int>> &res ,int res_to_vec);

void match_naive_wrapper(std::string pattern, std::string subject_string_filename, int nochunk, long size, long offset,int verbose);

void multipattern_match_texture_wrapper(std::vector<std::string> vpatterns, std::string subject_string_filename, long size, long offset,int verbose); //nochunk == 0 => nochunk

#endif