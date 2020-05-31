#include <rmm/rmm.h>
#include <NVStrings.h>
#include <iostream>
#include <vector>
#include <string>

// CUDA runtime
#include <cuda_runtime.h>
// using namespace NVStrings;

int main(int argc, char** argv){

    std::vector<std::string> v_str;
    v_str.push_back("Mr and Mrs Dursley, of number last four, Privet Drive, were proud to say "
                     "that they were perfectly normal, thank you very much.");
    v_str.push_back(" They were the last people you’d expect to be involved in anything"
                    "strange or mysterious, because they just didn’t hold with such nonsense. ");
    v_str.push_back("Mr Dursley was the director of a firm called Grunnings, which made drills.");

    auto strs = new std::pair<const char*,size_t>[v_str.size()];

    for(int i = 0; i < v_str.size(); i++){
        strs[0] = std::pair<const char*,size_t>(v_str[i].c_str(),v_str[i].size());
    }

    auto nv_handle = NVStrings::create_from_index(strs,v_str.size(),false);
    std::cout << nv_handle->size() << std::endl;

    int* res = new int[v_str.size()];
    const char* regex = "last";

    // nv_handle->

    // std::cout << nv_handle->len(res,false) << std::endl;

    int* d_res;
    RMM_ALLOC((void**)&d_res,sizeof(int)*v_str.size(),0);
    
    std::cout << nv_handle->len(d_res,true) << std::endl;
    cudaMemcpy(res,d_res,v_str.size() * sizeof(int),cudaMemcpyDeviceToHost);
    // nv_handle->
    for(int i = 0; i < v_str.size(); i++){
        std::cout << res[i] << std::endl;
    }

    delete[](res);
    delete[](strs);
    RMM_FREE(d_res,0);
    NVStrings::destroy(nv_handle);


    // char ** strs_c = new char*[2];
    // const char ** c_strs = strs_c;
    // auto nv_handle = NVStrings::create_from_array(const_cast<const char**>(strs_c),2);
    return 0;

}