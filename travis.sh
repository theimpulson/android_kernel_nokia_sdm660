#!/bin/bash
BUILD_START=$(date +"%s")

# Colours
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

# Kernel details
KERNEL_NAME="FireKernel"
VERSION="r1.x"
DATE=$(date +"%d-%m-%Y-%I-%M")
DEVICE="PL2"
FINAL_ZIP=$KERNEL_NAME-$VERSION-$DATE-$DEVICE.zip
defconfig=omni_defconfig

# Dirs
ANYKERNEL_DIR=$TRAVIS_BUILD_DIR/AnyKernel3
KERNEL_IMG=$TRAVIS_BUILD_DIR/arch/arm64/boot/Image.gz
DT_IMAGE=$TRAVIS_BUILD_DIR/arch/arm64/boot/dt.img
DTBTOOL=$TRAVIS_BUILD_DIR/tools/dtbToolCM
UPLOAD_DIR=~/$DEVICE

# Export
export ARCH=arm64
export CROSS_COMPILE=~/tc64/bin/aarch64-linux-android-
export CROSS_COMPILE_ARM32=~/tc32/bin/arm-linux-androideabi-

## Functions ##

# Make kernel
function make_kernel() {
make $defconfig
make -j$(nproc --all)
}

# Make DT.IMG
function make_dt(){
$DTBTOOL -2 -o $DT_IMAGE -s 2048 -p $TRAVIS_BUILD_DIR/scripts/dtc/ $TRAVIS_BUILD_DIR/arch/arm/boot/dts/qcom/
}

# Making zip
function make_zip() {
mkdir -p tmp_mod
make -j$(nproc --all) modules_install INSTALL_MOD_PATH=tmp_mod INSTALL_MOD_STRIP=1
find tmp_mod/ -name '*.ko' -type f -exec cp '{}' $ANYKERNEL_DIR/modules/system/lib/modules/ \;
cp $KERNEL_IMG $ANYKERNEL_DIR
cp $DT_IMAGE $ANYKERNEL_DIR
mkdir -p $UPLOAD_DIR
cd $ANYKERNEL_DIR
zip -r9 UPDATE-AnyKernel2.zip * -x README UPDATE-AnyKernel2.zip
mv $ANYKERNEL_DIR/UPDATE-AnyKernel2.zip $UPLOAD_DIR/$FINAL_ZIP
}

# Options
function options() {
make_kernel
make_dt
make_zip
}

# Clean Up
function cleanup(){
rm -rf $TRAVIS_BUILD_DIR/tmp_mod/
rm -rf $ANYKERNEL_DIR/Image.gz-dtb
rm -rf $ANYKERNEL_DIR/modules/system/lib/modules/*.ko
rm -rf $ANYKERNEL_DIR/dt.img
rm -rf $TRAVIS_BUILD_DIR/arch/arm/boot/dts/*.dtb
rm -rf $DT_IMAGE
}

# Uploading
function upload(){
wget -c https://github.com/probonopd/uploadtool/raw/master/upload.sh
bash upload.sh $UPLOAD_DIR/*
}

options
cleanup
upload
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
