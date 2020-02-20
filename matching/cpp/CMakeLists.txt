if(BLOCK_SIZE)
    message("-- BLOCK_SIZE=${BLOCK_SIZE}")
    add_definitions(-DBLOCK_SIZE=${BLOCK_SIZE})
else()
    message("-- Using default BLOCK_SIZE which is 1024")
    add_definitions(-DBLOCK_SIZE=1024)    
endif()


add_executable(match.out main.cu)