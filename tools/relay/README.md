# Building the local relay (kh2coop_server.exe) without Visual Studio

Cross-compiled on Linux from the kh2-multiplayer source with MinGW-w64 (GCC 13), statically linked:

    apt-get install mingw-w64 cmake ninja-build
    # wrapper that turns off -Werror (the source has -Werror on style warnings):
    printf '#!/bin/sh\nexec /usr/bin/x86_64-w64-mingw32-g++ "$@" -Wno-error\n' > gxx-wrap && chmod +x gxx-wrap
    # MinGW headers are lower-case; the source includes <Windows.h>:
    mkdir caseshim && echo '#include <windows.h>' > caseshim/Windows.h
    cmake -S kh2-multiplayer -B build-mingw -G Ninja -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_TOOLCHAIN_FILE=mingw-toolchain.cmake -DCMAKE_CXX_FLAGS="-I$PWD/caseshim"
    cmake --build build-mingw --target kh2coop_server
    x86_64-w64-mingw32-strip build-mingw/kh2coop_server.exe

Edit the CMAKE_CXX_COMPILER line in mingw-toolchain.cmake to point at gxx-wrap. The relay only talks ENet;
it needs no Steam. Protocol version is compiled in, so build it from the same source revision as the runtime.
