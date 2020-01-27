# find_package(CUDA REQUIRED)
#include_directories(${CUDA_INCLUDE_DIRS})

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2")

add_executable(filter.out main.cpp convolutionSeparable.cu convolutionSeparable.hpp convolutionSeparable_gold.cpp convolutionSeparable_gold.hpp)

link_directories(/usr/X11R6/lib)
target_link_libraries(filter.out m pthread jpeg X11)
target_include_directories(filter.out PUBLIC ${CUDA_INCLUDE_DIRS})