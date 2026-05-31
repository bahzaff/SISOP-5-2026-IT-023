#!/bin/bash

ISO_DIR="iso_build"
OUTPUT="osboot/farewell.iso"

echo "[*] Building bootable ISO..."

rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR/boot/grub"

cp osboot/bzImage "$ISO_DIR/boot/"
cp osboot/single.gz "$ISO_DIR/boot/"
cp osboot/multi.gz "$ISO_DIR/boot/"

cat > "$ISO_DIR/boot/grub/grub.cfg" << 'EOF'
set timeout=10
set default=0

menuentry "Farewell Party - Single User" {
    linux /boot/bzImage quiet
    initrd /boot/single.gz
}

menuentry "Farewell Party - Multi User" {
    linux /boot/bzImage quiet
    initrd /boot/multi.gz
}
EOF

grub-mkrescue -o "$OUTPUT" "$ISO_DIR"

rm -rf "$ISO_DIR"

echo "[+] ISO created! Output: $OUTPUT"
