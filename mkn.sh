#!/usr/bin/env bash

set -e

CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

[ -z "$(which cmake)" ] && echo "cmake is required to build aws.cpp_sdk" && exit 1;
[ -z "$(which mkn)" ]   && echo "mkn is required to build aws.cpp_sdk" && exit 1;

rm -rf inst
mkdir -p inst/lib inst/include

GIT_URL="https://github.com/aws/aws-sdk-cpp"
GIT_BNC="master"
GIT_OPT="--depth 1"
DIR="aws"

[ -z "$MKN_MAKE_THREADS" ] && MKN_MAKE_THREADS="$(nproc --all)"

[ ! -d "$CWD/$DIR" ] && git clone $GIT_OPT $GIT_URL -b $GIT_BNC $DIR --recursive

## This is a semicolon separated list
## example
# MKN_AWS_CPP_SDK_BUILD="s3;ec2"
[ -n "$MKN_AWS_CPP_SDK_BUILD" ] && MKN_CMAKE_CONFIG+=" -DBUILD_ONLY=$MKN_AWS_CPP_SDK_BUILD"

mkn clean -d
MKN_REPO="$(mkn -G MKN_REPO)"
VER_CURL="$(mkn -G net.curl.version)"

rm -rf $CWD/build
mkdir $CWD/build

pushd $CWD/build
read -r -d '' CMAKE <<- EOM || echo "running cmake"
    cmake -DCMAKE_INSTALL_PREFIX=$CWD/inst
          -DCMAKE_BUILD_TYPE=Release
          -DCURL_INCLUDE_DIR=${MKN_REPO}/net/curl/$VER_CURL/inst/include
          -DCURL_LIBRARY=${MKN_REPO}/net/curl/$VER_CURL/inst/lib/libcurl.so
          $MKN_CMAKE_CONFIG
          ../$DIR
EOM
echo $CMAKE
$CMAKE
make -j$MKN_MAKE_THREADS VERBOSE=1
make install
popd

rm -rf $CWD/build

echo "Finished successfully"
exit 0
