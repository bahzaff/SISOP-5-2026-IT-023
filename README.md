# SISOP-5-2026-IT-023

# Laporan SISOP Modul 5 - Soal 1: Farewell Party

## Identitas
**Nama:** Barra Ahza Fakhrullah  
**NRP:** 5027251023  

---

## Penjelasan Per Poin

### Poin 1 — Struktur Folder
Folder `soal_1/` dibuat sesuai spesifikasi soal dengan semua script yang diperlukan.

---

### Poin 2 — `kernel.sh` (Compile Linux Kernel 6.1.1)

Script ini bertugas mendownload, mengekstrak, dan mengcompile Linux kernel versi 6.1.1.

**Alur:**
1. Download kernel dari `cdn.kernel.org` jika belum ada
2. Extract tarball
3. Apply patch untuk mengatasi error compile di GCC versi baru
4. Jalankan `make defconfig` sebagai base config
5. Enable config network (virtio, e1000, inet)
6. Compile dengan `make -j$(nproc)`
7. Copy hasil ke `osboot/bzImage` dan `.config`

**Patch yang diperlukan:**
```bash
# Fix format string error di blk-iocost.c
sed -i '3035s/%u/%lu/' block/blk-iocost.c
sed -i '3045s/%u/%lu/' block/blk-iocost.c

# Fix array bounds error di tg3.h
sed -i 's/#define TG3_RSS_MAX_NUM_QS\t\t4/#define TG3_RSS_MAX_NUM_QS\t\t5/' drivers/net/ethernet/broadcom/tg3.h

# Disable driver tg3 dari Makefile
sed -i 's/obj-$(CONFIG_TIGON3)/# obj-$(CONFIG_TIGON3)/' drivers/net/ethernet/broadcom/Makefile
```

**Enable network config:**
```bash
scripts/config --enable CONFIG_VIRTIO
scripts/config --enable CONFIG_VIRTIO_NET
scripts/config --enable CONFIG_VIRTIO_PCI
scripts/config --enable CONFIG_NET
scripts/config --enable CONFIG_INET
scripts/config --enable CONFIG_E1000
make olddefconfig
```

**Output:** `osboot/bzImage`

---

### Poin 3 — `single.sh` (Single-user Filesystem)

Script ini membuat initramfs single-user berbasis BusyBox.

**Spesifikasi:**
- User: `root` (hanya root)
- Directory: `bin/, dev/, proc/, sys/, etc/, tmp/, root/`
- Access: root bisa akses apapun
- Banner: ASCII art "Farewell Party" + `Welcome, <USER>.` saat login

**Setup BusyBox:**
```bash
cp /bin/busybox "$SINGLE_DIR/bin/"
cd "$SINGLE_DIR/bin"
for cmd in $(./busybox --list); do
    ln -sf busybox "$cmd" 2>/dev/null
done
```

**Init script:**
```bash
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
```

**Build filesystem:**
```bash
find . | cpio -oH newc | gzip > "../$OUTPUT"
```

**Output:** `osboot/single.gz`

---

### Poin 4 — `multi.sh` (Multi-user Filesystem)

Script ini membuat initramfs multi-user berbasis BusyBox dengan multiple user dan access control.

**Spesifikasi user:**

| User | Password |
|------|----------|
| root | root123  |
| henn | henn123  |
| hann | hann123  |
| viii | viii123  |
| kids | kids123  |

**Access control:**

| Directory | Permission | Keterangan |
|-----------|-----------|------------|
| `/root` | 700 | root only |
| `/home/henn` | 700 | henn only |
| `/home/hann` | 770 (group: grp_hann) | hann, viii, kids |
| `/home/viii` | 770 (group: grp_viii) | viii, kids |
| `/home/kids` | 770 (group: grp_kids) | kids only |
| `/tmp` | 1777 | semua user |

**Setup /etc/passwd:**
```bash
cat > "$MULTI_DIR/etc/passwd" << 'EOF'
root:x:0:0:root:/root:/bin/sh
henn:x:1000:1000:henn:/home/henn:/bin/sh
hann:x:1001:1001:hann:/home/hann:/bin/sh
viii:x:1002:1002:viii:/home/viii:/bin/sh
kids:x:1003:1003:kids:/home/kids:/bin/sh
EOF
```

**Setup /etc/shadow (password di-hash openssl):**
```bash
hash_pass() { openssl passwd -6 "$1"; }
cat > "$MULTI_DIR/etc/shadow" << EOF
root:$(hash_pass root123):0:0:99999:7:::
henn:$(hash_pass henn123):0:0:99999:7:::
...
EOF
```

