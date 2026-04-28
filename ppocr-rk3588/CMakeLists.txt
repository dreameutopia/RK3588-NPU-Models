cmake_minimum_required(VERSION 3.15.1)

project(ppocr-rk3588-demo)

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

find_package(OpenMP REQUIRED)

include_directories(${LIBRKNNRT_INCLUDES})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src)

add_executable(ppocr_demo
    src/main.cpp
    src/ppocr_system.cc
    src/postprocess.cc
    src/clipper.cc
)

target_link_libraries(ppocr_demo PRIVATE ${OpenCV_LIBS} ${LIBRKNNRT})

set(CMAKE_INSTALL_PREFIX ${CMAKE_SOURCE_DIR}/install)
install(TARGETS ppocr_demo DESTINATION ./)
install(PROGRAMS ${LIBRKNNRT} DESTINATION lib)
install(FILES ${CMAKE_SOURCE_DIR}/run.sh DESTINATION .)
install(FILES ${CMAKE_SOURCE_DIR}/model/ppocrv4_det_serverial.rknn DESTINATION model)
install(FILES ${CMAKE_SOURCE_DIR}/model/ppocrv4_rec_serverial.rknn DESTINATION model)
install(FILES ${CMAKE_SOURCE_DIR}/test/test1.png DESTINATION test)
install(FILES ${CMAKE_SOURCE_DIR}/test/test2.png DESTINATION test)
install(FILES ${CMAKE_SOURCE_DIR}/test/test3.png DESTINATION test)
