#!/bin/sh

IFS='
'

MYARCH=linux-x86_64
if uname -s | grep -i "linux" > /dev/null ; then
	MYARCH=linux-x86_64
fi
if uname -s | grep -i "darwin" > /dev/null ; then
	MYARCH=darwin-x86_64
fi
if uname -s | grep -i "windows" > /dev/null ; then
	MYARCH=windows-x86_64
fi

NDK=`which ndk-build`
NDK=`dirname $NDK`
NDK=`readlink -f $NDK`

#echo NDK $NDK
GCCPREFIX=arm-linux-androideabi
[ -z "$NDK_TOOLCHAIN_VERSION" ] && NDK_TOOLCHAIN_VERSION=4.9
[ -z "$PLATFORMVER" ] && PLATFORMVER=android-14
LOCAL_PATH=`dirname $0`
if which realpath > /dev/null ; then
	LOCAL_PATH=`realpath $LOCAL_PATH`
else
	LOCAL_PATH=`cd $LOCAL_PATH && pwd`
fi
ARCH=armeabi-v7a


APP_MODULES=
APP_SHARED_LIBS=
MISSING_INCLUDE=
MISSING_LIB=

CFLAGS="\
-fpic -ffunction-sections -funwind-tables -fstack-protector-strong \
-no-canonical-prefixes -march=armv7-a -mfloat-abi=softfp \
-mfpu=vfpv3-d16 -mthumb -O2 -g -DNDEBUG \
-fomit-frame-pointer -fno-strict-aliasing -finline-limit=300 \
-DANDROID -Wall -Wno-unused -Wa,--noexecstack -Wformat -Werror=format-security \
-isystem$NDK/platforms/$PLATFORMVER/arch-arm/usr/include \
-isystem$NDK/sources/cxx-stl/gnu-libstdc++/$NDK_TOOLCHAIN_VERSION/include \
-isystem$NDK/sources/cxx-stl/gnu-libstdc++/$NDK_TOOLCHAIN_VERSION/libs/$ARCH/include \
-isystem$NDK/sources/cxx-stl/gnu-libstdc++/$NDK_TOOLCHAIN_VERSION/include/backward \
-isystem$LOCAL_PATH/../sdl-1.2/include \
`echo $APP_MODULES | sed \"s@\([-a-zA-Z0-9_.]\+\)@-isystem$LOCAL_PATH/../\1/include@g\"` \
$MISSING_INCLUDE $CFLAGS"

UNRESOLVED="-Wl,--no-undefined"
if [ -n "$BUILD_EXECUTABLE" ]; then
	SHARED="-Wl,--gc-sections -Wl,-z,nocopyreloc -pie"
fi
if [ -n "$NO_SHARED_LIBS" ]; then
	APP_SHARED_LIBS=
fi
if [ -n "$ALLOW_UNRESOLVED_SYMBOLS" ]; then
	UNRESOLVED=
fi

LDFLAGS="\
$SHARED \
--sysroot=$NDK/platforms/$PLATFORMVER/arch-arm \
-L$LOCAL_PATH/../../obj/local/$ARCH \
`echo $APP_SHARED_LIBS | sed \"s@\([-a-zA-Z0-9_.]\+\)@$LOCAL_PATH/../../obj/local/$ARCH/lib\1.so@g\"` \
-L$NDK/platforms/$PLATFORMVER/arch-arm/usr/lib \
-lc -lm -ldl -llog -lz \
-L$NDK/sources/cxx-stl/gnu-libstdc++/$NDK_TOOLCHAIN_VERSION/libs/$ARCH \
-lgnustl_static \
-no-canonical-prefixes -march=armv7-a -Wl,--fix-cortex-a8 $UNRESOLVED -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now \
-Wl,--build-id -Wl,--warn-shared-textrel -Wl,--fatal-warnings \
-lsupc++ \
$MISSING_LIB $LDFLAGS"

CC="$NDK/toolchains/$GCCPREFIX-$NDK_TOOLCHAIN_VERSION/prebuilt/$MYARCH/bin/$GCCPREFIX-gcc"
CXX="$NDK/toolchains/$GCCPREFIX-$NDK_TOOLCHAIN_VERSION/prebuilt/$MYARCH/bin/$GCCPREFIX-g++"
CPP="$NDK/toolchains/$GCCPREFIX-$NDK_TOOLCHAIN_VERSION/prebuilt/$MYARCH/bin/$GCCPREFIX-cpp $CFLAGS"

if [ -n "$CLANG" ]; then

CFLAGS="\
-gcc-toolchain $NDK/toolchains/$GCCPREFIX-$NDK_TOOLCHAIN_VERSION/prebuilt/$MYARCH \
-fno-integrated-as -target armv7-none-linux-androideabi -Wno-invalid-command-line-argument -Wno-unused-command-line-argument \
$CFLAGS"

LDFLAGS="$LDFLAGS \
-lgcc \
-latomic \
-gcc-toolchain $NDK/toolchains/$GCCPREFIX-$NDK_TOOLCHAIN_VERSION/prebuilt/$MYARCH \
-target armv7-none-linux-androideabi"

CC="$NDK/toolchains/llvm/prebuilt/$MYARCH/bin/clang"
CXX="$NDK/toolchains/llvm/prebuilt/$MYARCH/bin/clang++"
CPP="$CC -E $CFLAGS"

fi

env PATH=$NDK/toolchains/$GCCPREFIX-$NDK_TOOLCHAIN_VERSION/prebuilt/$MYARCH/bin:$LOCAL_PATH:$PATH \
CFLAGS="$CFLAGS" \
CXXFLAGS="$CXXFLAGS $CFLAGS -frtti -fexceptions" \
LDFLAGS="$LDFLAGS" \
CC="$CC" \
CXX="$CXX" \
RANLIB="$NDK/toolchains/$GCCPREFIX-$NDK_TOOLCHAIN_VERSION/prebuilt/$MYARCH/bin/$GCCPREFIX-ranlib" \
LD="$CC" \
AR="$NDK/toolchains/$GCCPREFIX-$NDK_TOOLCHAIN_VERSION/prebuilt/$MYARCH/bin/$GCCPREFIX-ar" \
CPP="$CPP" \
NM="$NDK/toolchains/$GCCPREFIX-$NDK_TOOLCHAIN_VERSION/prebuilt/$MYARCH/bin/$GCCPREFIX-nm" \
AS="$NDK/toolchains/$GCCPREFIX-$NDK_TOOLCHAIN_VERSION/prebuilt/$MYARCH/bin/$GCCPREFIX-as" \
STRIP="$NDK/toolchains/$GCCPREFIX-$NDK_TOOLCHAIN_VERSION/prebuilt/$MYARCH/bin/$GCCPREFIX-strip" \
"$@"