**Setup /etc/group:**
```bash
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
```

**Setup ownership dan permission via fakeroot:**
```bash
fakeroot bash << FAKEROOT
cd multi_fs
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
find . | cpio -oH newc | gzip > "../osboot/multi.gz"
FAKEROOT
```

> **Catatan limitasi:** Karena BusyBox tidak support POSIX ACL, access control asimetris (misal hann bisa akses viii tapi viii tidak bisa akses hann) tidak dapat diimplementasi penuh. Diselesaikan secara best-effort dengan group workaround.

**Output:** `osboot/multi.gz`

---

### Poin 5 — `iso.sh` (Bootable ISO)

Script ini membuat ISO bootable yang bisa load kedua filesystem.

**GRUB config:**
```bash
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
```

**Generate ISO:**
```bash
grub-mkrescue -o "$OUTPUT" "$ISO_DIR"
```

**Output:** `osboot/farewell.iso`

---

### Poin 6 — `qemu.sh` (Boot via QEMU)

Script ini menjalankan QEMU dengan 3 mode boot.

| Command | Fungsi |
|---------|--------|
| `./qemu.sh --single` | Boot langsung ke single-user filesystem |
| `./qemu.sh --multi` | Boot langsung ke multi-user filesystem |
| `./qemu.sh --all` | Boot dari ISO, pilih via menu GRUB |

**Contoh implementasi `--single`:**
```bash
qemu-system-x86_64 \
    -kernel osboot/bzImage \
    -initrd osboot/single.gz \
    -append "console=ttyS0 quiet" \
    -nographic -m 512M \
    -netdev user,id=net0 \
    -device e1000,netdev=net0
```

---

### Poin 7 — `backup.sh` (Backup Hasil Build)

Script ini mengzip semua file hasil build ke dalam satu file arsip.

**Format nama:** `farewell_backup_[DDMMYYYY-HHMMSS].zip`

```bash
TIMESTAMP=$(date +"%d%m%Y-%H%M%S")
OUTPUT="osboot/farewell_backup_[${TIMESTAMP}].zip"

zip "$OUTPUT" \
    osboot/bzImage \
    osboot/single.gz \
    osboot/multi.gz \
    osboot/farewell.iso
```

**Output:** `osboot/farewell_backup_[DDMMYYYY-HHMMSS].zip`

---

### Poin 8 — Akses Internet

OS berhasil mengakses internet via QEMU user-mode networking.

**Setup network di dalam OS:**
```sh
ip link set eth0 up
ip addr add 10.0.2.15/24 dev eth0
ip route add default via 10.0.2.2
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

**Test:**
```sh
wget -O- http://example.com
# Output: HTML dari example.com berhasil didownload
```

> **Catatan:** ICMP ping diblock oleh QEMU user-mode networking (limitasi QEMU, bukan OS). Koneksi TCP/HTTP berjalan normal dibuktikan dengan `wget example.com` berhasil.

---

### Poin 9 — Package Manager `party` ⚠️ BELUM SELESAI

> **Notes:** Package manager bernama `party` belum diimplementasi. Sesuai soal, `party` harus bisa install package dan binary-nya dinamai `party`. Rencana implementasi: wrapper script berbasis `apk` atau custom downloader script yang di-include ke dalam filesystem.

---

### Poin 10 — FUSE ⚠️ BELUM SELESAI

> **Notes:** Instalasi FUSE dan pembuatan program FUSE sederhana belum diimplementasi. Sesuai soal, OS harus bisa menjalankan program FUSE sebagai bukti package manager berjalan dan OS support FUSE filesystem.

---

## Kendala

1. **Compile kernel gagal** — GCC versi baru di WSL lebih strict, ada beberapa error format string dan array bounds yang perlu dipatch manual di source kernel sebelum compile.
2. **ICMP ping tidak berfungsi** — Limitasi QEMU user-mode networking yang memblock ICMP. Solusi: gunakan `wget` untuk test koneksi.
3. **Access control asimetris** — BusyBox tidak support POSIX ACL sehingga permission model asimetris antar user tidak bisa diimplementasi penuh. Diselesaikan secara best-effort dengan group workaround.
4. **chown di WSL** — `chown` tidak bisa set ownership dengan benar di WSL tanpa root/fakeroot. Diselesaikan dengan menggunakan `fakeroot` saat build filesystem.

## Kendala

1. **Compile kernel gagal** — GCC versi baru di WSL lebih strict, ada beberapa error format string dan array bounds yang perlu dipatch manual di source kernel sebelum compile.
2. **ICMP ping tidak berfungsi** — Bukan masalah OS, melainkan limitasi QEMU user-mode networking yang memblock ICMP. Solusi: gunakan `wget` untuk test koneksi.
3. **Access control asimetris** — BusyBox tidak support POSIX ACL sehingga permission model asimetris antar user tidak bisa diimplementasi penuh. Diselesaikan secara best-effort dengan group workaround.
4. **chown di WSL** — `chown` tidak bisa set ownership dengan benar di WSL tanpa root/fakeroot. Diselesaikan dengan menggunakan `fakeroot` saat build filesystem.


## SOAL 2

Program kernel OS 16-bit dibuat menggunakan dua file utama yaitu `kernel.asm` dan `kernel.c`. `kernel.asm` mengimplementasikan fungsi `_getChar` menggunakan BIOS interrupt untuk membaca input keyboard, sedangkan `kernel.c` mengimplementasikan seluruh fungsi utilitas dan command handler untuk shell sederhana yang berjalan di atas sistem 16-bit.

`Poin 1 - Implementasi _getChar pada kernel.asm`

Fungsi `_getChar` diimplementasikan menggunakan BIOS interrupt `INT 16h` dengan `AH=0` yang akan menunggu sampai ada keypress lalu mengembalikan ASCII character di register `AL`. `AH` di-clear sebelum return agar nilai yang dikembalikan hanya ASCII code-nya saja.
```asm
_getChar:
    push bp
    mov bp, sp

    xor ah, ah      ; BIOS INT 16h function 00h = wait for keypress
    int 0x16        ; AL = ASCII character

    xor ah, ah      ; zero out AH, return ASCII code in AX
    pop bp
    ret
