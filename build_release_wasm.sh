#!/bin/bash

set -e
set -o pipefail

while getopts ":dpa:snt:xbc:hu" opt; do
  case "${opt}" in
    d )
        export BUILD_TARGET="deps"
        ;;
    p )
        export PACK_DEPS="1"
        ;;
    a )
        export ARCH="$OPTARG"
        ;;
    s )
        export BUILD_TARGET="slicer"
        ;;
    n )
        export NIGHTLY_BUILD="1"
        ;;
    t )
        export OSX_DEPLOYMENT_TARGET="$OPTARG"
        ;;
    x )
        export SLICER_BUILD_TARGET="all"
        ;;
    b )
        export BUILD_ONLY="1"
        ;;
    c )
        export BUILD_CONFIG="$OPTARG"
        ;;
    1 )
        export CMAKE_BUILD_PARALLEL_LEVEL=1
        ;;
    u )
        ;;
    h ) echo "Usage: ./build_release_macos.sh [-d]"
        echo "   -d: Build deps only"
        echo "   -a: Set ARCHITECTURE (arm64 or x86_64)"
        echo "   -s: Build slicer only"
        echo "   -n: Nightly build"
        echo "   -t: Specify minimum version of the target platform, default is 11.3"
        echo "   -b: Build without reconfiguring CMake"
        echo "   -c: Set CMake build configuration, default is Release"
        echo "   -1: Use single job for building"
        exit 0
        ;;
    * )
        ;;
  esac
done

# Set defaults

if [ -z "$ARCH" ]; then
  ARCH="$(uname -m)"
  export ARCH
fi

if [ -z "$BUILD_CONFIG" ]; then
  export BUILD_CONFIG="Release"
fi

if [ -z "$BUILD_TARGET" ]; then
  export BUILD_TARGET="all"
fi


if [ -z "$SLICER_BUILD_TARGET" ]; then
  export SLICER_BUILD_TARGET="ALL_BUILD"
fi

if [ -z "$OSX_DEPLOYMENT_TARGET" ]; then
  export OSX_DEPLOYMENT_TARGET="11.3"
fi

echo "Build params:"
echo " - ARCH: $ARCH"
echo " - BUILD_CONFIG: $BUILD_CONFIG"
echo " - BUILD_TARGET: $BUILD_TARGET"
echo " - OSX_DEPLOYMENT_TARGET: $OSX_DEPLOYMENT_TARGET"
echo

# if which -s brew; then
# 	brew --prefix libiconv
# 	brew --prefix zstd
# 	export LIBRARY_PATH=$LIBRARY_PATH:$(brew --prefix zstd)/lib/
# elif which -s port; then
# 	port install libiconv
# 	port install zstd
# 	export LIBRARY_PATH=$LIBRARY_PATH:/opt/local/lib
# else
# 	echo "Need either brew or macports to successfully build deps"
# 	exit 1
# fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_BUILD_DIR="$PROJECT_DIR/build_$ARCH"
DEPS_DIR="$PROJECT_DIR/deps"
DEPS_BUILD_DIR="$DEPS_DIR/build_$ARCH"
DEPS="$DEPS_BUILD_DIR/OrcaSlicer_dep_$ARCH"

# Fix for Multi-config generators
if [ "$SLICER_CMAKE_GENERATOR" == "Xcode" ]; then
    export BUILD_DIR_CONFIG_SUBDIR="/$BUILD_CONFIG"
else
    export BUILD_DIR_CONFIG_SUBDIR=""
fi

function build_deps() {
    echo "Building deps..."
    (
        set -x
        mkdir -p "$DEPS"
        cd "$DEPS_BUILD_DIR"
        if [ "1." != "$BUILD_ONLY". ]; then
            emcmake cmake .. \
                -DDESTDIR="$DEPS" \
                -DCMAKE_BUILD_TYPE="$BUILD_CONFIG" 
        fi
        emmake cmake --build . --config "$BUILD_CONFIG" --target deps
    )
# GMP files not being found, this fixes it
 #   cp -rf ${DEPS_BUILD_DIR}/dep_GMP-prefix/src/dep_GMP/*.h ${DEPS}/usr/local/include
}

function pack_deps() {
    echo "Packing deps..."
    (
        set -x
        mkdir -p "$DEPS"
        cd "$DEPS_BUILD_DIR"
        tar -zcvf "OrcaSlicer_dep_mac_${ARCH}_$(date +"%Y%m%d").tar.gz" "OrcaSlicer_dep_$ARCH"
    )
}

function build_slicer() {
    echo "Building slicer..."
    (
        set -x
        mkdir -p "$PROJECT_BUILD_DIR"
        cd "$PROJECT_BUILD_DIR"
        if [ "1." != "$BUILD_ONLY". ]; then
            emcmake cmake .. \
                -DBBL_RELEASE_TO_PUBLIC=1 \
                -DCMAKE_PREFIX_PATH="$DEPS/usr/local" \
                -DCMAKE_INSTALL_PREFIX="$PWD/OrcaSlicer" \
                -DCMAKE_BUILD_TYPE="$BUILD_CONFIG" \
                -DCMAKE_INSTALL_RPATH="${DEPS}/usr/local" \
                -DSLIC3R_GUI=OFF \
                -DSLIC3R_DESKTOP_INTEGRATION=OFF \
                -DSLIC3R_ENC_CHECK=OFF \
                -DSLIC3R_STATIC=ON
        fi
        emmake cmake --build . --config "$BUILD_CONFIG" 
    )

    echo "Verify localization with gettext..."
    (
        cd "$PROJECT_DIR"
        ./run_gettext.sh
    )


    # extract version
    # export ver=$(grep '^#define SoftFever_VERSION' ../src/libslic3r/libslic3r_version.h | cut -d ' ' -f3)
    # ver="_V${ver//\"}"
    # echo $PWD
    # if [ "1." != "$NIGHTLY_BUILD". ];
    # then
    #     ver=${ver}_dev
    # fi

    # zip -FSr OrcaSlicer${ver}_Mac_${ARCH}.zip OrcaSlicer.app
}

case "${BUILD_TARGET}" in
    all)
        
        build_deps
        build_slicer
        ;;
    deps)
        build_deps
        ;;
    slicer)
       
        build_slicer
        ;;
    *)
        echo "Unknown target: $BUILD_TARGET. Available targets: deps, slicer, all."
        exit 1
        ;;
esac

if [ "1." == "$PACK_DEPS". ]; then
    pack_deps
fi
