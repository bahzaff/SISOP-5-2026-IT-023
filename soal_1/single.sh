#!/bin/bash

SINGLE_DIR="single_fs"
OUTPUT="osboot/single.gz"

echo "[*] Building single-user filesystem..."

rm -rf "$SINGLE_DIR"
mkdir -p "$SINGLE_DIR"/{bin,dev,proc,sys,etc,tmp,root}

# BusyBox
cp /bin/busybox "$SINGLE_DIR/bin/"
cd "$SINGLE_DIR/bin"
for cmd in $(./busybox --list); do
    ln -sf busybox "$cmd" 2>/dev/null
done
cd - > /dev/null

# Banner
cat > "$SINGLE_DIR/etc/profile" << 'EOF'
cat << 'BANNER'
  _____                                _ _   ____            _
 |  ___|_ _ _ __ _____      _____| | | |  _ \ __ _ _ __| |_ _   _
 | |_ / _` | '__/ _ \ \ /\ / / _ \ | | | |_) / _` | '__| __| | | |
 |  _| (_| | | |  __/\ V  V /  __/ | | |  __/ (_| | |  | |_| |_| |
 |_|  \__,_|_|  \___| \_/\_/ \___| |_| |_|   \__,_|_|   \__|\__, |
                                                                |___/
BANNER
echo "Welcome, $(whoami)."
EOF

# init
cat > "$SINGLE_DIR/init" << 'EOF'
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev 2>/dev/null || mdev -s

export HOME=/root
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

. /etc/profile

exec /bin/sh
EOF
chmod +x "$SINGLE_DIR/init"

# Build
cd "$SINGLE_DIR"
find . | cpio -oH newc | gzip > "../$OUTPUT"
cd ..

rm -rf "$SINGLE_DIR"

echo "[+] Single-user filesystem done! Output: $OUTPUT"
