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
BASE_DIR=/media/hdd/aayush/kernel
KERNEL_DIR=$BASE_DIR/sdm660
ANYKERNEL_DIR=$KERNEL_DIR/AnyKernel3
KERNEL_IMG=$KERNEL_DIR/arch/arm64/boot/Image.gz
DT_IMAGE=$KERNEL_DIR/arch/arm64/boot/dt.img
DTBTOOL=$KERNEL_DIR/tools/dtbToolCM
UPLOAD_DIR=$BASE_DIR/$DEVICE

# Export
export ARCH=arm64
export CROSS_COMPILE=$BASE_DIR/aarch64-linux-android-4.9/bin/aarch64-linux-android-
export CROSS_COMPILE_ARM32=$BASE_DIR/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-

## Functions ##

# Make kernel
function make_kernel() {
  echo -e "$cyan***********************************************"
  echo -e "          Initializing defconfig          "
  echo -e "***********************************************$nocol"
  make $defconfig
  echo -e "$cyan***********************************************"
  echo -e "             Building kernel          "
  echo -e "***********************************************$nocol"
  make -j8
  if ! [ -a $KERNEL_IMG ];
  then
    echo -e "$red Kernel Compilation failed! Fix the errors! $nocol"
    exit 1
  fi
}

# Make DT.IMG
function make_dt(){
$DTBTOOL -2 -o $DT_IMAGE -s 2048 -p $KERNEL_DIR/scripts/dtc/ $KERNEL_DIR/arch/arm/boot/dts/qcom/
}

# Making zip
function make_zip() {
mkdir -p tmp_mod
make -j4 modules_install INSTALL_MOD_PATH=tmp_mod INSTALL_MOD_STRIP=1
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
echo -e "$cyan***********************************************"
  echo "          Compiling FireKernel kernel          "
  echo -e "***********************************************$nocol"
  echo -e " "
  echo -e " Select one of the following types of build : "
  echo -e " 1.Dirty"
  echo -e " 2.Clean"
  echo -n " Your choice : ? "
  read ch

  echo -e " Select if you want zip or just kernel : "
  echo -e " 1.Get flashable zip"
  echo -e " 2.Get kernel only"
  echo -n " Your choice : ? "
  read ziporkernel

case $ch in
  1) echo -e "$cyan***********************************************"
     echo -e "          	Dirty          "
     echo -e "***********************************************$nocol"
     make_kernel
     make_dt ;;
  2) echo -e "$cyan***********************************************"
     echo -e "          	Clean          "
     echo -e "***********************************************$nocol"
     make clean
     make mrproper
     make_kernel
     make_dt;;
esac

if [ "$ziporkernel" = "1" ]; then
     echo -e "$cyan***********************************************"
     echo -e "     Making flashable zip        "
     echo -e "***********************************************$nocol"
     make_zip
else
     echo -e "$cyan***********************************************"
     echo -e "     Building Kernel only        "
     echo -e "***********************************************$nocol"
fi
}

# Clean Up
function cleanup(){
rm -rf $KERNEL_DIR/tmp_mod/
rm -rf $ANYKERNEL_DIR/Image.gz-dtb
rm -rf $ANYKERNEL_DIR/modules/system/lib/modules/*.ko
rm -rf $ANYKERNEL_DIR/dt.img
rm -rf $KERNEL_DIR/arch/arm/boot/dts/*.dtb
rm -rf $DT_IMAGE
}

options
cleanup
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
