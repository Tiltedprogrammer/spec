project(my_test LANGUAGES CUDA CXX)
cmake_minimum_required(VERSION 3.1)

find_package(AnyDSL_runtime REQUIRED)
find_package(CUDA REQUIRED)
set(CMAKE_CXX_STANDARD 17)

add_subdirectory(matching)
add_subdirectory(convolution/cpp)
add_subdirectory(convolution/impala)
add_subdirectory(aho-corasick/cpp)