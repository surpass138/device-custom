#! /bin/bash

source BoardConfig.mk

# Config
SDK_ROOT=${PWD}
BUILD_CONFIG=$CFG_BUILDROOT
echo "$BUILD_CONFIG"
PRODUCT_PATH=${SDK_ROOT}/device/rockchip/${TARGET_PRODUCT}
BUILDROOT_PATH=${SDK_ROOT}/buildroot
IMAGE_OUT_PATH=${SDK_ROOT}/rockdev/Image-$TARGET_PRODUCT
KERNEL_PATH=${SDK_ROOT}/kernel
UBOOT_PATH=${SDK_ROOT}/u-boot
MISC_IMG_PATH=$PRODUCT_PATH/rockimg/misc.img
RECOVERY_IMG_PATH=${SDK_ROOT}/buildroot/output/rockchip_rk3308_recovery/images/recovery.img
PACKAGE_DATA_TOOL_PATH="$(pwd)/buildroot/output/$BUILD_CONFIG/host/usr/bin:$(pwd)/buildroot/output/$BUILD_CONFIG/host/usr/sbin" 
PACKAGE_DATA_TOOL=${SDK_ROOT}/buildroot/output/$BUILD_CONFIG/host/usr/bin/mke2img
MKSQUASHFS_TOOL=${SDK_ROOT}/buildroot/output/$BUILD_CONFIG/host/usr/bin/mksquashfs
export PATH=$PATH:${PACKAGE_DATA_TOOL_PATH}

if [ ! -f ${PACKAGE_DATA_TOOL} ];then
	echo "Please Make Buildroot First!!!"
	exit -1
fi

rm -rf $IMAGE_OUT_PATH
mkdir -p $IMAGE_OUT_PATH

echo "Package rootfs.img now"
cp $(pwd)/buildroot/output/$BUILD_CONFIG/images/rootfs.${ROOTFS_TYPE} $IMAGE_OUT_PATH/rootfs.img
echo "Package rootfs Done..."

if [ ! -f $KERNEL_PATH/kernel.img -o ! -f $KERNEL_PATH/boot.img ];then
	echo "Please Make Kernel First!!!"
	exit -1
fi

echo "Package oem.img now"
if [ "${OEM_PARTITION_TYPE}" == "ext2" ];then
    ${PACKAGE_DATA_TOOL} -d ${PRODUCT_PATH}/${OEM_PATH} -G 2 -R 1 -B 2048 -I 0 -o ${IMAGE_OUT_PATH}/oem.img
else
    ${MKSQUASHFS_TOOL} ${PRODUCT_PATH}/${OEM_PATH} ${IMAGE_OUT_PATH}/oem.img -noappend -comp gzip
fi
echo "Package data.img [image type: ${OEM_PARTITION_TYPE}] Done..."

echo "Package userdata.img now"
	${PACKAGE_DATA_TOOL} -d ${PRODUCT_PATH}/userdata -G 2 -R 1 -B 2048 -I 0 -o ${IMAGE_OUT_PATH}/userdata.img
echo "Package userdata.img Done..."

if [ "${FLASH_TYPE}" == "nand" ];then
	if [ "${OEM_PATH}" == "aispeech" ];then
		PARAMETER=$PRODUCT_PATH/rockimg/gpt-nand-aispeech.txt
	else
		PARAMETER=$PRODUCT_PATH/rockimg/gpt-nand.txt
	fi
else
	PARAMETER=$PRODUCT_PATH/rockimg/gpt-emmc.txt
fi

if [ -f $UBOOT_PATH/uboot.img ]
then
	echo -n "create uboot.img..."
	cp -a $UBOOT_PATH/uboot.img $IMAGE_OUT_PATH/uboot.img
	echo "done."
else
	echo "$UBOOT_PATH/uboot.img not fount! Please make it from $UBOOT_PATH first!"
fi

if [ -f $UBOOT_PATH/trust.img ]
then
        echo -n "create trust.img..."
        cp -a $UBOOT_PATH/trust.img $IMAGE_OUT_PATH/trust.img
        echo "done."
else    
        echo "$UBOOT_PATH/trust.img not fount! Please make it from $UBOOT_PATH first!"
fi

if [ -f $UBOOT_PATH/*_loader_*.bin ]
then
        echo -n "create loader..."
        cp -a $UBOOT_PATH/*_loader_*.bin $IMAGE_OUT_PATH/MiniLoaderAll.bin
        echo "done."
else
		echo -n "create loader..."
		cp -a $UBOOT_PATH/*_loader_*.bin $IMAGE_OUT_PATH/
        echo "done."
fi

if [ -f $KERNEL_PATH/boot.img ]
then
        echo -n "create boot.img..."
        cp -a $KERNEL_PATH/boot.img $IMAGE_OUT_PATH/boot.img
        echo "done."
else
        echo "$KERNEL_PATH/boot.img not fount!"
fi

if [ -f $MISC_IMG_PATH ]
then
        echo -n "create misc.img..."
        cp -a $MISC_IMG_PATH $IMAGE_OUT_PATH/misc.img
        echo "done."
else
        echo "$KERNEL_PATH/boot.img not fount!"
fi

if [ -f $RECOVERY_IMG_PATH ]
then
        echo -n "create boot.img..."
        cp -a $RECOVERY_IMG_PATH $IMAGE_OUT_PATH/recovery.img
        echo "done."
else
        echo "$KERNEL_PATH/boot.img not fount!"
fi

if [ -f $PARAMETER ]
then
        echo -n "create parameter..."
        cp -a $PARAMETER $IMAGE_OUT_PATH/parameter.txt
		cp -a $PRODUCT_PATH/rockimg/gpt-nand-32bit.txt $IMAGE_OUT_PATH/parameter_32bit.txt
        echo "done."
else
        echo "$PARAMETER not fount!"
fi

echo "Image: image in ${IMAGE_OUT_PATH} is ready"