set(FUN_INCLUDE_FILE ${CMAKE_CURRENT_BINARY_DIR}/fun.inc)
add_custom_command(OUTPUT ${FUN_INCLUDE_FILE} COMMAND xxd -i fun.impala > ${FUN_INCLUDE_FILE} WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
set_source_files_properties(${FUN_INCLUDE_FILE} PROPERTIES GENERATED TRUE)

anydsl_runtime_wrap(NON_JIT_MATCH
    FILES non_jit.impala)

if(BLOCK_SIZE)
    message("-- BLOCK_SIZE=${BLOCK_SIZE}")
    add_definitions(-DBLOCK_SIZE=${BLOCK_SIZE})
else()
    message("-- Using default BLOCK_SIZE which is 1024")
    add_definitions(-DBLOCK_SIZE=1024)    
endif()

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

SET(JITIFY /home/alekseey_tyurin_gmail_com/specialization/jitify)
SET(JITIFY_LINK -lcuda -lcudart -lnvrtc)
#test
add_definitions(-JITIFY_THREAD_SAFE=0)


# cuda_add_executable(match_spec.out main_spec.cpp match_wrappers.cpp ../cpp/utils.cpp ${FUN_INCLUDE_FILE} ${NON_JIT_MATCH})
# # add_executable(clean.out test.cu)
# target_include_directories(match_spec.out PUBLIC ${CMAKE_CURRENT_BINARY_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CUDA_INCLUDE_DIRS} ../include)
# target_link_libraries(match_spec.out ${AnyDSL_runtime_LIBRARIES})

cuda_add_executable(TestSpec test.cpp match_wrappers.cpp ../cpp/utils.cpp ${FUN_INCLUDE_FILE} ../cpp/kernels.cu)
target_include_directories(TestSpec PUBLIC ${CMAKE_CURRENT_BINARY_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CUDA_INCLUDE_DIRS} ../include ${PFAC_INCLUDE_DIR} ${JITIFY})
target_link_libraries(TestSpec ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES} ${JITIFY_LINK})
target_compile_options(TestSpec  PRIVATE $<$<COMPILE_LANGUAGE:CUDA>:-Xptxas -v>)

cuda_add_executable(TestSpec2 test_simple.cpp match_wrappers.cpp ../cpp/utils.cpp ${FUN_INCLUDE_FILE} ../cpp/kernels.cu)
target_include_directories(TestSpec2 PUBLIC ${CMAKE_CURRENT_BINARY_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CUDA_INCLUDE_DIRS} ../include ${PFAC_INCLUDE_DIR} ${JITIFY})
target_link_libraries(TestSpec2 ${PFAC_LIB} ${AnyDSL_runtime_LIBRARIES} ${JITIFY_LINK})
target_compile_options(TestSpec2  PRIVATE $<$<COMPILE_LANGUAGE:CUDA>:-Xptxas -v>)
