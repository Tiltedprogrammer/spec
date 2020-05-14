set(FUN_INCLUDE_FILE ${CMAKE_CURRENT_BINARY_DIR}/../impala/fun.inc)

find_library(PFAC_LIB pfac HINTS ${PFAC_LIB_ROOT}/lib)

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


if(BLOCK_SIZE)
    message("-- BLOCK_SIZE=${BLOCK_SIZE}")
    add_definitions(-DBLOCK_SIZE=${BLOCK_SIZE})
else()
    message("-- Using default BLOCK_SIZE which is 1024")
    add_definitions(-DBLOCK_SIZE=1024)    
endif()

anydsl_runtime_wrap(IMPALA_TEST
    FILES test.impala)

SET(JITIFY /home/alekseey_tyurin_gmail_com/specialization/jitify)
SET(JITIFY_LINK -lcuda -lcudart -lnvrtc)

add_definitions(-JITIFY_THREAD_SAFE=0)

# add_executable(match.out main.cpp utils.cpp kernels.cu)

# target_include_directories(match.out PUBLIC ${CUDA_INCLUDE_DIRS} ../include)

cuda_add_executable(MatchConst MatchConst.cpp ../impala/match_wrappers.cpp ../cpp/utils.cpp ${FUN_INCLUDE_FILE} ../cpp/kernels.cu)
target_include_directories(MatchConst PUBLIC ${CMAKE_CURRENT_BINARY_DIR}/../impala ${AnyDSL_runtime_INCLUDE_DIRS} ${CUDA_INCLUDE_DIRS} ../include ${PFAC_INCLUDE_DIR} ${JITIFY})
target_link_libraries(MatchConst ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES} ${JITIFY_LINK})

cuda_add_executable(MatchGlobal MatchGlobal.cpp ../impala/match_wrappers.cpp ../cpp/utils.cpp ${FUN_INCLUDE_FILE} ../cpp/kernels.cu)
target_include_directories(MatchGlobal PUBLIC ${CMAKE_CURRENT_BINARY_DIR}/../impala ${AnyDSL_runtime_INCLUDE_DIRS} ${CUDA_INCLUDE_DIRS} ../include ${PFAC_INCLUDE_DIR} ${JITIFY})
target_link_libraries(MatchGlobal ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES} ${JITIFY_LINK})

cuda_add_executable(MatchSpec MatchSpec.cpp ../impala/match_wrappers.cpp ../cpp/utils.cpp ${FUN_INCLUDE_FILE} ../cpp/kernels.cu)
target_include_directories(MatchSpec PUBLIC ${CMAKE_CURRENT_BINARY_DIR}/../impala ${AnyDSL_runtime_INCLUDE_DIRS} ${CUDA_INCLUDE_DIRS} ../include ${PFAC_INCLUDE_DIR} ${JITIFY})
target_link_libraries(MatchSpec ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES} ${JITIFY_LINK})

cuda_add_executable(MatchConstManual MatchConstManual.cpp ../impala/match_wrappers.cpp ../cpp/utils.cpp ${FUN_INCLUDE_FILE} ../cpp/kernels.cu)
target_include_directories(MatchConstManual PUBLIC ${CMAKE_CURRENT_BINARY_DIR}/../impala ${AnyDSL_runtime_INCLUDE_DIRS} ${CUDA_INCLUDE_DIRS} ../include ${PFAC_INCLUDE_DIR} ${JITIFY})
target_link_libraries(MatchConstManual ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES} ${JITIFY_LINK})

# target_compile_options(match.out PRIVATE $<$<COMPILE_LANGUAGE:CUDA>:-O4 -arch=sm_75>)