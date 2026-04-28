cmake_minimum_required(VERSION 3.15.1)

project(qwen3-rerank-demo)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wl,--allow-shlib-undefined")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -Wl,--allow-shlib-undefined")

if(${CMAKE_VERSION} VERSION_GREATER "3.15.0" AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
  add_link_options("-Wl,-Bsymbolic")
endif()

if (CMAKE_SYSTEM_NAME STREQUAL "Android")
    set (TARGET_LIB_ARCH ${CMAKE_ANDROID_ARCH_ABI})
else()
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set (TARGET_LIB_ARCH aarch64)
    else()
        set (TARGET_LIB_ARCH armhf)
    endif()
    if (CMAKE_C_COMPILER MATCHES "uclibc")
        set (TARGET_LIB_ARCH ${TARGET_LIB_ARCH}_uclibc)
    endif()
endif()

set(RKLLM_PATH ${CMAKE_CURRENT_SOURCE_DIR})
set(LIBRKLLMRT ${RKLLM_PATH}/lib/${TARGET_LIB_ARCH}/librkllmrt.so)
set(LIBRKLLMRT_INCLUDES ${RKLLM_PATH}/include)

find_package(OpenMP REQUIRED)

include_directories(${LIBRKLLMRT_INCLUDES})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src)

add_executable(demo src/main.cpp)
if(CMAKE_SYSTEM_NAME STREQUAL "Android")
  target_link_libraries(demo PRIVATE ${LIBRKLLMRT} log)
else()
  target_link_libraries(demo PRIVATE ${LIBRKLLMRT})
endif()

set_target_properties(demo PROPERTIES LINK_FLAGS -Wl,--no-undefined,--version-script,${CMAKE_SOURCE_DIR}/c_export.map)

set(CMAKE_INSTALL_PREFIX ${CMAKE_SOURCE_DIR}/install/demo_${CMAKE_SYSTEM_NAME}_${TARGET_LIB_ARCH})
install(TARGETS demo DESTINATION ./)
install(PROGRAMS ${LIBRKLLMRT} DESTINATION lib)
install(FILES ${CMAKE_SOURCE_DIR}/scripts/run.sh DESTINATION .)
install(PROGRAMS ${CMAKE_SOURCE_DIR}/scripts/test_single.sh DESTINATION .)
install(PROGRAMS ${CMAKE_SOURCE_DIR}/scripts/test_batch.sh DESTINATION .)
install(FILES ${CMAKE_SOURCE_DIR}/test/documents.txt DESTINATION test)
install(DIRECTORY DESTINATION models)
