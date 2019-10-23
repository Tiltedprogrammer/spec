set(FUN_INCLUDE_FILE ${CMAKE_CURRENT_BINARY_DIR}/fun.inc)
add_custom_command(OUTPUT ${FUN_INCLUDE_FILE} COMMAND xxd -i fun.impala > ${FUN_INCLUDE_FILE} WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
set_source_files_properties(${FUN_INCLUDE_FILE} PROPERTIES GENERATED TRUE)

anydsl_runtime_wrap(NON_JIT_MATCH
    FILES non_jit.impala)

add_executable(fun main.cu ${FUN_INCLUDE_FILE} ${NON_JIT_MATCH})
target_include_directories(fun PUBLIC ${CMAKE_CURRENT_BINARY_DIR} ${AnyDSL_runtime_INCLUDE_DIRS})
target_link_libraries(fun ${AnyDSL_runtime_LIBRARIES})
