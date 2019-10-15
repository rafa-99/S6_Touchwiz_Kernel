#!/bin/sh

# SETUP
# -----
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`
export USE_CCACHE=1
export PLATFORM_VERSION=7.0
RDIR=$(pwd)
OUTDIR=$RDIR/arch/$ARCH/boot
DTSDIR=$RDIR/arch/$ARCH/boot/dts
DTBDIR=$OUTDIR/dtb
DTCTOOL=$RDIR/scripts/dtc/dtc
INCDIR=$RDIR/include
PAGE_SIZE=2048
DTB_PADDING=0
export REVISION="RC"
export KBUILD_BUILD_VERSION="1"
S6DEVICE="Nougat"
EDGE_LOG=Edge_build.log
FLAT_LOG=Flat_build.log
PORT=0
DEFCONFIG=defconfig
DEFCONFIG_S6EDGE=defconfig_edge
DEFCONFIG_S6FLAT=defconfig_flat
TMOBILE_DEFCONFIG=defconfig_tmobile

# PROGRAM START
# -------------
clear
echo ""
echo "Build Kernel for:"
echo ""
echo "S6 Nougat"
echo "(1) S6 Flat SM-G920F"
echo "(2) S6 Edge SM-G925F"
echo "(3) S6 Edge + Flat International"
echo "(4) S6 Flat SM-G920T"
echo "(5) S6 Edge SM-G925T"
echo "(6) S6 Edge + Flat Tmobile"
echo ""
echo ""
read -p "Select an option to compile the kernel " prompt

if [ $prompt == "1" ]; then
    MODEL=G920
    DEVICE=$S6DEVICE
    KERNEL_DEFCONFIG=$DEFCONFIG_S6FLAT
    TMOBILE=0
    LOG=$FLAT_LOG
    echo "S6 Flat G920F Selected"
elif [ $prompt == "2" ]; then
    MODEL=G925
    DEVICE=$S6DEVICE
    KERNEL_DEFCONFIG=$DEFCONFIG_S6EDGE
    TMOBILE=0
    LOG=$EDGE_LOG
    echo "S6 Edge G925F Selected"
elif [ $prompt == "3" ]; then
    MODEL=G925
    DEVICE=$S6DEVICE
    KERNEL_DEFCONFIG=$DEFCONFIG_S6EDGE
    TMOBILE=0
    LOG=$EDGE_LOG
    echo "S6 EDGE + FLAT International Selected"
    echo "Compiling EDGE ..."
    MODEL=G920
    KERNEL_DEFCONFIG=$DEFCONFIG_S6FLAT
    TMOBILE=0
    LOG=$FLAT_LOG
    echo "Compiling FLAT ..."
elif [ $prompt == "4" ]; then
    MODEL=G920
    DEVICE=$S6DEVICE
    KERNEL_DEFCONFIG=$DEFCONFIG_S6FLAT
    TMOBILE=1
    LOG=$FLAT_LOG
    echo "S6 Flat G920T Selected"
elif [ $prompt == "5" ]; then
    MODEL=G925
    DEVICE=$S6DEVICE
    KERNEL_DEFCONFIG=$DEFCONFIG_S6EDGE
    TMOBILE=1
    LOG=$EDGE_LOG
    echo "S6 Edge G925T Selected"
elif [ $prompt == "6" ]; then
    MODEL=G925
    DEVICE=$S6DEVICE
    KERNEL_DEFCONFIG=$DEFCONFIG_S6EDGE
    TMOBILE=1
    LOG=$EDGE_LOG
    echo "S6 EDGE + FLAT Tmobile Selected"
    echo "Compiling EDGE ..."
    MODEL=G920
    KERNEL_DEFCONFIG=$DEFCONFIG_S6FLAT
    TMOBILE=1
    LOG=$FLAT_LOG
    echo "Compiling FLAT ..."
fi

cp -f $RDIR/arch/$ARCH/configs/$DEFCONFIG $RDIR/.config
cat $RDIR/arch/$ARCH/configs/$KERNEL_DEFCONFIG >> $RDIR/.config

if [ $TMOBILE == "1" ]; then
	cat $RDIR/arch/$ARCH/configs/$TMOBILE_DEFCONFIG >> $RDIR/.config
fi

# MAKE
# ---------

	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE \
			tmp_defconfig || exit -1
	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE || exit -1
	echo ""
	mkdir -p "modules_output"
	make INSTALL_MOD_PATH=$RDIR/modules_output
	make INSTALL_MOD_PATH=$RDIR/modules_output INSTALL_MOD_STRIP=1 modules_install

	[ -f "$DTCTOOL" ] || {
		echo "You need to run ./build.sh first!"
		exit 1
	}

if [ $TMOBILE == "1" ]; then
    case $MODEL in
	G920)
		DTSFILES="exynos7420-zeroflte_usa_00 exynos7420-zeroflte_usa_01 exynos7420-zeroflte_usa_02 exynos7420-zeroflte_usa_03 exynos7420-zeroflte_usa_04 exynos7420-zeroflte_usa_05"
		;;
	G925)
		DTSFILES="exynos7420-zerolte_usa_01 exynos7420-zerolte_usa_02 exynos7420-zerolte_usa_03 exynos7420-zerolte_usa_04 exynos7420-zerolte_usa_05 exynos7420-zerolte_usa_06 exynos7420-zerolte_usa_07 exynos7420-zerolte_usa_08"
		;;
    *)
    echo "Unknown device: $MODEL"
	exit 1
	;;
	esac
else
    case $MODEL in
    G920)
		DTSFILES="exynos7420-zeroflte_eur_open_00 exynos7420-zeroflte_eur_open_01 exynos7420-zeroflte_eur_open_02 exynos7420-zeroflte_eur_open_03 exynos7420-zeroflte_eur_open_04 exynos7420-zeroflte_eur_open_05 exynos7420-zeroflte_eur_open_06 exynos7420-zeroflte_eur_open_07"
		;;
	G925)
		DTSFILES="exynos7420-zerolte_eur_open_01 exynos7420-zerolte_eur_open_02 exynos7420-zerolte_eur_open_03 exynos7420-zerolte_eur_open_04 exynos7420-zerolte_eur_open_05 exynos7420-zerolte_eur_open_06 exynos7420-zerolte_eur_open_07 exynos7420-zerolte_eur_open_08"
		;;
    *)
    echo "Unknown device: $MODEL"
		exit 1
		;;
	esac
fi

	mkdir -p $OUTDIR $DTBDIR
	cd $DTBDIR || {
		echo "Unable to cd to $DTBDIR!"
		exit 1
	}
	rm -f ./*
	echo "Processing dts files."
	for dts in $DTSFILES; do
		echo "=> Processing: ${dts}.dts"
		${CROSS_COMPILE}cpp -nostdinc -undef -x assembler-with-cpp -I "$INCDIR" "$DTSDIR/${dts}.dts" > "${dts}.dts"
		echo "=> Generating: ${dts}.dtb"
		$DTCTOOL -p $DTB_PADDING -i "$DTSDIR" -O dtb -o "${dts}.dtb" "${dts}.dts"
	done
	echo "Generating dtb.img."
	$RDIR/scripts/dtbtool_exynos/dtbtool -o "$OUTDIR/dtb.img" -d "$DTBDIR/" -s $PAGE_SIZE
	echo "Done."
