#!/bin/bash

REPO=`dirname "$(cd ${0%/*} && echo $PWD/${0##*/})"`
PREFIX=${1:-~/MySql-5.7}
BUILD=${2:-~/MySql-5.7/build}
TRE_RDP=${3:-~/xw-3rdp}
NUMJOBS=${NUMJOBS:--j6}


mkdir -p "$BUILD" && cd "$BUILD" && cmake "$REPO" -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE="Release"\
 -DCMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_NO_WARNINGS:BOOL=1\
 -DWITH_EMBEDDED_SERVER:BOOL=0\
 -DCOMMUNITY_BUILD:BOOL=1\
 -DWITH_UNIT_TESTS:BOOL=0\
 -DWITH_ARCHIVE_STORAGE_ENGINE:BOOL=0\
 -DWINDOWS_RUNTIME_MD:BOOL=0\
 -DWITH_ASAN:BOOL=0\
 -DWITH_FEDERATED_STORAGE_ENGINE:BOOL=0\
 -DWITH_PARTITION_STORAGE_ENGINE:BOOL=0\
 -DMYSQL_DATADIR:PATH="$PREFIX\data"\
 -DBOOST_INCLUDE_DIR:PATH="$TRE_RDP\include\boost-1_59"\
 -DMYSQL_KEYRINGDIR:PATH="$PREFIX\keyring"\
 -DWITH_BOOST:PATH="$TRE_RDP\include\boost-1_59"\
 -DTMPDIR:PATH="$PREFIX\tmp"\
 -DCMAKE_INSTALL_PREFIX:PATH="$PREFIX"\
 -DCMAKE_BUILD_TYPE:STRING="RelWithDebInfo"\
 -DMYSQL_PROJECT_NAME:STRING="MySQL"
 
 #full build 
 #cmake --build "$BUILD" --target install -- ${NUMJOBS}

pushd "$BUILD"/libservices && make install && popd
pushd "$BUILD"/libmysql && make install && popd
pushd "$BUILD"/include && make install && popd