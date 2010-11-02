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
        "darwin")
			libdir="$top/stage/libraries/universal-darwin/"
            mkdir -p "$libdir"/lib_{debug,release}
			configure
			make 

			cp ".libs/libpcre.a" \
				"$libdir/lib_release/libpcre.a"
			cp ".libs/libpcrecpp.a" \
				"$libdir/lib_release/libpcrecpp.a"
			cp ".libs/libpcreposix.a" \
				"$libdir/lib_release/libpcreposix.a"
        ;;

        "linux")
			libdir="$top/stage/libraries/i686-linux/"
            mkdir -p "$libdir"/lib_{debug,release}_client
			configure
			make 

			cp ".libs/libpcre.a" \
				"$libdir/lib_release_client/libpcre.a"
			cp ".libs/libpcrecpp.a" \
				"$libdir/lib_release_client/libpcrecpp.a"
			cp ".libs/libpcreposix.a" \
				"$libdir/lib_release_client/libpcreposix.a"
        ;;

esac
mkdir -p "stage/libraries/include/pcre"
cp -R *.h "stage/libraries/include/pcre/"
mkdir -p stage/LICENSES
cp "LICENCE" "stage/LICENSES/pcre-license.txt"

pass

