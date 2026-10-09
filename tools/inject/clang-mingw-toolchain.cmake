# Cross-compile the KH2 co-op mod on Linux with clang targeting MinGW-w64.
# clang (unlike gcc) accepts MSVC __try/__except, which the inject DLL needs.
# Requires: clang, lld, mingw-w64 (headers, libstdc++ from the gcc package).
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR AMD64)

set(KH2_MINGW_TRIPLE x86_64-w64-mingw32)
if(NOT DEFINED KH2_MINGW_GXX)
    file(GLOB _gxx_dirs /usr/lib/gcc/${KH2_MINGW_TRIPLE}/*-posix)
    list(GET _gxx_dirs 0 KH2_MINGW_GXX)
endif()
get_filename_component(KH2_TOOLS_DIR "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)

set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)
set(CMAKE_ASM_COMPILER clang)
set(CMAKE_C_COMPILER_TARGET ${KH2_MINGW_TRIPLE})
set(CMAKE_CXX_COMPILER_TARGET ${KH2_MINGW_TRIPLE})
set(CMAKE_ASM_COMPILER_TARGET ${KH2_MINGW_TRIPLE})
set(CMAKE_RC_COMPILER ${KH2_MINGW_TRIPLE}-windres)

set(CMAKE_FIND_ROOT_PATH /usr/${KH2_MINGW_TRIPLE})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

set(_common "-fms-extensions -femulated-tls -I${KH2_TOOLS_DIR}/caseshim -I/usr/${KH2_MINGW_TRIPLE}/include")
set(CMAKE_C_FLAGS_INIT "${_common}")
set(CMAKE_CXX_FLAGS_INIT "${_common} -I${KH2_MINGW_GXX}/include/c++ -I${KH2_MINGW_GXX}/include/c++/${KH2_MINGW_TRIPLE} -Wno-error")
set(_link "-fuse-ld=lld -static -static-libgcc -static-libstdc++ -L${KH2_MINGW_GXX} -L/usr/${KH2_MINGW_TRIPLE}/lib -lwinpthread")
set(CMAKE_EXE_LINKER_FLAGS_INIT "${_link} ${KH2_TOOLS_DIR}/ucrtshim.o")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "${_link}")
