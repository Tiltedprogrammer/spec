find_package(CUDA REQUIRED)
include_directories(${CUDA_INCLUDE_DIRS})

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2")

add_executable(hello.out main.cpp cpp/convolutionSeparable.cu cpp/convolutionSeparable.hpp cpp/convolutionSeparable_gold.cpp cpp/convolutionSeparable_gold.hpp)

link_directories(/usr/X11R6/lib)
target_link_libraries(hello.out m pthread jpeg X11)
