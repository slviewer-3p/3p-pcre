#!/bin/sh

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

if [ -z "$AUTOBUILD" ] ; then 
    fail
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    export AUTOBUILD="$(cygpath -u $AUTOBUILD)"
fi

# run build commands from root checkout directory
cd "$(dirname "$0")"

# load autbuild provided shell functions and variables
set +x
eval "$("$AUTOBUILD" source_environment)"
set -x

top="$(pwd)"
stage="${top}"/stage

case "$AUTOBUILD_PLATFORM" in

    "windows")
        echo "Windows not ready for builds yet." 1>&2
        fail
    ;;

    "darwin")
        pushd pcre
            libdir="$top/stage/lib"
            mkdir -p "$libdir"/{debug,release}

            # Select SDK with full path.  This shouldn't have much effect on this
            # build but adding to establish a consistent pattern.
            #
            # sdk=/Developer/SDKs/MacOSX10.6.sdk/
            # sdk=/Developer/SDKs/MacOSX10.7.sdk/
            # sdk=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.6.sdk/
            sdk=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.7.sdk/
            
            opts="${TARGET_OPTS:--arch i386 -iwithsysroot $sdk -mmacosx-version-min=10.6}"

            # Prefer llvm-g++ if available.
            if [ -x /usr/bin/llvm-gcc -a -x /usr/bin/llvm-g++ ]; then
                export CC=/usr/bin/llvm-gcc
                export CXX=/usr/bin/llvm-g++
            fi

            # Debug first
            CFLAGS="$opts -O0 -gdwarf-2" CXXFLAGS="$opts -O0 -gdwarf-2" LDFLAGS="$opts -gdwarf-2" \
                ./configure --disable-dependency-tracking --with-pic --enable-utf --enable-unicode-properties \
                --enable-static=yes --enable-shared=no \
                --prefix="$stage" --includedir="$stage"/include/pcre --libdir="$libdir"/debug
            make 
            make install

            # conditionally run unit tests
            if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                make test
            fi

            make clean

            # Release last for configuration headers
            CFLAGS="$opts -O2 -gdwarf-2" CXXFLAGS="$opts -O2 -gdwarf-2" LDFLAGS="$opts -gdwarf-2" \
                ./configure --disable-dependency-tracking --with-pic --enable-utf --enable-unicode-properties \
                --enable-static=yes --enable-shared=no \
                --prefix="$stage" --includedir="$stage"/include/pcre --libdir="$libdir"/release
            make 
            make install

            # conditionally run unit tests
            if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                make test
            fi

            make clean

        popd
    ;;

    "linux")
        libdir="$top/stage/lib/"
        mkdir -p "$libdir"/{debug,release}
        pushd pcre
            # Linux build environment at Linden comes pre-polluted with stuff that can
            # seriously damage 3rd-party builds.  Environmental garbage you can expect
            # includes:
            #
            #    DISTCC_POTENTIAL_HOSTS     arch           root        CXXFLAGS
            #    DISTCC_LOCATION            top            branch      CC
            #    DISTCC_HOSTS               build_name     suffix      CXX
            #    LSDISTCC_ARGS              repo           prefix      CFLAGS
            #    cxx_version                AUTOBUILD      SIGN        CPPFLAGS
            #
            # So, clear out bits that shouldn't affect our configure-directed build
            # but which do nonetheless.
            #
            # unset DISTCC_HOSTS CC CXX CFLAGS CPPFLAGS CXXFLAGS

            # Prefer gcc-4.6 if available.
            if [ -x /usr/bin/gcc-4.6 -a -x /usr/bin/g++-4.6 ]; then
                export CC=/usr/bin/gcc-4.6
                export CXX=/usr/bin/g++-4.6
            fi

            # Default target to 32-bit
            opts="${TARGET_OPTS:--m32}"

            # Handle any deliberate platform targeting
            if [ -z "$TARGET_CPPFLAGS" ]; then
                # Remove sysroot contamination from build environment
                unset CPPFLAGS
            else
                # Incorporate special pre-processing flags
                export CPPFLAGS="$TARGET_CPPFLAGS"
            fi

            # Debug first
            CFLAGS="$opts -g -O0" CXXFLAGS="$opts -g -O0" LDFLAGS="$opts -g" \
                ./configure --with-pic --enable-utf --enable-unicode-properties \
                --enable-static=yes --enable-shared=no \
                --prefix="$stage" --includedir="$stage"/include/pcre --libdir="$libdir"/debug
            make 
            make install

            # conditionally run unit tests
            if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                make test
            fi

            make clean

            # Release last for header files
            CFLAGS="$opts -O2" CXXFLAGS="$opts -O2" LDFLAGS="$opts" \
                ./configure --with-pic --enable-utf --enable-unicode-properties \
                --enable-static=yes --enable-shared=no \
                --prefix="$stage" --includedir="$stage"/include/pcre --libdir="$libdir"/release
            make 
            make install

            # conditionally run unit tests
            if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                make test
            fi

            make clean
        popd
    ;;

    *)
        echo "Unrecognized platform" 1>&2
        fail
    ;;
esac

mkdir -p stage/LICENSES
cp "pcre/LICENCE" "stage/LICENSES/pcre-license.txt"
mkdir -p "$stage"/docs/pcre/
cp -a "$top"/README.Linden "$stage"/docs/pcre/

pass

