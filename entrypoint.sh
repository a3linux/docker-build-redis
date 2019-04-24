#!/bin/bash
set -e

# 1. Checkout repo
# 2. Compile binary
# 3. Package binary in .tgz
# 4. Package binary in .deb
#
# Options:
# -v: tag version
# -d: debug
# -t <target>: add a make target
#

BUILD=/build/redis
SRC=/src
DEB=/deb


# Reset getopts option index
OPTIND=1

# If set, then build a specific tag version. If unset, then build unstable branch
version="unstable"
# If the -d flag is set then create a debug build of dynomite
mode="production"
# Additional make target
target=""


while getopts "v:d:t:" opt; do
	case "$opt" in
	v)  version=$OPTARG
		;;
	d)  mode=$OPTARG
		;;
	t)  target=$OPTARG
		;;
	esac
done

#
# Checkout Redis source code
#
git clone https://github.com/antirez/redis.git
cd $BUILD
if [ "$version" != "unstable" ] ; then
	echo "Building tagged version:  $version"
	git checkout tags/$version
else
	echo "Building branch: $version"
fi

# Build Redis

# Change the value of target only if not explicitly set
if [ "$mode" == "debug" && "x$target" == "x" ] ; then
	target="noopt"
fi

# Default target == ""
make $target

#
# Create Redis package
#
rm -f $SRC/redis_ubuntu-18.04-x64.tar.gz
rm -rf $SRC/redis-binary
mkdir -p $SRC/redis-binary/conf

# System binaries
cp $BUILD/src/redis-server $SRC/redis-binary/redis-server
if [ "$mode" == "production" ] ; then
	cp $SRC/reis-binary/redis-server $SRC/redis-binary/redis-server-debug
	strip --strip-debug --strip-unneeded /src/redis-binary/redis-server
fi

# Binaries
for b in "redis-benchmark" "redis-check-aof" "redis-check-dump" "redis-cli"
do
	cp $BUILD/src/$b $SRC/redis-binary/
	if [ "$mode" == "production" ] ; then
		strip --strip-debug --strip-unneeded $SRC/redis-binary/$b
	fi
done

# Static files
for s in "00-RELEASENOTES" "BUGS" "COPYING" "README"
do
	cp $BUILD/$s $SRC/redis-binary/
done

cd /src
tar -czf redis_ubuntu-18.04-x64.tgz -C /src redis-binary
