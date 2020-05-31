project(my_test LANGUAGES CUDA CXX)

cmake_minimum_required(VERSION 3.1)

set(DEFAULT_BUILD_TYPE "Debug")

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(STATUS "Setting build type to '${DEFAULT_BUILD_TYPE}' since none specified.")
  set(CMAKE_BUILD_TYPE "${DEFAULT_BUILD_TYPE}" CACHE
      STRING "Choose the type of build." FORCE)
  # Set the possible values of build type for cmake-gui
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Release")
endif()


find_package(AnyDSL_runtime REQUIRED)
find_package(CUDA REQUIRED)
set(CMAKE_CXX_STANDARD 17)

add_definitions(-DBENCHMARK)
add_definitions(-DITERATIONS_CMAKE=20)

add_subdirectory(matching/impala)
add_subdirectory(matching/cpp)
add_subdirectory(convolution/cpp)
add_subdirectory(convolution/impala)
add_subdirectory(aho-corasick/cpp)
add_subdirectory(regex/cpp)
#add_subdirectory(micro-bench)