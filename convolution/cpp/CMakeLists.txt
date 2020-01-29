# find_package(CUDA REQUIRED)
#include_directories(${CUDA_INCLUDE_DIRS})

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2")

add_executable(filter.out main.cpp
                          convolutionSeparable255.cu 
                          convolutionSeparable255.hpp
                          convolutionSeparable127.cu 
                          convolutionSeparable127.hpp
                          convolutionSeparable63.cu 
                          convolutionSeparable63.hpp
                          convolutionSeparable31.cu 
                          convolutionSeparable31.hpp
                          convolutionSeparable15.cu 
                          convolutionSeparable15.hpp 
                          convolutionSeparable.cu 
                          convolutionSeparable.hpp
                          convolutionSeparable_gold.cpp 
                          convolutionSeparable_gold.hpp defines.hpp)

link_directories(/usr/X11R6/lib)
target_link_libraries(filter.out m pthread jpeg X11)
target_include_directories(filter.out PUBLIC ${CUDA_INCLUDE_DIRS})