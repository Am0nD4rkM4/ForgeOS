#!/usr/bin/env bash
# ForgeOS — constructor de ISO con live-build (Debian 13)
# Uso (en Debian 13, con sudo, ~4 GB libres y buena conexión):
#   sudo bash build-iso.sh
#   # La ISO queda en: live-build/live-image-amd64.hybrid.iso
#
# Esto descarga paquetes de Debian y construye la imagen live.
# Tarda 20-60 minutos según tu conexión y tu CPU. Pruébala en VM (QEMU/VirtualBox)
# antes de instalarla en hardware real.
set -euo pipefail

# --dry-run: solo valida y muestra los pasos, sin apt-get ni lb build.
# Esto permite probar el script en cualquier sitio sin descargar paquetes.
DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    *) echo "Opción desconocida: $arg"; exit 2 ;;
  esac
done
if $DRY_RUN; then
  echo "[dry-run] build-iso: comprobaría root, instalaría live-build/debootstrap,"
  echo "[dry-run] copiaría live-build/ + config/ a /tmp/forgeos-build y ejecutaría lb clean/config/build"
  for f in live-build/auto/config live-build/config/package-lists/forgeos.list.chroot \
           config/i3/config config/alacritty/alacritty.toml scripts/forgeos-quad \
           scripts/forgeos-monitor scripts/forgeos-pantallas scripts/forgeos-sysinfo; do
    [[ -f "$f" ]] || { echo "Falta $f"; exit 1; }
    echo "[dry-run] OK $f"
  done
  exit 0
fi

if [[ $EUID -ne 0 ]]; then
  echo "Ejecuta con sudo: sudo bash build-iso.sh"
  exit 1
fi

apt-get update -qq
apt-get install -y live-build debootstrap squashfs-tools xorriso isolinux syslinux-utils

# Copiar la configuración live-build a un directorio de trabajo limpio
rm -rf /tmp/forgeos-build
mkdir -p /tmp/forgeos-build
cp -a live-build/* /tmp/forgeos-build/
# Incluir las configs de i3/Alacritty en el esqueleto del live
mkdir -p /tmp/forgeos-build/config/includes.chroot/etc/skel/.config
cp -a config/i3 /tmp/forgeos-build/config/includes.chroot/etc/skel/.config/
cp -a config/i3status /tmp/forgeos-build/config/includes.chroot/etc/skel/.config/
cp -a config/alacritty /tmp/forgeos-build/config/includes.chroot/etc/skel/.config/
cp -a config/rofi /tmp/forgeos-build/config/includes.chroot/etc/skel/.config/
cp -a config/picom /tmp/forgeos-build/config/includes.chroot/etc/skel/.config/
cp scripts/forgeos-quad /tmp/forgeos-build/config/includes.chroot/usr/local/bin/
chmod +x /tmp/forgeos-build/config/includes.chroot/usr/local/bin/forgeos-quad
cp scripts/forgeos-monitor /tmp/forgeos-build/config/includes.chroot/usr/local/bin/
chmod +x /tmp/forgeos-build/config/includes.chroot/usr/local/bin/forgeos-monitor
cp scripts/forgeos-pantallas /tmp/forgeos-build/config/includes.chroot/usr/local/bin/
chmod +x /tmp/forgeos-build/config/includes.chroot/usr/local/bin/forgeos-pantallas
cp scripts/forgeos-sysinfo /tmp/forgeos-build/config/includes.chroot/usr/local/bin/
chmod +x /tmp/forgeos-build/config/includes.chroot/usr/local/bin/forgeos-sysinfo

cd /tmp/forgeos-build
lb clean
lb config
lb build

echo "==> ISO generada:"
ls -lh live-image-*.iso
echo "Pruébala con: qemu-system-x86_64 -m 2048 -cdrom live-image-amd64.hybrid.iso -boot d"
