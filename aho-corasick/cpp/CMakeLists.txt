anydsl_runtime_wrap(IMPALA_TEST
    FILES test.impala)

set(FUN_INCLUDE_FILE ${CMAKE_CURRENT_BINARY_DIR}/spec_match.inc)

add_custom_command(OUTPUT ${FUN_INCLUDE_FILE} COMMAND xxd -i ../impala/spec_match.impala > ${FUN_INCLUDE_FILE} WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
set_source_files_properties(${FUN_INCLUDE_FILE} PROPERTIES GENERATED TRUE)

SET(SPEC_KERNELS spec-kernels/ImpalaNaiveCuda.cu spec-kernels/ImpalaNaiveOpt.cu spec-kernels/ImpalaCorasickCuda.cu spec-kernels/CudaNaiveOpt.cu spec-kernels/CudaSpecManualOpt.cu spec-kernels/CudaSpecManualOptNU.cu spec-kernels/CudaSpecManualOptNUBW.cu spec-kernels/CudaCorasickSpec.cu)

#test

cuda_add_executable(RunTest test.cpp
                         spec_match.cpp
                         ../../matching/impala/match_wrappers.cpp 
                         ../../matching/cpp/utils.cpp 
                         ../../matching/cpp/kernels.cu 
                         ${SPEC_KERNELS}
                         ${FUN_INCLUDE_FILE})

target_link_libraries(RunTest ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES} ${JITIFY_LINK})
target_include_directories(RunTest PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} spec-kernels/ ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala ${JITIFY})
target_compile_options(RunTest PRIVATE $<$<COMPILE_LANGUAGE:CUDA>:-pthread -O3>)



# Impala naive

cuda_add_executable(ImpalaNaive
                    ImpalaNaive.cpp 
                    spec_match.cpp 
                    ../../matching/impala/match_wrappers.cpp 
                    ../../matching/cpp/utils.cpp 
                    ../../matching/cpp/kernels.cu
                    ${SPEC_KERNELS}
                    ${FUN_INCLUDE_FILE})

target_link_libraries(ImpalaNaive ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES} ${JITIFY_LINK})
target_include_directories(ImpalaNaive PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala ${JITIFY})
target_compile_options(ImpalaNaive PRIVATE $<$<COMPILE_LANGUAGE:CUDA>: -O3>) 


# Impala naive opt
cuda_add_executable(ImpalaNaiveOpt 
                    ImpalaNaiveOpt.cpp 
                    spec_match.cpp 
                    ../../matching/impala/match_wrappers.cpp 
                    ../../matching/cpp/utils.cpp 
                    ../../matching/cpp/kernels.cu
                    ${SPEC_KERNELS} 
                    ${FUN_INCLUDE_FILE})

target_link_libraries(ImpalaNaiveOpt ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES} ${JITIFY_LINK})
target_include_directories(ImpalaNaiveOpt PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala ${JITIFY})
target_compile_options(ImpalaNaiveOpt PRIVATE $<$<COMPILE_LANGUAGE:CUDA>: -O3>) 


# Pfac gloabal
cuda_add_executable(PfacGlobal 
                    PfacGlobal.cpp 
                    spec_match.cpp 
                    ../../matching/impala/match_wrappers.cpp 
                    ../../matching/cpp/utils.cpp 
                    ../../matching/cpp/kernels.cu
                    ${SPEC_KERNELS} 
                    ${FUN_INCLUDE_FILE})

target_link_libraries(PfacGlobal ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES} ${JITIFY_LINK})
target_include_directories(PfacGlobal PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala ${JITIFY})
target_compile_options(PfacGlobal PRIVATE $<$<COMPILE_LANGUAGE:CUDA>: -O3>) 


# Impala corasick

cuda_add_executable(ImpalaCorasick 
                    ImpalaCorasick.cpp 
                    spec_match.cpp 
                    ../../matching/impala/match_wrappers.cpp 
                    ../../matching/cpp/utils.cpp 
                    ../../matching/cpp/kernels.cu
                    ${SPEC_KERNELS}
                    ${FUN_INCLUDE_FILE})

