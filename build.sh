# /bin/bash

# 解包tar.bz2
# UNPACK_DIR 必须是完整目录路径
unpack_tar_bz2()
{
	DL_URL=$2
	UNPACK_DIR=$1
	DL_FILE=${DL_URL##*/};
	
	mkdir -p ${UNPACK_DIR%/*};
	pushd ${UNPACK_DIR%/*};
	if [ ! -d "${UNPACK_DIR}" ]; then
		if [ ! -f "${DL_FILE}" ]; then
			wget -O ${DL_FILE} ${DL_URL};
		fi;
		tar -jxf ${DL_FILE};
		rm -rf ${DL_FILE};
	fi;
	popd;
}

# 完整使用 128M flash
nand128m()
{
	OLD='wndr4300_mtdlayout=mtdparts=ar934x-nfc:256k(u-boot)ro,256k(u-boot-env)ro,256k(caldata),512k(pot),2048k(language),512k(config),3072k(traffic_meter),2048k(kernel),23552k(ubi),25600k@0x6c0000(firmware),256k(caldata_backup),-(reserved)'
	NEW='wndr4300_mtdlayout=mtdparts=ar934x-nfc:256k(u-boot)ro,256k(u-boot-env)ro,256k(caldata),512k(pot),2048k(language),512k(config),3072k(traffic_meter),2048k(kernel),121856k(ubi),123904k@0x6c0000(firmware),256k(caldata_backup),-(reserved)'
	EDIT_FILE="target/linux/ar71xx/image/Makefile"
#	sed -n  "/^${OLD}$/p" ${EDIT_FILE};
	sed -i "s/^${OLD}$/${NEW}/g" ${EDIT_FILE};
#	sed -n  "/^${NEW}$/p" ${EDIT_FILE};
	[ `sed -n  "/^${NEW}$/p" ${EDIT_FILE} | wc -l` -eq 1 ] && echo OK. ;
}

nomodule()
{
	sed -i '/=m$/s/^/# /g' .config
	sed -i 's/=m$/ is not set/g' .config
}

cfg15051()
{
	wget -O config.diff https://downloads.openwrt.org/chaos_calmer/15.05.1/ar71xx/nand/config.diff
	rm -rf .config
	make defconfig
	cat config.diff >> .config
	make defconfig
	make menuconfig
}

# imagebuilder
IMAGE_BUILDER_DIR=${HOME}/wndr3700v4/img;
image_build_system()
{
	VERSION=15.05.1
	DL_URL=https://downloads.openwrt.org/chaos_calmer/15.05.1/ar71xx/nand/OpenWrt-ImageBuilder-15.05.1-ar71xx-nand.Linux-x86_64.tar.bz2
	DL_FILE=${DL_URL##*/}
	UNPACK_DIR=${HOME}/wndr3700v4/OpenWrt-ImageBuilder-15.05.1-ar71xx-nand.Linux-x86_64
	
	unpack_tar_bz2 "${UNPACK_DIR}" "${DL_URL}";
	rm -rf ${IMAGE_BUILDER_DIR};
	ln -s ${UNPACK_DIR} ${IMAGE_BUILDER_DIR};
}

# sdk
SDK_DIR=${HOME}/wndr3700v4/sdk;
sdk_build_system()
{
	VERSION=15.05.1
	DL_URL=https://downloads.openwrt.org/chaos_calmer/15.05.1/ar71xx/nand/OpenWrt-SDK-15.05.1-ar71xx-nand_gcc-4.8-linaro_uClibc-0.9.33.2.Linux-x86_64.tar.bz2
	DL_FILE=${DL_URL##*/}
	UNPACK_DIR=${HOME}/wndr3700v4/OpenWrt-SDK-15.05.1-ar71xx-nand_gcc-4.8-linaro_uClibc-0.9.33.2.Linux-x86_64
	
	unpack_tar_bz2 "${UNPACK_DIR}" "${DL_URL}";
	rm -rf ${SDK_DIR};
	ln -s ${UNPACK_DIR} ${SDK_DIR};
}

# luci
LUCI='luci luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn'
luci()
{
	if [ ! -d "${IMAGE_BUILDER_DIR}" ]; then
		image_build_system;
	fi;
	
	pushd ${IMAGE_BUILDER_DIR};
	nand128m;
	make image PROFILE=WNDR4300 PACKAGES="${LUCI}"
	popd;
}

dnsmasq_full()
{
	if [ ! -d "${IMAGE_BUILDER_DIR}" ]; then
		image_build_system;
	fi;
	
	pushd ${IMAGE_BUILDER_DIR};
	nand128m;
	make image PROFILE=WNDR4300 PACKAGES="${LUCI} -dnsmasq dnsmasq-full"
	popd;
}

# samba
USB='kmod-usb-storage kmod-usb-storage-extras kmod-scsi-core block-mount usbutils blkid fdisk e2fsprogs hdparm kmod-fs-ext4'
SMB='luci-app-samba luci-i18n-samba-zh-cn'
FAT32='kmod-fs-vfat kmod-nls-cp437 kmod-nls-iso8859-1 dosfsck mkdosfs dosfslabel'
EXFAT='kmod-fs-exfat'
NTFS='kmod-fs-ntfs'
F2FS='kmod-fs-f2fs libf2fs f2fs-tools'
smb()
{
	if [ ! -d "${IMAGE_BUILDER_DIR}" ]; then
		image_build_system;
	fi;
	
	pushd ${IMAGE_BUILDER_DIR};
	nand128m;
	make image PROFILE=WNDR4300 PACKAGES="${LUCI} ${USB} ${SMB} ${FAT32} ${NTFS}";
	popd;
}

# BT
BT='luci-app-transmission luci-i18n-transmission-zh-cn transmission-web'
bt()
{
	if [ ! -d "${IMAGE_BUILDER_DIR}" ]; then
		image_build_system;
	fi;
	
	pushd ${IMAGE_BUILDER_DIR};
	nand128m;
	make image PROFILE=WNDR4300 PACKAGES="${LUCI} ${USB} ${SMB} ${FAT32} ${NTFS} ${BT}";
	popd;
}

################################################################
if [ -z "$1" ]; then
	cat $0 | grep \(\)$
else
	if [ `cat $0 | grep ^$1\(\)$ | wc -l` -eq 1 ]; then
		$*
	else
		echo "Invalid parameter"
	fi
fi
