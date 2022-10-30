cmake_minimum_required(VERSION 3.10)
project(rosettaboy-cpp)

option(ENABLE_LTO "enable LTO" OFF)

set(CMAKE_CXX_STANDARD 17)

set(CMAKE_CXX_FLAGS_RELEASE "-O3")

include_directories(/usr/local/include/)

add_executable(rosettaboy-cpp src/main.cpp src/args.cpp src/cpu.cpp src/cart.cpp src/gameboy.cpp src/gpu.cpp src/consts.h src/cart.h src/cpu.h src/gpu.h src/args.h src/apu.cpp src/apu.h src/ram.cpp src/ram.h src/buttons.cpp src/buttons.h src/clock.cpp src/clock.h)

if(ENABLE_LTO)
    # include(CheckIPOSupported)
    # check_ipo_supported(RESULT lto_supported OUTPUT lto_error)

    # if(lto_supported)
        set_property(TARGET rosettaboy-cpp PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
        target_compile_options(rosettaboy-cpp PRIVATE -flto)
        target_link_options(rosettaboy-cpp PRIVATE -flto)

        # else()
    #     message(SEND_ERROR "LTO not supported: <${lto_error}>")
    # endif()
endif()

find_package(SDL2 REQUIRED)
include_directories(${SDL2_INCLUDE_DIRS})
target_link_libraries(rosettaboy-cpp ${SDL2_LIBRARIES})
