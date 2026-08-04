cmake_minimum_required(VERSION 4.3.0)
project(han1me_ech LANGUAGES C CXX)

include(ExternalProject)

set(BORINGSSL_SRC "${CMAKE_CURRENT_SOURCE_DIR}/lib/boringssl")
set(CURL_SRC    "${CMAKE_CURRENT_SOURCE_DIR}/lib/curl")
set(INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/install")

ExternalProject_Add(boringssl_project
    SOURCE_DIR "${BORINGSSL_SRC}"
    BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/boringssl"
    CMAKE_ARGS
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
        -DANDROID_ABI=${ANDROID_ABI}
        -DANDROID_PLATFORM=${ANDROID_PLATFORM}
        -DANDROID_NDK=${ANDROID_NDK}
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}
        -DBUILD_SHARED_LIBS=OFF
        -DBUILD_TESTING=OFF
        -DOPENSSL_NO_ASM=ON
    BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --target install
    INSTALL_COMMAND ""
    BUILD_BYPRODUCTS
        "${INSTALL_DIR}/lib/libssl.a"
        "${INSTALL_DIR}/lib/libcrypto.a"
        "${INSTALL_DIR}/include/openssl/ssl.h"
)

ExternalProject_Add(curl_project
    SOURCE_DIR "${CURL_SRC}"
    BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/curl"
    CMAKE_ARGS
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
        -DANDROID_ABI=${ANDROID_ABI}
        -DANDROID_PLATFORM=${ANDROID_PLATFORM}
        -DANDROID_NDK=${ANDROID_NDK}
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}
        -DOPENSSL_ROOT_DIR=${INSTALL_DIR}
        -DOPENSSL_INCLUDE_DIR=${INSTALL_DIR}/include
        -DOPENSSL_SSL_LIBRARY=${INSTALL_DIR}/lib/libssl.a
        -DOPENSSL_CRYPTO_LIBRARY=${INSTALL_DIR}/lib/libcrypto.a
        -DCURL_USE_OPENSSL=ON
        -DUSE_ECH=ON
        -DHAVE_SSL_SET1_ECH_CONFIG_LIST=1
        -DBUILD_SHARED_LIBS=OFF
        -DBUILD_CURL_EXE=OFF
        -DBUILD_EXAMPLES=OFF
        -DBUILD_TESTING=OFF
        -DCMAKE_DISABLE_FIND_PACKAGE_Perl=ON
        -DCURL_DISABLE_DICT=ON
        -DCURL_DISABLE_FILE=ON
        -DCURL_DISABLE_FTP=ON
        -DCURL_DISABLE_GOPHER=ON
        -DCURL_DISABLE_IMAP=ON
        -DCURL_DISABLE_LDAP=ON
        -DCURL_DISABLE_MQTT=ON
        -DCURL_DISABLE_POP3=ON
        -DCURL_DISABLE_RTSP=ON
        -DCURL_DISABLE_SMB=ON
        -DCURL_DISABLE_SMTP=ON
        -DCURL_DISABLE_TELNET=ON
        -DCURL_DISABLE_TFTP=ON
        -DCURL_USE_LIBSSH2=OFF
        -DCURL_USE_LIBPSL=OFF
        -DCURL_ZLIB=OFF
        -DCURL_ZSTD=OFF
        -DCURL_BROTLI=OFF
        -DUSE_LIBIDN2=OFF
        -DUSE_NGHTTP2=OFF
    DEPENDS boringssl_project
    BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --target install
    INSTALL_COMMAND ""
    BUILD_BYPRODUCTS "${INSTALL_DIR}/lib/libcurl.a"
)

set(CURL_LIB "${INSTALL_DIR}/lib/libcurl.a")
set(SSL_LIB "${INSTALL_DIR}/lib/libssl.a")
set(CRYPTO_LIB "${INSTALL_DIR}/lib/libcrypto.a")
set(INCLUDE_DIRS "${INSTALL_DIR}/include")

add_library(han1me_ech SHARED native-lib.cpp)
target_compile_features(han1me_ech PRIVATE cxx_std_20)

add_dependencies(han1me_ech curl_project)

target_include_directories(han1me_ech PRIVATE "${INCLUDE_DIRS}")

find_library(android_lib android)
find_library(log_lib log)
find_library(z_lib z)

target_link_libraries(han1me_ech PRIVATE
    "${CURL_LIB}"
    "${SSL_LIB}"
    "${CRYPTO_LIB}"
    ${android_lib}
    ${log_lib}
    ${z_lib}
)
