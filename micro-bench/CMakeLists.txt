set(FUN_INCLUDE_FILE ${CMAKE_CURRENT_BINARY_DIR}/kernel.inc)
add_custom_command(OUTPUT ${FUN_INCLUDE_FILE} COMMAND xxd -i kernel.impala > ${FUN_INCLUDE_FILE} WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
set_source_files_properties(${FUN_INCLUDE_FILE} PROPERTIES GENERATED TRUE)


set(CLANG_FLAGS -march=native)
set(ANYDSL_RUNTIME_LIBRARIES ${AnyDSL_runtime_LIBRARIES})

anydsl_runtime_wrap(KERNEL
    CLANG_FLAGS ${CLANG_FLAGS}
    IMPALA_FLAGS ${IMPALA_FLAGS}
    FILES kernel.impala)
cuda_add_executable(kernel mini_benchmark2.cu ${KERNEL})
target_link_libraries(kernel ${ANYDSL_RUNTIME_LIBRARIES})
target_include_directories(kernel PUBLIC ${AnyDSL_runtime_INCLUDE_DIRS} ${CUDA_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR})
target_compile_options(kernel  PRIVATE $<$<COMPILE_LANGUAGE:CUDA>:-arch=sm_75 -Xptxas -v>)


add_executable(MiniBench mini_benchmark2.cu ${FUN_INCLUDE_FILE})
target_include_directories(MiniBench PUBLIC ${AnyDSL_runtime_INCLUDE_DIRS} ${CUDA_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR})
target_link_libraries(MiniBench ${AnyDSL_runtime_LIBRARIES})
target_compile_options(MiniBench  PRIVATE $<$<COMPILE_LANGUAGE:CUDA>:-arch=sm_75 -Xptxas -v>)
