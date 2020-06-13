add_executable(filter.out main.cpp
                          convolutionSeparable255.cu 
                          convolutionSeparable127.cu 
                          convolutionSeparable63.cu 
                          convolutionSeparable31.cu 
                          convolutionSeparable15.cu  
                          convolutionSeparable.cu 
                          convolutionSeparable_gold.cpp)

target_include_directories(filter.out PUBLIC ${CUDA_INCLUDE_DIRS} ${CMAKE_CURRENT_SOURCE_DIR}/../include)
