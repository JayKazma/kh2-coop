#!/bin/sh
# Cross-build the mod binaries (inject DLL, relay, runtime, kh2ctl) with clang.
# usage: tools/inject/build.sh <kh2-multiplayer source dir> [build dir]
set -e
SRC=${1:?source dir}; BUILD=${2:-$SRC/build-clang}
HERE=$(cd "$(dirname "$0")" && pwd)
clang -target x86_64-w64-mingw32 -O2 -c "$HERE/ucrtshim.c" -o "$HERE/ucrtshim.o"
cmake -S "$SRC" -B "$BUILD" -G Ninja -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_TOOLCHAIN_FILE="$HERE/clang-mingw-toolchain.cmake"
cmake --build "$BUILD" --target kh2coop_inject kh2coop_server kh2coop_runtime_scaffold kh2ctl
mkdir -p "$BUILD/out"
for f in inject/staging/kh2coop_inject.dll kh2coop_runtime_scaffold.exe tools/kh2ctl/kh2ctl.exe kh2coop_server.exe; do
    [ -f "$BUILD/$f" ] && cp "$BUILD/$f" "$BUILD/out/"
done
x86_64-w64-mingw32-strip "$BUILD"/out/*.exe "$BUILD"/out/*.dll
ls -la "$BUILD/out"
