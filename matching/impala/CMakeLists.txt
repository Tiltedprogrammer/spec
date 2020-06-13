set(FUN_INCLUDE_FILE ${CMAKE_CURRENT_BINARY_DIR}/fun.inc)
add_custom_command(OUTPUT ${FUN_INCLUDE_FILE} COMMAND xxd -i fun.impala ${FUN_INCLUDE_FILE} WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
set_source_files_properties(${FUN_INCLUDE_FILE} PROPERTIES GENERATED TRUE)



anydsl_runtime_wrap(NON_JIT_MATCH
    FILES non_jit.impala)

add_definitions(-JITIFY_THREAD_SAFE=0)

cuda_add_executable(TestSpec test.cpp match_wrappers.cpp ../cpp/utils.cpp ${FUN_INCLUDE_FILE} ../cpp/kernels.cu)
target_include_directories(TestSpec PUBLIC ${CMAKE_CURRENT_BINARY_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CUDA_INCLUDE_DIRS} ../include ${PFAC_INCLUDE_DIR} ${JITIFY})
target_link_libraries(TestSpec ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES} ${JITIFY_LINK})
target_compile_options(TestSpec PRIVATE $<$<COMPILE_LANGUAGE:CUDA>: -O3>) 


cuda_add_executable(TestSpec2 test_simple.cpp match_wrappers.cpp ../cpp/utils.cpp ${FUN_INCLUDE_FILE} ../cpp/kernels.cu)
target_include_directories(TestSpec2 PUBLIC ${CMAKE_CURRENT_BINARY_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CUDA_INCLUDE_DIRS} ../include ${PFAC_INCLUDE_DIR} ${JITIFY})
target_link_libraries(TestSpec2 ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES} ${JITIFY_LINK})
target_compile_options(TestSpec2 PRIVATE $<$<COMPILE_LANGUAGE:CUDA>: -O3>) 
