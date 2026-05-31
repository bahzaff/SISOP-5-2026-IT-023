#!/bin/bash

KERNEL_VERSION="6.1.1"
KERNEL_DIR="linux-${KERNEL_VERSION}"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz"

# Download kernel jika belum ada
if [ ! -f "linux-${KERNEL_VERSION}.tar.xz" ]; then
    echo "[*] Downloading Linux kernel ${KERNEL_VERSION}..."
    wget "$KERNEL_URL"
fi

# Extract
if [ ! -d "$KERNEL_DIR" ]; then
    echo "[*] Extracting kernel..."
    tar -xf "linux-${KERNEL_VERSION}.tar.xz"
fi

cd "$KERNEL_DIR"

# Patch tg3.h
sed -i 's/#define TG3_RSS_MAX_NUM_QS\t\t4/#define TG3_RSS_MAX_NUM_QS\t\t5/' drivers/net/ethernet/broadcom/tg3.h

# Patch blk-iocost.c
sed -i '3035s/%u/%lu/' block/blk-iocost.c
sed -i '3045s/%u/%lu/' block/blk-iocost.c

# Disable driver broadcom tg3 dari Makefile
sed -i 's/obj-$(CONFIG_TIGON3)/# obj-$(CONFIG_TIGON3)/' drivers/net/ethernet/broadcom/Makefile

# Config
make defconfig

# Enable network
scripts/config --enable CONFIG_VIRTIO
scripts/config --enable CONFIG_VIRTIO_NET
scripts/config --enable CONFIG_VIRTIO_PCI
scripts/config --enable CONFIG_NET
scripts/config --enable CONFIG_INET
scripts/config --enable CONFIG_E1000

make olddefconfig

# Compile
echo "[*] Compiling kernel..."
make -j$(nproc)

# Cek hasil
if [ ! -f "arch/x86/boot/bzImage" ]; then
    echo "[!] ERROR: Compile gagal, bzImage tidak ditemukan!"
    exit 1
fi

# Copy hasil
cp arch/x86/boot/bzImage ../osboot/bzImage

# Copy .config ke soal_1/
cp .config ../.config

echo "[+] Kernel compiled! Output: osboot/bzImage"
