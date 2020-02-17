# pass the path via cmake parameter
find_library(PFAC_LIB pfac HINTS /home/alekseytyurinspb_gmail_com/PFAC/PFAC-master/PFAC/lib)

# target_include_directories(simple.out )
set(PFAC_LIB_ROOT "/home/alekseytyurinspb_gmail_com/PFAC/PFAC-master/PFAC/include")
message("-- PFAC=${PFAC_LIB_ROOT}")
# link_directories(/home/alekseytyurinspb_gmail_com/PFAC/PFAC-master/PFAC/lib)

add_executable(simple.out simple_example.cpp)

target_link_libraries(simple.out ${PFAC_LIB})
target_include_directories(simple.out PUBLIC ${CUDA_INCLUDE_DIRS} ${PFAC_LIB_ROOT})

