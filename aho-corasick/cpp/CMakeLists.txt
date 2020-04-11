# pass the path via cmake parameter
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

# target_include_directories(simple.out )
# set(PFAC_LIB_ROOT "/home/bolkonskiy322_gmail_com/PFAC/PFAC/include")
find_path(PFAC_INCLUDE_DIR
    NAMES PFAC_P.h
    PATHS ${PFAC_LIB_ROOT}/include)

if(PFAC_INCLUDE_DIR-NOTFOUND)
    message(FATAL_ERROR "pfac includes not found")
else()
    message("pfac include found at ${PFAC_INCLUDE_DIR}")
endif(PFAC_INCLUDE_DIR-NOTFOUND)
# link_directories(/home/alekseytyurinspb_gmail_com/PFAC/PFAC-master/PFAC/lib)

anydsl_runtime_wrap(IMPALA_TEST
    FILES test.impala)

set(FUN_INCLUDE_FILE ${CMAKE_CURRENT_BINARY_DIR}/spec_match.inc)

add_custom_command(OUTPUT ${FUN_INCLUDE_FILE} COMMAND xxd -i ../impala/spec_match.impala > ${FUN_INCLUDE_FILE} WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
set_source_files_properties(${FUN_INCLUDE_FILE} PROPERTIES GENERATED TRUE)


if(BLOCK_SIZE)
    message("-- BLOCK_SIZE=${BLOCK_SIZE}")
    add_definitions(-DBLOCK_SIZE=${BLOCK_SIZE})
else()
    message("-- Using default BLOCK_SIZE which is 1024")
    add_definitions(-DBLOCK_SIZE=1024)    
endif()

# cuda_add_executable(simple.out main.cpp spec_match.cpp ${FUN_INCLUDE_FILE})
# cuda_add_executable(simple-impala.out main.cpp spec_match.cpp ${FUN_INCLUDE_FILE})

# add_executable(test.out main.cpp ${IMPALA_TEST})

SET(SPEC_KERNELS spec-kernels/ImpalaNaiveCuda.cu spec-kernels/ImpalaNaiveOpt.cu spec-kernels/ImpalaCorasickCuda.cu spec-kernels/CudaNaiveOpt.cu spec-kernels/CudaSpecManualOpt.cu spec-kernels/CudaSpecManualOptNU.cu spec-kernels/CudaSpecManualOptNUBW.cu spec-kernels/CudaCorasickSpec.cu)


#test
# add_definitions(-DBENCHMARK)
cuda_add_executable(RunTest test.cpp
                         spec_match.cpp
                         ../../matching/impala/match_wrappers.cpp 
                         ../../matching/cpp/utils.cpp 
                         ../../matching/cpp/kernels.cu 
                         ${SPEC_KERNELS}
                         ${FUN_INCLUDE_FILE})

target_link_libraries(RunTest ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES})
target_include_directories(RunTest PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} spec-kernels/ ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala)

# #benchmark NaiveImpalaVsPfac
# cuda_add_executable(PfacVsImpalaNaive NaiveImpalaVsPfac.cpp spec_match.cpp ../../matching/impala/match_wrappers.cpp ../../matching/cpp/utils.cpp ../../matching/cpp/kernels.cu ${FUN_INCLUDE_FILE})

# target_link_libraries(PfacVsImpalaNaive ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES})
# target_include_directories(PfacVsImpalaNaive PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala)

# target_compile_options(PfacVsImpalaNaive PRIVATE $<$<COMPILE_LANGUAGE:CUDA>:-O4 -arch=sm_75>)

# #benchmark ImpalaGlobalVsPfac
# cuda_add_executable(ImpalaGlobalVsPfac ImpalaCorasickGlobalVsPfac.cpp spec_match.cpp ../../matching/impala/match_wrappers.cpp ../../matching/cpp/utils.cpp ../../matching/cpp/kernels.cu ${FUN_INCLUDE_FILE})

# target_link_libraries(ImpalaGlobalVsPfac ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES})
# target_include_directories(ImpalaGlobalVsPfac PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala)


# cuda_add_executable(ImpalaNaiveOptimizedVsPfac ImpalaNaiveOptimizedVsPfac.cpp spec_match.cpp ../../matching/impala/match_wrappers.cpp ../../matching/cpp/utils.cpp ../../matching/cpp/kernels.cu ${FUN_INCLUDE_FILE})

# target_link_libraries(ImpalaNaiveOptimizedVsPfac ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES})
# target_include_directories(ImpalaNaiveOptimizedVsPfac PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala)


# cuda_add_executable(ImpalaCorasickVsPfac ImpalaCorasickVsPfac.cpp spec_match.cpp ../../matching/impala/match_wrappers.cpp ../../matching/cpp/utils.cpp ../../matching/cpp/kernels.cu ${FUN_INCLUDE_FILE})

# target_link_libraries(ImpalaCorasickVsPfac ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES})
# target_include_directories(ImpalaCorasickVsPfac PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala)


# Impala naive

