#!/bin/bash

MULTI_DIR="multi_fs"
OUTPUT="osboot/multi.gz"

echo "[*] Building multi-user filesystem..."

rm -rf "$MULTI_DIR"
mkdir -p "$MULTI_DIR"/{bin,dev,proc,sys,etc,tmp,root}
mkdir -p "$MULTI_DIR"/home/{henn,hann,viii,kids}

# BusyBox
cp /bin/busybox "$MULTI_DIR/bin/"
cd "$MULTI_DIR/bin"
for cmd in $(./busybox --list); do
    ln -sf busybox "$cmd" 2>/dev/null
done
cd - > /dev/null

# /etc/passwd
cat > "$MULTI_DIR/etc/passwd" << 'EOF'
root:x:0:0:root:/root:/bin/sh
henn:x:1000:1000:henn:/home/henn:/bin/sh
hann:x:1001:1001:hann:/home/hann:/bin/sh
viii:x:1002:1002:viii:/home/viii:/bin/sh
kids:x:1003:1003:kids:/home/kids:/bin/sh
EOF

# /etc/shadow
hash_pass() { openssl passwd -6 "$1"; }
cat > "$MULTI_DIR/etc/shadow" << EOF
root:$(hash_pass root123):0:0:99999:7:::
henn:$(hash_pass henn123):0:0:99999:7:::
hann:$(hash_pass hann123):0:0:99999:7:::
viii:$(hash_pass viii123):0:0:99999:7:::
kids:$(hash_pass kids123):0:0:99999:7:::
EOF

# /etc/group
cat > "$MULTI_DIR/etc/group" << 'EOF'
root:x:0:root
henn:x:1000:henn
hann:x:1001:hann
viii:x:1002:viii
kids:x:1003:kids
grp_hann:x:2001:hann,viii,kids
grp_viii:x:2002:viii,kids
grp_kids:x:2003:kids
EOF

# Banner
cat > "$MULTI_DIR/etc/profile" << 'EOF'
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

# inittab
cat > "$MULTI_DIR/etc/inittab" << 'EOF'
::sysinit:/bin/mount -t proc none /proc
::sysinit:/bin/mount -t sysfs none /sys
::sysinit:/bin/mdev -s
::respawn:/bin/login
EOF

# init
cat > "$MULTI_DIR/init" << 'EOF'
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev 2>/dev/null || mdev -s
exec /bin/init
EOF
chmod +x "$MULTI_DIR/init"

# Build
fakeroot bash << FAKEROOT
cd "$MULTI_DIR"

chown -R 0:0 .
chown -R 1000:1000 home/henn
chown -R 1001:2001 home/hann
chown -R 1002:2002 home/viii
chown -R 1003:2003 home/kids
chown 0:0 root

chmod 700 root
chmod 700 home/henn
chmod 770 home/hann
chmod 770 home/viii
chmod 770 home/kids
chmod 1777 tmp

find . | cpio -oH newc | gzip > "../$OUTPUT"
FAKEROOT

cd ..
rm -rf "$MULTI_DIR"
echo "[+] Multi-user filesystem done! Output: $OUTPUT"
