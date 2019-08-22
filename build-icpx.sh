#!/usr/bin/env bash

RELEASE_DATE=`date "+%Y%m%d-%H%M"`
RELEASE_DIR=/release.$RELEASE_DATE
BUILD_SRC_DIR=/usr/src
BUILD_RELEASE_DIR=$BUILD_SRC_DIR/release
KERNCONF=ICPX

test -d $RELEASE_DIR && rm -rf $RELEASE_DIR
mkdir $RELEASE_DIR

cd $BUILD_SRC_DIR

test -d .git && mv .git ../_git

echo "[`date "+%Y/%m/%d %H:%M"`] Step 1: make clean"

cd $BUILD_RELEASE_DIR

make clean >$RELEASE_DIR/make-clean-release.log 2>&1

cd $BUILD_SRC_DIR

make clean >$RELEASE_DIR/make-clean.log 2>&1

if [ $? -ne 0 ]; then
	echo "[`date "+%Y/%m/%d %H:%M"`] Failed to make clean"
	exit 1
fi

echo "[`date "+%Y/%m/%d %H:%M"`] Step 2: make -j `sysctl -n hw.ncpu` buildworld buildkernel KERNCONF=$KERNCONF"

sed -e 's/^BRANCH="RELEASE/BRANCH="'$KERNCONF'/' -I .orig $BUILD_SRC_DIR/sys/conf/newvers.sh

cp $BUILD_SRC_DIR/sys/amd64/conf/$KERNCONF $BUILD_SRC_DIR/sys/amd64/conf/$KERNCONF.$RELEASE_DATE
cp $BUILD_SRC_DIR/sys/amd64/conf/$KERNCONF $RELEASE_DIR/$KERNCONF.$RELEASE_DATE

make -j `sysctl -n hw.ncpu` buildworld buildkernel KERNCONF=$KERNCONF >$RELEASE_DIR/make-buildworld-buildkernel.log 2>&1

if [ $? -ne 0 ]; then
	echo "[`date "+%Y/%m/%d %H:%M"`] Failed to make buildworld buildkernel"
	exit 1
fi

cd $BUILD_RELEASE_DIR

echo "[`date "+%Y/%m/%d %H:%M"`] Step 3: make release KERNCONF=$KERNCONF"

make release KERNCONF=$KERNCONF >$RELEASE_DIR/make-release.log 2>&1

if [ $? -ne 0 ]; then
	echo "[`date "+%Y/%m/%d %H:%M"`] Failed to make release"
	exit 1
fi

echo "[`date "+%Y/%m/%d %H:%M"`] Step 4: make install DESTDIR=$RELEASE_DIR"

make install DESTDIR=$RELEASE_DIR >$RELEASE_DIR/make-install.log 2>&1

mv $BUILD_SRC_DIR/sys/conf/newvers.sh.orig $BUILD_SRC_DIR/sys/conf/newvers.sh

if [ $? -ne 0 ]; then
	echo "[`date "+%Y/%m/%d %H:%M"`] Failed to make install"
	exit 1
fi

echo "[`date "+%Y/%m/%d %H:%M"`] done"
exit 0
