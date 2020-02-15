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
VERSION="r2.2"
DATE=$(date +"%d-%m-%Y-%I-%M")
DEVICE="NOKIA_SDM660"
FINAL_ZIP=$KERNEL_NAME-$VERSION-$DATE-$DEVICE.zip
defconfig=nokia_defconfig

# Dirs
ANYKERNEL_DIR=$GITHUB_WORKSPACE/AnyKernel3
KERNEL_IMG=$GITHUB_WORKSPACE/output/arch/arm64/boot/Image.gz-dtb

# Environment Variables
export ARCH=arm64

export CROSS_COMPILE=$HOME/aarch64-elf-gcc/bin/aarch64-elf-
export CROSS_COMPILE_ARM32=$HOME/arm-eabi-gcc/bin/arm-eabi-

export PATH=${CLANG_PATH}:${PATH}
export CLANG_PATH=$HOME/aosp-clang/bin
export CLANG_TRIPLE=aarch64-linux-gnu-
export CLANG_TCHAIN="$HOME/aosp-clang/bin"

export KBUILD_COMPILER_STRING="$(${CLANG_TCHAIN} --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"

## Functions ##

# Make kernel
function make_kernel() {
make $defconfig O=output/
make -j$(nproc --all) O=output/
}

# Making zip
function make_zip() {
cp $KERNEL_IMG $ANYKERNEL_DIR
cd $ANYKERNEL_DIR
zip -r9 UPDATE-AnyKernel3.zip * -x README UPDATE-AnyKernel3.zip
mv $ANYKERNEL_DIR/UPDATE-AnyKernel3.zip $GITHUB_WORKSPACE/$FINAL_ZIP
}

make_kernel
make_zip

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