cuda_add_executable(ImpalaNaive
                    ImpalaNaive.cpp 
                    spec_match.cpp 
                    ../../matching/impala/match_wrappers.cpp 
                    ../../matching/cpp/utils.cpp 
                    ../../matching/cpp/kernels.cu
                    ${SPEC_KERNELS}
                    ${FUN_INCLUDE_FILE})

target_link_libraries(ImpalaNaive ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES})
target_include_directories(ImpalaNaive PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala)

# Impala naive opt
cuda_add_executable(ImpalaNaiveOpt 
                    ImpalaNaiveOpt.cpp 
                    spec_match.cpp 
                    ../../matching/impala/match_wrappers.cpp 
                    ../../matching/cpp/utils.cpp 
                    ../../matching/cpp/kernels.cu
                    ${SPEC_KERNELS} 
                    ${FUN_INCLUDE_FILE})

target_link_libraries(ImpalaNaiveOpt ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES})
target_include_directories(ImpalaNaiveOpt PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala)

# Pfac gloabal
cuda_add_executable(PfacGlobal 
                    PfacGlobal.cpp 
                    spec_match.cpp 
                    ../../matching/impala/match_wrappers.cpp 
                    ../../matching/cpp/utils.cpp 
                    ../../matching/cpp/kernels.cu
                    ${SPEC_KERNELS} 
                    ${FUN_INCLUDE_FILE})

target_link_libraries(PfacGlobal ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES})
target_include_directories(PfacGlobal PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala)

# Impala corasick

cuda_add_executable(ImpalaCorasick 
                    ImpalaCorasick.cpp 
                    spec_match.cpp 
                    ../../matching/impala/match_wrappers.cpp 
                    ../../matching/cpp/utils.cpp 
                    ../../matching/cpp/kernels.cu
                    ${SPEC_KERNELS}
                    ${FUN_INCLUDE_FILE})

target_link_libraries(ImpalaCorasick ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES})
target_include_directories(ImpalaCorasick PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala)


cuda_add_executable(CudaNaiveOpt 
                    CudaNaiveOpt.cpp 
                    spec_match.cpp 
                    ../../matching/impala/match_wrappers.cpp 
                    ../../matching/cpp/utils.cpp 
                    ../../matching/cpp/kernels.cu
                    ${SPEC_KERNELS}
                    ${FUN_INCLUDE_FILE})

target_link_libraries(CudaNaiveOpt ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES})
target_include_directories(CudaNaiveOpt PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala)


cuda_add_executable(CudaNaiveOptSpec 
                    CudaSpecManual.cpp 
                    spec_match.cpp 
                    ../../matching/impala/match_wrappers.cpp 
                    ../../matching/cpp/utils.cpp 
                    ../../matching/cpp/kernels.cu
                    ${SPEC_KERNELS}
                    ${FUN_INCLUDE_FILE})

target_link_libraries(CudaNaiveOptSpec ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES})
target_include_directories(CudaNaiveOptSpec PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala)

cuda_add_executable(CudaNaiveOptSpecNU 
                    CudaSpecManualNU.cpp 
                    spec_match.cpp 
                    ../../matching/impala/match_wrappers.cpp 
                    ../../matching/cpp/utils.cpp 
                    ../../matching/cpp/kernels.cu
                    ${SPEC_KERNELS}
                    ${FUN_INCLUDE_FILE})

target_link_libraries(CudaNaiveOptSpecNU ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES})
target_include_directories(CudaNaiveOptSpecNU PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala)

cuda_add_executable(CudaNaiveOptSpecNUBW 
                    CudaSpecManualNUBW.cpp 
                    spec_match.cpp 
                    ../../matching/impala/match_wrappers.cpp 
                    ../../matching/cpp/utils.cpp 
                    ../../matching/cpp/kernels.cu
                    ${SPEC_KERNELS}
                    ${FUN_INCLUDE_FILE})

target_link_libraries(CudaNaiveOptSpecNUBW ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES})
target_include_directories(CudaNaiveOptSpecNUBW PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala)

cuda_add_executable(CudaCorasickSpec 
                    CudaCorasickSpec.cpp 
                    spec_match.cpp 
                    ../../matching/impala/match_wrappers.cpp 
                    ../../matching/cpp/utils.cpp 
                    ../../matching/cpp/kernels.cu
                    ${SPEC_KERNELS}
                    ${FUN_INCLUDE_FILE})

target_link_libraries(CudaCorasickSpec ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES})
target_include_directories(CudaCorasickSpec PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR} ../../matching/include ${CMAKE_CURRENT_BINARY_DIR}/../../matching/impala)




# # target_link_libraries(simple.out ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES})
# # target_include_directories(simple.out PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR})

# # target_link_libraries(simple-impala.out ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES})
# # target_include_directories(simple-impala.out PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_INCLUDE_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR})


# execute_process(COMMAND cp ${CMAKE_CURRENT_BINARY_DIR}/simple.out ${CMAKE_CURRENT_SOURCE_DIR}/../benchmarking/)

# target_include_directories(test.out PUBLIC ${AnyDSL_runtime_INCLUDE_DIRS})
# target_link_libraries(test.out ${AnyDSL_runtime_LIBRARIES})
