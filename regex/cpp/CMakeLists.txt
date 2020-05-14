if(RMM_LIB_ROOT)
    message("RMM_LIB_ROOT=${RMM_LIB_ROOT} rmm root $ENV{RMM_ROOT}")
else()
    message(FATAL_ERROR "RMM_LIB_ROOT should be provided to Cmake, e.g. '/home/.../PFAC/PFAC/'")
endif()

find_library(RMM_LIB rmm HINTS ${RMM_LIB_ROOT}/lib)

if(RMM_LIB-NOTFOUND)
    message(FATAL ERROR "rmm library is not found")
else()
    message("rmm library is found at ${RMM_LIB}")
endif(RMM_LIB-NOTFOUND)

if(NVSTRINGS_LIB_ROOT)
    message("NVSTRINGS_LIB_ROOT=${NVSTRINGS_LIB_ROOT}")
else()
    message(FATAL_ERROR "NVSTRINGS_LIB_ROOT should be provided to Cmake, e.g. '/home/.../PFAC/PFAC/'")
endif()

find_library(NVSTRINGS_LIB NVStrings HINTS ${NVSTRINGS_LIB_ROOT})

if(NVSTRINGS_LIB-NOTFOUND)
    message(FATAL ERROR "NVSTRINGS_LIB_ROOT library is not found")
else()
    message("NVSTRINGS_LIB library is found at ${NVSTRINGS_LIB}")
endif()


add_executable(test test.cpp)

target_include_directories(test PUBLIC $ENV{RMM_ROOT}/include ${CUDA_INCLUDE_DIRS} /home/alekseey_tyurin_gmail_com/specialization/custrings/cpp/include)

# target_include_directories(simple.out )
# set(PFAC_LIB_ROOT "/home/bolkonskiy322_gmail_com/PFAC/PFAC/include")
# find_path(RMM_INCLUDE_DIR
#     NAMES PFAC_P.h
#     PATHS ${PFAC_LIB_ROOT}/include)

# if(PFAC_INCLUDE_DIR-NOTFOUND)
#     message(FATAL_ERROR "pfac includes not found")
# else()
#     message("pfac include found at ${PFAC_INCLUDE_DIR}")
# endif(PFAC_INCLUDE_DIR-NOTFOUND)