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


#PFAC
if(PFAC_LIB_ROOT)
    message("PFAC_LIB_ROOT=${PFAC_LIB_ROOT}")
else()
    message(FATAL_ERROR "PFAC_LIB_ROOT should be provided to Cmake, e.g. '/home/.../PFAC/PFAC/'")
endif()


find_library(PFAC_LIB pfac HINTS ${PFAC_LIB_ROOT}/lib)

if(PFAC_LIB-NOTFOUND)
    message(FATAL ERROR "pfac library is not found")
else()
    message("pfac library is found at ${PFAC_LIB}")
endif(PFAC_LIB-NOTFOUND)

find_path(PFAC_INCLUDE_DIR
    NAMES PFAC_P.h
    PATHS ${PFAC_LIB_ROOT}/include)

if(PFAC_INCLUDE_DIR-NOTFOUND)
    message(FATAL_ERROR "pfac includes not found")
else()
    message("pfac include found at ${PFAC_INCLUDE_DIR}")
endif(PFAC_INCLUDE_DIR-NOTFOUND)


if(BLOCK_SIZE)
    message("-- BLOCK_SIZE=${BLOCK_SIZE}")
    add_definitions(-DBLOCK_SIZE=${BLOCK_SIZE})
else()
    message("-- Using default BLOCK_SIZE which is 1024")
    add_definitions(-DBLOCK_SIZE=1024)    
endif()

if(JITIFY)
    message("JITIFY=${JITIFY}")
else()
    message(FATAL_ERROR "JITIFY should be provided to Cmake")
endif()

SET(JITIFY_LINK -lcuda -lcudart -lnvrtc)

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
#add_subdirectory(regex/cpp)
#add_subdirectory(micro-bench)