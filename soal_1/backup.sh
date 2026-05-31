#!/bin/bash

TIMESTAMP=$(date +"%d%m%Y-%H%M%S")
OUTPUT="osboot/farewell_backup_[${TIMESTAMP}].zip"

echo "[*] Backing up build results..."

zip "$OUTPUT" \
    osboot/bzImage \
    osboot/single.gz \
    osboot/multi.gz \
    osboot/farewell.iso

echo "[+] Backup done! Output: $OUTPUT"
