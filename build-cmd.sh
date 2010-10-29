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

# load autbuild provided shell functions and variables
set +x
eval "$("$AUTOBUILD" source_environment)"
set -x
top="$(pwd)"

case "$AUTOBUILD_PLATFORM" in
        "linux")
			libdir="$top/stage/libraries/i686-linux/"
            mkdir -p "$libdir"/lib_{debug,release}_client
			configure
			make 

#			cp "external-libs/boost/lib/mingw/libboost_filesystem.a" \
#				"$libdir/lib_release_client/libboost_filesystem.a"
#			cp "external-libs/boost/lib/mingw/libboost_system.a" \
#				"$libdir/lib_release_client/libboost_system.a"
#
#			cp "build/linux-1.4/libcollada14dom.a" \
#				"$libdir/lib_release_client/libcollada14dom.a"
#
#			cp "external-libs/boost/lib/mingw/libboost_filesystem.a" \
#				"$libdir/lib_debug_client/libboost_filesystem.a"
#			cp "external-libs/boost/lib/mingw/libboost_system.a" \
#				"$libdir/lib_debug_client/libboost_system.a"
#
#			cp "build/linux-1.4-d/libcollada14dom-d.a" \
#				"$libdir/lib_debug_client/libcollada14dom-d.a"
        ;;

esac
mkdir -p "stage/libraries/include/pcre"
cp -R *.h "stage/libraries/include/pcre/"
mkdir -p stage/LICENSES
cp "LICENCE" "stage/LICENSES/pcre-license.txt"

pass

