project(my_test)
cmake_minimum_required(VERSION 3.1)

find_package(AnyDSL_runtime REQUIRED)
set(CMAKE_CXX_STANDARD 14)

add_subdirectory(src)