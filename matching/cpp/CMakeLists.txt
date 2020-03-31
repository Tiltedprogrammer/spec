if(BLOCK_SIZE)
    message("-- BLOCK_SIZE=${BLOCK_SIZE}")
    add_definitions(-DBLOCK_SIZE=${BLOCK_SIZE})
else()
    message("-- Using default BLOCK_SIZE which is 1024")
    add_definitions(-DBLOCK_SIZE=1024)    
endif()

anydsl_runtime_wrap(IMPALA_TEST
    FILES test.impala)

add_executable(test.out test.cpp ${IMPALA_TEST})

add_executable(match.out main.cpp utils.cpp kernels.cu)

target_include_directories(match.out PUBLIC ${CUDA_INCLUDE_DIRS} ../include)

# target_compile_options(match.out PRIVATE $<$<COMPILE_LANGUAGE:CUDA>:-O4 -arch=sm_75>)