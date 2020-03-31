#ifndef SPEC_MATCH_H
#define SPEC_MATCH_H

#define THREAD_BLOCK_EXP   (8)
#define EXTRA_SIZE_PER_TB  (128)
#define THREAD_BLOCK_SIZE  (1 << THREAD_BLOCK_EXP)

#include <PFAC.h>
#include <PFAC_P.h>
#include <string>
#include <vector>

int spec_match_from_host(PFAC_handle_t handle, char* h_input_string, size_t input_size, int* h_matched_result, int algorithm);


template<int>
void  spec_match_from_device( PFAC_handle_t handle, char *d_input_string, size_t input_size,
    int *d_matched_result );

#endif