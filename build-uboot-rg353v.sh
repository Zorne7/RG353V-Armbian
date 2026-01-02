#!/bin/bash

set -eu

[ -d u-boot ] || git clone https://github.com/u-boot/u-boot.git
[ -d rkbin ] || git clone https://github.com/rockchip-linux/rkbin
cd u-boot
git checkout v2025.10
export CROSS_COMPILE=aarch64-linux-gnu-
export BL31=../rkbin/bin/rk35/rk3568_bl31_v1.45.elf
export ROCKCHIP_TPL=../rkbin/bin/rk35/rk3568_ddr_1056MHz_v1.23.bin
make anbernic-rgxx3-rk3566_defconfig
make
cd ..
[ -d bootloader ] || mkdir bootloader
cp u-boot/idbloader.img ./bootloader
cp u-boot/u-boot.itb ./bootloader
echo "######### Bootloader built #########"
