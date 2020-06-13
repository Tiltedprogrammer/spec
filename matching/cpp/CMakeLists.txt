
set(FUN_INCLUDE_FILE ${CMAKE_CURRENT_BINARY_DIR}/fun.inc)
add_custom_command(OUTPUT ${FUN_INCLUDE_FILE} COMMAND xxd -i ../impala/fun.impala ${FUN_INCLUDE_FILE} WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
set_source_files_properties(${FUN_INCLUDE_FILE} PROPERTIES GENERATED TRUE)



anydsl_runtime_wrap(IMPALA_TEST
    FILES test.impala)

add_definitions(-JITIFY_THREAD_SAFE=0)

cuda_add_executable(MatchConst MatchConst.cpp ../impala/match_wrappers.cpp ../cpp/utils.cpp ${FUN_INCLUDE_FILE} ../cpp/kernels.cu)
target_include_directories(MatchConst PUBLIC ${CMAKE_CURRENT_BINARY_DIR}/../impala ${AnyDSL_runtime_INCLUDE_DIRS} ${CUDA_INCLUDE_DIRS} ../include ${PFAC_INCLUDE_DIR} ${JITIFY})
target_link_libraries(MatchConst ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES} ${JITIFY_LINK})
target_compile_options(MatchConst PRIVATE $<$<COMPILE_LANGUAGE:CUDA>: -O3>) 



cuda_add_executable(MatchGlobal MatchGlobal.cpp ../impala/match_wrappers.cpp ../cpp/utils.cpp ${FUN_INCLUDE_FILE} ../cpp/kernels.cu)
target_include_directories(MatchGlobal PUBLIC ${CMAKE_CURRENT_BINARY_DIR}/../impala ${AnyDSL_runtime_INCLUDE_DIRS} ${CUDA_INCLUDE_DIRS} ../include ${PFAC_INCLUDE_DIR} ${JITIFY})
target_link_libraries(MatchGlobal ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES} ${JITIFY_LINK})
target_compile_options(MatchGlobal PRIVATE $<$<COMPILE_LANGUAGE:CUDA>: -O3>) 



cuda_add_executable(MatchSpec MatchSpec.cpp ../impala/match_wrappers.cpp ../cpp/utils.cpp ${FUN_INCLUDE_FILE} ../cpp/kernels.cu)
target_include_directories(MatchSpec PUBLIC ${CMAKE_CURRENT_BINARY_DIR}/../impala ${AnyDSL_runtime_INCLUDE_DIRS} ${CUDA_INCLUDE_DIRS} ../include ${PFAC_INCLUDE_DIR} ${JITIFY})
target_link_libraries(MatchSpec ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES} ${JITIFY_LINK})
target_compile_options(MatchSpec PRIVATE $<$<COMPILE_LANGUAGE:CUDA>: -O3>) 


cuda_add_executable(MatchConstManual MatchConstManual.cpp ../impala/match_wrappers.cpp ../cpp/utils.cpp ${FUN_INCLUDE_FILE} ../cpp/kernels.cu)
target_include_directories(MatchConstManual PUBLIC ${CMAKE_CURRENT_BINARY_DIR}/../impala ${AnyDSL_runtime_INCLUDE_DIRS} ${CUDA_INCLUDE_DIRS} ../include ${PFAC_INCLUDE_DIR} ${JITIFY})
target_link_libraries(MatchConstManual ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES} ${JITIFY_LINK})
target_compile_options(MatchConstManual PRIVATE $<$<COMPILE_LANGUAGE:CUDA>: -O3>) 



cuda_add_executable(MatchSingleBench MatchSingleBench.cpp ../impala/match_wrappers.cpp ../cpp/utils.cpp ${FUN_INCLUDE_FILE} ../cpp/kernels.cu)
target_include_directories(MatchSingleBench PUBLIC ${CMAKE_CURRENT_BINARY_DIR}/../impala ${AnyDSL_runtime_INCLUDE_DIRS} ${CUDA_INCLUDE_DIRS} ../include ${PFAC_INCLUDE_DIR} ${JITIFY})
target_link_libraries(MatchSingleBench ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES} ${JITIFY_LINK})
target_compile_options(MatchSingleBench PRIVATE $<$<COMPILE_LANGUAGE:CUDA>: -O3>) 
