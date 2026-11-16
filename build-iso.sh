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
# set -euo pipefail: "si algo falla, para el script en seco".
# -e = si un comando da error, el script se detiene. -u = si se usa una
# variable que no existe, da error. -o pipefail = si algo falla dentro
# de una tubería (|), también cuenta como error.

# --dry-run: solo valida y muestra los pasos, sin apt-get ni lb build.
# Esto permite probar el script en cualquier sitio sin descargar paquetes.
DRY_RUN=false
# DRY_RUN=false: un interruptor que empieza apagado. Con --dry-run solo
# dice lo que haría y comprueba que existen los archivos, sin construir nada.
for arg in "$@"; do
  # for arg in "$@": repasa cada argumento que le pasaste al script.
  # "$@" son todos esos argumentos, y en cada vuelta arg vale uno distinto.
  case "$arg" in
    # case "$arg" in: mira qué vale arg y salta a la rama que coincida.
    # ;; significa "fin de esta rama". *: "cualquier otra cosa".
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
  # $EUID es el número de usuario que corre el script: 0 es root.
  # -ne 0 significa "distinto de 0", o sea, "no eres root". Construir
  # una ISO necesita ser root, por eso se pide sudo.
  echo "Ejecuta con sudo: sudo bash build-iso.sh"
  exit 1
  # exit 1: sale del script con código 1, que significa "hubo un error".
fi

apt-get update -qq
apt-get install -y live-build debootstrap squashfs-tools xorriso isolinux syslinux-utils
# apt-get install: instala las herramientas para construir la ISO. -y es
# "sí a todo, no preguntes". live-build = el constructor de ISOs de Debian.
# debootstrap = descarga un Debian mínimo desde cero. squashfs-tools =
# comprime el sistema en la ISO. xorriso/isolinux/syslinux-utils = hacen
# que la ISO pueda arrancar desde un USB o un CD.

# Copiar la configuración live-build a un directorio de trabajo limpio
rm -rf /tmp/forgeos-build
# rm -rf /tmp/forgeos-build: borra la carpeta de trabajo anterior, si la
# había, para empezar limpio. -r = con todo lo de dentro. -f = sin preguntar.
mkdir -p /tmp/forgeos-build
# mkdir -p /tmp/forgeos-build: crea la carpeta de trabajo limpia.
cp -a live-build/* /tmp/forgeos-build/
# cp -a: copia todo lo de live-build/ a la carpeta de trabajo, con permisos
# y fechas incluidos (-a = "tal cual, archivo por archivo").
# Incluir las configs de i3/Alacritty en el esqueleto del live
# /etc/skel es la carpeta "molde": todo lo que se pone ahí, Debian se lo
# copia a cada usuario nuevo cuando se crea. Por eso las configs de i3,
# i3status, Alacritty, rofi y picom van ahí: así el usuario del live ya
# arranca con ForgeOS puesto. Los scripts van a /usr/local/bin, que es
# donde van los programas que instalas tú a mano, y chmod +x los hace ejecutables.
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
# cd /tmp/forgeos-build: entra a la carpeta de trabajo, porque los comandos
# lb (live-build) trabajan sobre la carpeta en la que estás.
lb clean
# lb clean: limpia cualquier resto de una construcción anterior.
lb config
# lb config: lee la configuración de live-build y la prepara.
lb build
# lb build: construye la ISO de verdad: descarga Debian, instala los
# paquetes, mete tus configs y empaqueta todo en un archivo .iso.
# Tarda 20-60 minutos según tu conexión y tu CPU.

echo "==> ISO generada:"
ls -lh live-image-*.iso
# ls -lh live-image-*.iso: lista la ISO que se generó, con su tamaño
# en forma legible (-h = "human", por ejemplo 2,1G). El * es "cualquier
# texto": live-image-*.iso casa con live-image-amd64.hybrid.iso.
echo "Pruébala con: qemu-system-x86_64 -m 2048 -cdrom live-image-amd64.hybrid.iso -boot d"
# qemu-system-x86_64 es una máquina virtual por línea de comandos: -m 2048
# le da 2048 MB de RAM, -cdrom le mete la ISO como si fuera un CD, y
# -boot d le dice "arranca desde ese CD". Así la pruebas sin tocar tu PC.
