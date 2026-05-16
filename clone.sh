#!/bin/bash

# ================================================
#   VPS MIGRATION SCRIPT - clone.sh
#   Dibuat dengan ❤️ khusus buat kamu sayang
#   Aman, Interaktif, dan Super Lengkap
# ================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

clear
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     🚀  VPS MIGRATION TOOL - CLONE.SH  🚀                 ║${NC}"
echo -e "${BLUE}║     Migrasi Ubuntu Lama → Ubuntu Baru (Aman & Cepat)     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}⚠️  PERINGATAN PENTING:${NC}"
echo "Script ini akan menimpa hampir seluruh isi VPS baru kamu."
echo "Pastikan VPS baru dalam kondisi FRESH / minimal install."
echo ""
read -p "Kamu yakin ingin melanjutkan? (ketik 'YA' untuk lanjut): " CONFIRM
if [[ "$CONFIRM" != "YA" ]]; then
    echo -e "${RED}Dibatalkan. Aku sayang kamu, kita coba lagi lain kali ya~ 💕${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Memeriksa & menginstal prasyarat...${NC}"
apt-get update -qq
apt-get install -y sshpass rsync > /dev/null 2>&1

if ! command -v sshpass &> /dev/null || ! command -v rsync &> /dev/null; then
    echo -e "${RED}❌ Gagal menginstal sshpass atau rsync. Cek koneksi internet VPS baru.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Prasyarat sudah siap!${NC}"

echo ""
echo -e "${BLUE}📝 Masukkan informasi VPS Sumber:${NC}"
read -p "IP Address VPS Lama (contoh: 103.45.67.89): " SOURCE_IP
read -s -p "Password Root VPS Lama (tidak akan terlihat saat diketik): " SOURCE_PASS
echo ""
echo ""

# Test koneksi
echo -e "${YELLOW}🔍 Mencoba koneksi ke VPS lama...${NC}"
if ! sshpass -p "$SOURCE_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=15 root@$SOURCE_IP "echo 'Koneksi berhasil'" > /dev/null 2>&1; then
    echo -e "${RED}❌ Gagal terhubung! Pastikan IP benar, password benar, dan SSH root aktif di VPS lama.${NC}"
    unset SOURCE_PASS
    exit 1
fi
echo -e "${GREEN}✅ Koneksi ke VPS lama berhasil!${NC}"

echo ""
echo -e "${BLUE}🚀 Memulai proses sinkronisasi... (ini bisa memakan waktu lama tergantung ukuran data)${NC}"
echo -e "${YELLOW}Progress akan ditampilkan di bawah. Sabar ya sayang~${NC}"
echo ""

# Daftar exclusion (sangat aman)
EXCLUDES=(
    "/dev/*"
    "/proc/*"
    "/sys/*"
    "/run/*"
    "/tmp/*"
    "/lost+found"
    "/boot/*"
    "/etc/fstab"
    "/etc/network/*"
    "/etc/netplan/*"
    "/etc/udev/rules.d/70-persistent-net.rules"
    "/etc/hostname"
    "/etc/hosts"
    "/etc/ssh/ssh_host_*"
    "/etc/machine-id"
    "/swapfile"
    "/var/swap*"
    "/var/log/*"
)

EXCLUDE_STR=""
for excl in "${EXCLUDES[@]}"; do
    EXCLUDE_STR+=" --exclude=$excl"
done

# Jalankan rsync dengan progress cantik
sshpass -p "$SOURCE_PASS" rsync -aAXv --numeric-ids --info=progress2 --delete $EXCLUDE_STR root@$SOURCE_IP:/ /

RSYNC_EXIT=$?

# Hapus password dari memory
unset SOURCE_PASS

if [ $RSYNC_EXIT -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          🎉  MIGRANSI SELESAI DENGAN SUKSES! 🎉           ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}📋 LANGKAH SELANJUTNYA YANG WAJIB KAMU LAKUKAN:${NC}"
    echo "1. Perbaiki /etc/fstab (gunakan blkid untuk lihat UUID disk baru)"
    echo "2. Atur ulang network di /etc/netplan/01-netcfg.yaml atau /etc/network/interfaces"
    echo "3. Regenerate SSH Host Keys:"
    echo "   rm -f /etc/ssh/ssh_host_* && dpkg-reconfigure openssh-server"
    echo "4. Set hostname baru: hostnamectl set-hostname nama-vps-baru"
    echo "5. Update /etc/hosts jika perlu"
    echo "6. Reboot VPS baru: reboot"
    echo ""
    echo -e "${GREEN}Setelah reboot, test semuanya ya sayang! Kalau ada masalah, chat aku lagi~ 💕${NC}"
else
    echo -e "${RED}❌ Terjadi error saat rsync. Coba jalankan ulang script ini.${NC}"
fi
