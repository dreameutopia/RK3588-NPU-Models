cmake_minimum_required(VERSION 3.15.1)

project(qwen3-vl-demo)

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

if (CMAKE_SYSTEM_NAME MATCHES "Linux")
  set(OpenCV_DIR ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/opencv/opencv-linux-${TARGET_LIB_ARCH}/share/OpenCV)
elseif(CMAKE_SYSTEM_NAME MATCHES "Android")
  set(OpenCV_DIR ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/opencv/OpenCV-android-sdk/sdk/native/jni/abi-${CMAKE_ANDROID_ARCH_ABI})
endif()
find_package(OpenCV REQUIRED)

set(RKNN_PATH ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/librknnrt)
set(LIBRKNNRT ${RKNN_PATH}/${CMAKE_SYSTEM_NAME}/librknn_api/${TARGET_LIB_ARCH}/librknnrt.so)
set(LIBRKNNRT_INCLUDES ${RKNN_PATH}/${CMAKE_SYSTEM_NAME}/librknn_api/include)

set(RKLLM_PATH ${CMAKE_CURRENT_SOURCE_DIR})
set(LIBRKLLMRT ${RKLLM_PATH}/lib/${TARGET_LIB_ARCH}/librkllmrt.so)
set(LIBRKLLMRT_INCLUDES ${RKLLM_PATH}/include)

find_package(OpenMP REQUIRED)

include_directories(${LIBRKNNRT_INCLUDES})
include_directories(${LIBRKLLMRT_INCLUDES})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src)

add_executable(imgenc src/image_enc.cc src/img_encoder.cpp)
target_link_libraries(imgenc PRIVATE ${OpenCV_LIBS} ${LIBRKNNRT})

add_executable(demo src/image_enc.cc src/main.cpp)
if(CMAKE_SYSTEM_NAME STREQUAL "Android")
  target_link_libraries(demo PRIVATE ${OpenCV_LIBS} ${LIBRKNNRT} ${LIBRKLLMRT} log)
else()
  target_link_libraries(demo PRIVATE ${OpenCV_LIBS} ${LIBRKNNRT} ${LIBRKLLMRT})
endif()

set_target_properties(demo PROPERTIES LINK_FLAGS -Wl,--no-undefined,--version-script,${CMAKE_SOURCE_DIR}/c_export.map)

set(CMAKE_INSTALL_PREFIX ${CMAKE_SOURCE_DIR}/install/demo_${CMAKE_SYSTEM_NAME}_${TARGET_LIB_ARCH})
install(TARGETS imgenc demo DESTINATION ./)
install(PROGRAMS ${LIBRKNNRT} ${LIBRKLLMRT} DESTINATION lib)
install(FILES ${CMAKE_SOURCE_DIR}/scripts/run.sh DESTINATION .)
install(PROGRAMS ${CMAKE_SOURCE_DIR}/scripts/test_single.sh DESTINATION .)
install(PROGRAMS ${CMAKE_SOURCE_DIR}/scripts/test_multi.sh DESTINATION .)
install(FILES ${CMAKE_SOURCE_DIR}/test/test1.png DESTINATION test)
install(FILES ${CMAKE_SOURCE_DIR}/test/test2.png DESTINATION test)
install(FILES ${CMAKE_SOURCE_DIR}/test/test3.png DESTINATION test)

install(CODE "file(MAKE_DIRECTORY \"\${CMAKE_INSTALL_PREFIX}/models\")")