target_link_libraries(ImpalaCorasick ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES} ${JITIFY_LINK})
target_include_directories(ImpalaCorasick PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala ${JITIFY})
target_compile_options(ImpalaCorasick PRIVATE $<$<COMPILE_LANGUAGE:CUDA>: -O3>) 


cuda_add_executable(CudaNaiveOpt 
                    CudaNaiveOpt.cpp 
                    spec_match.cpp 
                    ../../matching/impala/match_wrappers.cpp 
                    ../../matching/cpp/utils.cpp 
                    ../../matching/cpp/kernels.cu
                    ${SPEC_KERNELS}
                    ${FUN_INCLUDE_FILE})

target_link_libraries(CudaNaiveOpt ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES} ${JITIFY_LINK})
target_include_directories(CudaNaiveOpt PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala ${JITIFY})
target_compile_options(CudaNaiveOpt PRIVATE $<$<COMPILE_LANGUAGE:CUDA>: -O3>) 


cuda_add_executable(CudaNaiveOptSpec 
                    CudaSpecManual.cpp 
                    spec_match.cpp 
                    ../../matching/impala/match_wrappers.cpp 
                    ../../matching/cpp/utils.cpp 
                    ../../matching/cpp/kernels.cu
                    ${SPEC_KERNELS}
                    ${FUN_INCLUDE_FILE})

target_link_libraries(CudaNaiveOptSpec ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES} ${JITIFY_LINK})
target_include_directories(CudaNaiveOptSpec PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala ${JITIFY})
target_compile_options(CudaNaiveOptSpec PRIVATE $<$<COMPILE_LANGUAGE:CUDA>: -O3>) 



cuda_add_executable(CudaNaiveOptSpecNU 
                    CudaSpecManualNU.cpp 
                    spec_match.cpp 
                    ../../matching/impala/match_wrappers.cpp 
                    ../../matching/cpp/utils.cpp 
                    ../../matching/cpp/kernels.cu
                    ${SPEC_KERNELS}
                    ${FUN_INCLUDE_FILE})

target_link_libraries(CudaNaiveOptSpecNU ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES} ${JITIFY_LINK})
target_include_directories(CudaNaiveOptSpecNU PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala ${JITIFY})
target_compile_options(CudaNaiveOptSpecNU PRIVATE $<$<COMPILE_LANGUAGE:CUDA>: -O3>) 



cuda_add_executable(CudaNaiveOptSpecNUBW 
                    CudaSpecManualNUBW.cpp 
                    spec_match.cpp 
                    ../../matching/impala/match_wrappers.cpp 
                    ../../matching/cpp/utils.cpp 
                    ../../matching/cpp/kernels.cu
                    ${SPEC_KERNELS}
                    ${FUN_INCLUDE_FILE})

target_link_libraries(CudaNaiveOptSpecNUBW ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES} ${JITIFY_LINK})
target_include_directories(CudaNaiveOptSpecNUBW PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala ${JITIFY})
target_compile_options(CudaNaiveOptSpecNUBW PRIVATE $<$<COMPILE_LANGUAGE:CUDA>: -O3>) 



cuda_add_executable(CudaCorasickSpec 
                    CudaCorasickSpec.cpp 
                    spec_match.cpp 
                    ../../matching/impala/match_wrappers.cpp 
                    ../../matching/cpp/utils.cpp 
                    ../../matching/cpp/kernels.cu
                    ${SPEC_KERNELS}
                    ${FUN_INCLUDE_FILE})

target_link_libraries(CudaCorasickSpec ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES} ${JITIFY_LINK})
target_include_directories(CudaCorasickSpec PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala ${JITIFY})
target_compile_options(CudaCorasickSpec PRIVATE $<$<COMPILE_LANGUAGE:CUDA>:-pthread -O3>)