```

`Poin 2 - printChar dan printString`

`printChar` menulis karakter beserta atribut warna langsung ke VGA memory di segment `0xB800`. Setiap cell terdiri dari 2 byte yaitu karakter dan atribut warna. `printString` melakukan loop `printChar` untuk setiap karakter sampai null terminator.
```c
void printChar(char c) {
    putInMemory(0xB800, cursor * 2,     c);
    putInMemory(0xB800, cursor * 2 + 1, color);
    cursor++;
}

void printString(char *s) {
    int i = 0;
    while (s[i] != '\0') {
        printChar(s[i]);
        i++;
    }
}
```

`Poin 3 - clearScreen`

`clearScreen` mengisi seluruh 2000 cell VGA memory (80x25) dengan spasi dan atribut default `0x07`, lalu mereset cursor ke posisi 0 dan warna ke default.
```c
void clearScreen() {
    int i;
    for (i = 0; i < 2000; i++) {
        putInMemory(0xB800, i * 2,     ' ');
        putInMemory(0xB800, i * 2 + 1, 0x07);
    }
    cursor = 0;
    color  = 0x07;
}
```

`Poin 4 - readString`

`readString` membaca input karakter per karakter menggunakan `getChar()`. Mendukung backspace untuk menghapus karakter terakhir dan berhenti ketika karakter enter (`\r` atau `\n`) diterima.
```c
void readString(char *buf) {
    int  i = 0;
    char c;
    while (1) {
        c = getChar();
        if (c == '\r' || c == '\n') { buf[i] = '\0'; return; }
        if (c == '\b') {
            if (i > 0) {
                i--; cursor--;
                putInMemory(0xB800, cursor * 2,     ' ');
                putInMemory(0xB800, cursor * 2 + 1, color);
            }
            continue;
        }
        buf[i] = c; i++;
        printChar(c);
    }
}
```

`Poin 5 - strcmp dan startsWith`

`strcmp` membandingkan dua string karakter per karakter dan mengembalikan 1 jika sama. `startsWith` mengecek apakah string `s` diawali dengan `prefix`, digunakan untuk parsing command yang memiliki argumen.
```c
int strcmp(char *a, char *b) {
    int i = 0;
    while (a[i] != '\0' && b[i] != '\0') {
        if (a[i] != b[i]) return 0;
        i++;
    }
    return (a[i] == '\0' && b[i] == '\0');
}

