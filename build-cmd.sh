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

case "$AUTOBUILD_PLATFORM" in
        "darwin")
		libdir="$top/stage/lib"
		mkdir -p "$libdir"/{debug,release}

		opts="-O2 -arch i386 -mmacosx-version-min=10.4 -DMAC_OS_X_VERSION_MIN_REQUIRED=1040 -iwithsysroot /Developer/SDKs/MacOSX10.4u.sdk"
		CFLAGS="$opts" CXXFLAGS="$opts" LDFLAGS="$opts" ./configure --disable-dependency-tracking
			make 

			cp ".libs/libpcre.a" \
				"$libdir/release/libpcre.a"
			cp ".libs/libpcrecpp.a" \
				"$libdir/release/libpcrecpp.a"
			cp ".libs/libpcreposix.a" \
				"$libdir/release/libpcreposix.a"
        ;;

        "linux")
			libdir="$top/stage/lib/"
            mkdir -p "$libdir"/{debug,release}
			./configure
			make 

			cp ".libs/libpcre.a" \
				"$libdir/release/libpcre.a"
			cp ".libs/libpcrecpp.a" \
				"$libdir/release/libpcrecpp.a"
			cp ".libs/libpcreposix.a" \
				"$libdir/release/libpcreposix.a"
        ;;

esac
mkdir -p "stage/include/pcre"
cp -R *.h "stage/include/pcre/"
mkdir -p stage/LICENSES
cp "LICENCE" "stage/LICENSES/pcre-license.txt"

pass

