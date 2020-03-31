# find_package(CUDA REQUIRED)
#include_directories(${CUDA_INCLUDE_DIRS})

set(FUN_INCLUDE_FILE ${CMAKE_CURRENT_BINARY_DIR}/convolutionSeparable.inc)
add_custom_command(OUTPUT ${FUN_INCLUDE_FILE} COMMAND xxd -i convolutionSeparable.impala > ${FUN_INCLUDE_FILE} WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
set_source_files_properties(${FUN_INCLUDE_FILE} PROPERTIES GENERATED TRUE)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2")

cuda_add_executable(filter_spec.out mainImpala.cpp ../cpp/convolutionSeparable_gold.cpp ../cpp/convolutionSeparable_gold.hpp ${FUN_INCLUDE_FILE})

link_directories(/usr/X11R6/lib)
target_include_directories(filter_spec.out PUBLIC ${CMAKE_CURRENT_BINARY_DIR} ${AnyDSL_runtime_INCLUDE_DIRS})
target_link_libraries(filter_spec.out m pthread jpeg X11 ${AnyDSL_runtime_LIBRARIES})
# target_include_directories(filter_spec.out PUBLIC ${CMAKE_CURRENT_BINARY_DIR} ${AnyDSL_runtime_INCLUDE_DIRS} ${CUDA_INCLUDE_DIRS})