int startsWith(char *s, char *prefix) {
    int i = 0;
    while (prefix[i] != '\0') {
        if (s[i] != prefix[i]) return 0;
        i++;
    }
    return 1;
}
```

`Poin 6 - atoi dan intToString`

`atoi` mengkonversi string ke integer tanpa menggunakan stdlib. `intToString` mengkonversi integer ke string tanpa menggunakan operator `/` atau `%`, melainkan menggunakan repeated subtraction untuk mendapatkan digit dan quotient secara manual sesuai restriction soal.
```c
int atoi(char *s) {
    int result = 0, sign = 1, i = 0;
    while (s[i] == ' ') i++;
    if (s[i] == '-') { sign = -1; i++; }
    while (s[i] >= '0' && s[i] <= '9') {
        result = result * 10 + (s[i] - '0');
        i++;
    }
    return result * sign;
}

void intToString(int n, char *buf) {
    char tmp[7];
    int count = 0, i, j, neg = 0, rem, q;
    if (n == 0) { buf[0] = '0'; buf[1] = '\0'; return; }
    if (n < 0)  { neg = 1; n = -n; }
    while (n > 0) {
        rem = n; q = 0;
        while (rem >= 10) { rem -= 10; q++; }
        tmp[count] = '0' + rem;
        count++; n = q;
    }
    i = 0;
    if (neg) { buf[i] = '-'; i++; }
    j = count;
    while (j > 0) { j--; buf[i] = tmp[j]; i++; }
    buf[i] = '\0';
}
```

`Poin 7 - factorial dengan overflow check`

`factorial` menghitung faktorial secara iteratif. Karena sistem 16-bit dengan signed integer maksimal 32767, jika hasil perkalian menjadi negatif (overflow) maka fungsi mengembalikan -1 sebagai tanda overflow dan command handler akan mencetak pesan `"know your limit little bro."`.
```c
int factorial(int n) {
    int result = 1, i;
    if (n < 0) return -1;
    for (i = 2; i <= n; i++) {
        result = result * i;
        if (result < 0) return -1;
    }
    return result;
}
```

`Poin 8 - season handler (color)`

Command `season` mengubah global variabel `color` sesuai musim yang dipilih. Setiap musim memiliki warna VGA text attribute yang berbeda sehingga seluruh output setelahnya akan tampil dengan warna tersebut.
```c
} else if (startsWith(cmd, "season ")) {
    parseStr(cmd, arg);
    if      (strcmp(arg, "winter"))  { color = 0x0B; printString("winter mode");  }
    else if (strcmp(arg, "spring"))  { color = 0x0A; printString("spring mode");  }
    else if (strcmp(arg, "summer"))  { color = 0x0E; printString("summer mode");  }
    else if (strcmp(arg, "fall"))    { color = 0x0C; printString("fall mode");    }
    else if (strcmp(arg, "radiant")) { color = 0x0D; printString("radiant mode"); }
    else                             { printString("unknown season");              }
}
```

`Poin 9 - triangle handler`

Command `triangle <n>` mencetak segitiga dari karakter `x` dengan baris ke-i memiliki i buah karakter x, dari baris 1 sampai n.
```c
void printTriangle(int n) {
    int i, j;
    for (i = 1; i <= n; i++) {
        for (j = 0; j < i; j++) printChar('x');
        newline();
    }
}
```

`Poin 10 - add, sub, fac, clear, help, check handler`

Seluruh command handler diimplementasikan di dalam shell loop `while(1)` menggunakan `strcmp` untuk exact match dan `startsWith` untuk command dengan argumen. Command `clear` mereset layar dan langsung `continue` agar tidak mencetak newline tambahan.
```c
if      (strcmp(cmd, "check"))        { printString("ok"); }
else if (strcmp(cmd, "help"))         { printString("check add sub fac season triangle clear about"); }
else if (startsWith(cmd, "add "))     { parseTwoInts(cmd, &a, &b); intToString(a+b, numStr); printString(numStr); }
else if (startsWith(cmd, "sub "))     { parseTwoInts(cmd, &a, &b); intToString(a-b, numStr); printString(numStr); }
else if (startsWith(cmd, "fac "))     { parseOneInt(cmd, &a); res = factorial(a);
                                        if (res == -1) printString("know your limit little bro.");
                                        else { intToString(res, numStr); printString(numStr); } }
else if (strcmp(cmd, "clear"))        { clearScreen(); continue; }
```

**OUTPUT SOAL 2**

`check dan help`

![output check help](assets/check_help.png)

`add dan sub`

![output add sub](assets/add_sub.png)

`fac normal dan overflow`

![output fac](assets/fac.png)

`season - perubahan warna`

![output season](assets/season.png)

`triangle`

![output triangle](assets/triangle.png)

`clear`

![output clear](assets/clear.png)

**KENDALA**

tidak ada kendala
