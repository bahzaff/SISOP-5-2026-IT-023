# SISOP-5-2026-IT-023

# Laporan SISOP Modul 5 - Soal 1: Farewell Party

## Identitas
**Nama:** Barra Ahza Fakhrullah  
**NRP:** 5027251023  
**Repo:** SISOP-5-2026-IT-023

---


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
3. Apply patch untuk mengatasi error compile di GCC versi baru:
   - `block/blk-iocost.c` — fix format string `%u` → `%lu`
   - `drivers/net/ethernet/broadcom/tg3.h` — naikkan `TG3_RSS_MAX_NUM_QS` dari 4 → 5
4. Jalankan `make defconfig` sebagai base config
5. Enable config network (virtio, e1000, inet)
6. Compile dengan `make -j$(nproc)`
7. Copy hasil `bzImage` ke `osboot/bzImage`
8. Copy `.config` ke `soal_1/.config`

**Output:** `osboot/bzImage`

---

### Poin 3 — `single.sh` (Single-user Filesystem)

Script ini membuat initramfs single-user berbasis BusyBox.

**Spesifikasi:**
- User: `root` (hanya root)
- Directory: `bin/, dev/, proc/, sys/, etc/, tmp/, root/`
- Access: root bisa akses apapun
- Banner: ASCII art "Farewell Party" + `Welcome, <USER>.` saat login

**Alur:**
1. Buat struktur direktori
2. Copy BusyBox dan buat symlink semua command
3. Buat `/etc/profile` dengan banner ASCII art
4. Buat `/init` script yang mount proc/sys/dev lalu exec `/bin/sh`
5. Pack dengan `cpio` dan compress dengan `gzip`

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

**Implementasi:**
- `/etc/passwd`, `/etc/shadow` (password di-hash dengan `openssl passwd -6`), `/etc/group` dibuat manual
- Ownership diset menggunakan `fakeroot` agar bisa chown tanpa root di WSL
- Group `grp_hann`, `grp_viii`, `grp_kids` dibuat untuk mengatur akses antar user
- Banner ASCII art + `Welcome, <USER>.` muncul saat login via `/etc/profile`

> **Catatan limitasi:** Karena BusyBox tidak support POSIX ACL, access control yang bersifat asimetris (misal hann bisa akses viii tapi viii tidak bisa akses hann) tidak dapat diimplementasi penuh dengan permission bit standar. Implementasi dilakukan secara best-effort dengan group workaround.

**Output:** `osboot/multi.gz`

---

### Poin 5 — `iso.sh` (Bootable ISO)

Script ini membuat ISO bootable yang bisa load kedua filesystem (single dan multi).

**Alur:**
1. Buat struktur `iso_build/boot/grub/`
2. Copy `bzImage`, `single.gz`, `multi.gz` ke dalam ISO
3. Buat `grub.cfg` dengan 2 menu entry: Single User dan Multi User
4. Generate ISO dengan `grub-mkrescue`

**Output:** `osboot/farewell.iso`

---

### Poin 6 — `qemu.sh` (Boot via QEMU)

Script ini menjalankan QEMU dengan 3 mode boot.

| Command | Fungsi |
|---------|--------|
| `./qemu.sh --single` | Boot langsung ke single-user filesystem |
| `./qemu.sh --multi` | Boot langsung ke multi-user filesystem |
| `./qemu.sh --all` | Boot dari ISO, pilih via menu GRUB |

Network menggunakan QEMU user-mode networking dengan device `e1000`.

---

### Poin 7 — `backup.sh` (Backup Hasil Build)

Script ini mengzip semua file hasil build ke dalam satu file arsip.

**Format nama:** `farewell_backup_[DDMMYYYY-HHMMSS].zip`

**File yang dibackup:**
- `osboot/bzImage`
- `osboot/single.gz`
- `osboot/multi.gz`
- `osboot/farewell.iso`

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
- `ping 8.8.8.8` — ICMP diblock oleh QEMU user-mode (limitasi QEMU, bukan OS)
- `wget example.com` — **BERHASIL**, koneksi HTTP keluar

> **Catatan:** ICMP ping tidak bisa digunakan di QEMU user-mode networking karena QEMU memblock ICMP. Koneksi TCP/HTTP berjalan normal dibuktikan dengan `wget example.com` berhasil.

---

### Poin 9 — Package Manager `party` ⚠️ BELUM SELESAI

> **Notes:** Package manager bernama `party` belum diimplementasi. Sesuai soal, `party` harus bisa install package dan binary-nya dinamai `party`. Rencana implementasi: wrapper script berbasis `apk` (Alpine Package Manager) atau custom downloader script.

---

### Poin 10 — FUSE ⚠️ BELUM SELESAI

> **Notes:** Instalasi FUSE dan pembuatan program FUSE sederhana belum diimplementasi. Sesuai soal, OS harus bisa menjalankan program FUSE sebagai bukti package manager berjalan dan OS support FUSE filesystem.

---

## Kendala

1. **Compile kernel gagal** — GCC versi baru di WSL lebih strict, ada beberapa error format string dan array bounds yang perlu dipatch manual di source kernel sebelum compile.
2. **ICMP ping tidak berfungsi** — Bukan masalah OS, melainkan limitasi QEMU user-mode networking yang memblock ICMP. Solusi: gunakan `wget` untuk test koneksi.
3. **Access control asimetris** — BusyBox tidak support POSIX ACL sehingga permission model asimetris antar user tidak bisa diimplementasi penuh. Diselesaikan secara best-effort dengan group workaround.
4. **chown di WSL** — `chown` tidak bisa set ownership dengan benar di WSL tanpa root/fakeroot. Diselesaikan dengan menggunakan `fakeroot` saat build filesystem.
