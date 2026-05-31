#!/bin/bash

case "$1" in
    --single)
        echo "[*] Booting single-user filesystem..."
        qemu-system-x86_64 \
            -kernel osboot/bzImage \
            -initrd osboot/single.gz \
            -append "console=ttyS0 quiet" \
            -nographic -m 512M \
            -netdev user,id=net0 \
            -device e1000,netdev=net0
        ;;
    --multi)
        echo "[*] Booting multi-user filesystem..."
        qemu-system-x86_64 \
            -kernel osboot/bzImage \
            -initrd osboot/multi.gz \
            -append "console=ttyS0 quiet" \
            -nographic -m 512M \
            -netdev user,id=net0 \
            -device e1000,netdev=net0
        ;;
    --all)
        echo "[*] Booting from ISO..."
        qemu-system-x86_64 \
            -cdrom osboot/farewell.iso \
            -boot d \
            -nographic -m 512M \
            -netdev user,id=net0 \
            -device e1000,netdev=net0
        ;;
    *)
        echo "Usage: ./qemu.sh [--single | --multi | --all]"
        exit 1
        ;;
esac
