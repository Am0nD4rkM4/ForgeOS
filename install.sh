#!/usr/bin/env bash
# ForgeOS — instalador local
# Transforma un Debian 13 mínimo (netinst sin escritorio) en ForgeOS: Debian + i3.
# Uso:
#   sudo bash install.sh            # instalación completa
#   sudo bash install.sh --dry-run  # solo muestra lo que haría, sin instalar
#   sudo bash install.sh --no-infoforge  # sin clonar InfoForge
#
# Requiere: Debian 13 Trixie, conexión a internet, sudo.
# NO lo ejecutes en tu sistema principal sin probarlo antes en una VM.
set -euo pipefail
# set -euo pipefail: "si algo falla, para el script en seco".
# -e = si un comando da error, el script se detiene (no sigue a ciegas).
# -u = si se usa una variable que no existe, da error en vez de usarla vacía.
# -o pipefail = si algo falla dentro de una tubería (|), también cuenta como error.

DRY_RUN=false
NO_INFOFORGE=false
# DRY_RUN=false: dos interruptores que empiezan apagados. DRY_RUN es el
# modo "ensayo": si se enciende con --dry-run, el script solo dice lo que
# haría, sin instalar nada. NO_INFOFORGE es "no clonar InfoForge".
for arg in "$@"; do
  # for arg in "$@": repasa cada argumento que le pasaste al script en la
  # terminal, por ejemplo "sudo bash install.sh --dry-run". "$@" son todos
  # esos argumentos, y en cada vuelta arg vale uno distinto.
  case "$arg" in
    # case "$arg" in: mira qué vale arg y salta a la rama que coincida,
    # como el switch de C# o muchos if/else. ;; significa "fin de esta rama".
    --dry-run) DRY_RUN=true ;;
    --no-infoforge) NO_INFOFORGE=true ;;
    *) echo "Opción desconocida: $arg"; exit 2 ;;
    # *: "cualquier otra cosa": si el argumento no es ninguno de los dos
    # conocidos, avisa y sale con código 2 (error).
  esac
done

run() {
  # run() es una función auxiliar que tú creaste: "corre este comando, o
  # solo dilo si estamos en modo ensayo". "$@" son los argumentos que le
  # pases a run, y "$*" es lo mismo pero pegado en un solo texto.
  if $DRY_RUN; then echo "[dry-run] $*"; else "$@"; fi
  # Si DRY_RUN está encendido, solo imprime "[dry-run] comando...".
  # Si no, ejecuta el comando de verdad con "$@".
}
log() { echo "==> $*"; }
# log() es otra función auxiliar: imprime un título con ==> delante,
# para que se vean los pasos en la terminal.

if [[ $EUID -ne 0 && $DRY_RUN == false ]]; then
  # if [[ ... ]]: si se cumple esto, haz lo de dentro.
  # $EUID es el número de usuario que corre el script: 0 es root (administrador).
  # -ne 0 significa "distinto de 0", o sea, "no eres root".
  # && significa "y además". O sea: "si no eres root Y no es un ensayo".
  echo "Ejecuta con sudo: sudo bash install.sh"
  exit 1
  # exit 1: sale del script con código 1, que significa "hubo un error".
  # Instalar paquetes necesita ser root, por eso se pide sudo.
fi

log "ForgeOS — Debian 13 + i3"
log "1/6 Actualizando apt..."
# apt-get update: le pide a Debian la lista nueva de paquetes disponibles.
# -qq es "muy callado": que no llene la terminal de texto.
run apt-get update -qq
run apt-get install -y -qq curl git sudo
# apt-get install: instala paquetes. -y es "sí a todo, no preguntes".
# curl = para descargar cosas de internet. git = para clonar repos.
# sudo = para poder hacer cosas de administrador como tu usuario.

log "2/6 Instalando Xorg, i3 y utilidades..."
# La barra \ al final de cada línea significa "esta lista sigue en la
# línea siguiente": es un solo comando apt-get install, partido en
# varias líneas para que se pueda leer.
# Qué es cada cosa: xorg/xinit = el sistema gráfico. lightdm = la pantalla
# de login. i3 = el escritorio en mosaico. i3status = la barra de arriba.
# i3lock = bloquear pantalla. dmenu/rofi = lanzadores de programas.
# picom = transparencias y sombras. nitrogen = fondo de pantalla.
# alacritty = la terminal. tmux = varias terminales en una. neovim = editor.
# htop/btop = ver CPU y RAM. fastfetch = datos del sistema. wget/unzip/zip =
# descargar y comprimir. fonts-* = las letras. network-manager = el Wi-Fi.
# blueman = Bluetooth. pavucontrol = volumen. pipewire-audio = el sonido.
# brightnessctl = brillo de pantalla. flameshot = capturas. firefox-esr =
# el navegador. thunar = el explorador de archivos. lxqt-policykit = que
# te pida la contraseña cuando algo necesita permiso de administrador.
run apt-get install -y -qq \
  xorg xinit lightdm i3 i3status i3lock dmenu rofi picom nitrogen \
  alacritty tmux neovim htop btop fastfetch curl wget git unzip zip \
  fonts-jetbrains-mono fonts-firacode x11-xserver-utils \
  network-manager network-manager-gnome blueman pavucontrol \
  pipewire-audio brightnessctl flameshot \
  firefox-esr thunar thunar-archive-plugin file-roller \
  lxqt-policykit

log "3/6 Herramientas de red / seguridad (opcionales, para InfoForge)..."
# nmap = escáner de puertos. whois = datos de un dominio. dnsutils = dig/nslookup.
# jq = leer JSON en la terminal. traceroute = ver por dónde va la conexión.
# iproute2 = el comando ip. iputils-ping = el ping. python3/python3-pip = Python.
# 2>/dev/null significa "los errores, a la basura, no los muestres".
# || true significa "aunque este comando falle, no es error": como este paso
# es opcional, si un paquete no está, el script sigue igual.
run apt-get install -y -qq \
  nmap whois dnsutils curl jq traceroute iproute2 iputils-ping \
  python3 python3-pip 2>/dev/null || true

log "4/6 Configuración de i3, Alacritty, rofi, picom..."
# USER_NAME es tu usuario real, no root: SUDO_USER es el usuario que llamó
# a sudo (por ejemplo am0nd4rk). ${SUDO_USER:-${USER:-$(whoami)}} significa:
# "usa SUDO_USER si existe, si no USER, si no, lo que diga whoami".
# whoami es un comando que dice "¿quién soy yo?".
USER_NAME="${SUDO_USER:-${USER:-$(whoami)}}"
USER_HOME="/home/$USER_NAME"
# USER_HOME es tu carpeta personal, por ejemplo /home/am0nd4rk.
[[ "$USER_NAME" == "root" ]] && USER_HOME="/root"
# Si el usuario es root, su casa no es /home/root, es /root. El && significa
# "si se cumple lo de la izquierda, haz lo de la derecha".
if [[ -n "$USER_HOME" && -d "$USER_HOME" ]]; then
  # if [[ -n ... && -d ... ]]: "si USER_HOME no está vacío (-n) Y esa carpeta
  # existe (-d)". Solo entonces se copian las configuraciones.
  # mkdir -p crea las carpetas de configuración si no existen.
  # cp copia cada archivo de config de ForgeOS a tu carpeta .config.
  # chmod +x hace ejecutables los scripts. chown -R les pone tu usuario
  # como dueño, para que puedas editarlos sin ser root.
  run mkdir -p "$USER_HOME/.config/i3" "$USER_HOME/.config/i3status" \
    "$USER_HOME/.config/alacritty" "$USER_HOME/.config/rofi" "$USER_HOME/.config/picom"
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  run cp "$SCRIPT_DIR/config/i3/config" "$USER_HOME/.config/i3/config"
  run cp "$SCRIPT_DIR/config/i3status/config" "$USER_HOME/.config/i3status/config"
  run cp "$SCRIPT_DIR/config/alacritty/alacritty.toml" "$USER_HOME/.config/alacritty/alacritty.toml"
  run cp "$SCRIPT_DIR/config/rofi/config.rasi" "$USER_HOME/.config/rofi/config.rasi"
  run cp "$SCRIPT_DIR/config/picom/picom.conf" "$USER_HOME/.config/picom/picom.conf"
  run cp "$SCRIPT_DIR/scripts/forgeos-quad" /usr/local/bin/forgeos-quad
  run chmod +x /usr/local/bin/forgeos-quad
  run cp "$SCRIPT_DIR/scripts/forgeos-monitor" /usr/local/bin/forgeos-monitor
  run chmod +x /usr/local/bin/forgeos-monitor
  run cp "$SCRIPT_DIR/scripts/forgeos-pantallas" /usr/local/bin/forgeos-pantallas
  run chmod +x /usr/local/bin/forgeos-pantallas
  run cp "$SCRIPT_DIR/scripts/forgeos-sysinfo" /usr/local/bin/forgeos-sysinfo
  run chmod +x /usr/local/bin/forgeos-sysinfo
  run chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.config" 2>/dev/null || true
  # tmux útil — printf en vez de heredoc dentro de bash -c (era frágil)
  if [[ ! -f "$USER_HOME/.tmux.conf" ]]; then
    if $DRY_RUN; then
      echo "[dry-run] escribir $USER_HOME/.tmux.conf"
    else
      printf '%s\n' 'set -g mouse on' 'set -g history-limit 10000' \
        'bind | split-window -h' 'bind - split-window -v' > "$USER_HOME/.tmux.conf"
    fi
    run chown "$USER_NAME:$USER_NAME" "$USER_HOME/.tmux.conf" 2>/dev/null || true
  fi
fi

log "5/6 InfoForge..."
# Paso 5: bajar InfoForge de GitHub con git clone, en tu carpeta personal.
# Solo si NO_INFOFORGE está apagado (o sea, si no pasaste --no-infoforge).
# Si la carpeta InfoForge ya existe, no se clona de nuevo.
# git clone descarga una copia de un repo. sudo -u "$USER_NAME" lo hace
# como tu usuario, no como root, para que los archivos sean tuyos.
# Si falla el clonado, avisa y sigue: no rompe la instalación.
if [[ "$NO_INFOFORGE" == false ]]; then
  if [[ -d "$USER_HOME/InfoForge" ]]; then
    log "InfoForge ya existe en $USER_HOME/InfoForge, no lo clono de nuevo."
  else
    # Repo privado: necesita autenticación (SSH o token). Si falla, se avisa y se sigue.
    # Sin bash -c anidado: el comando se ejecuta directo, con sudo -u solo si no somos root.
    if $DRY_RUN; then
      echo "[dry-run] git clone https://github.com/Am0nD4rkM4/InfoForge.git $USER_HOME/InfoForge (como $USER_NAME)"
    elif [[ "$USER_NAME" == "root" ]]; then
      git clone https://github.com/Am0nD4rkM4/InfoForge.git "$USER_HOME/InfoForge" 2>/dev/null || echo 'No se pudo clonar InfoForge (repo privado: usa tu SSH/token y clónalo a mano)'
    else
      sudo -u "$USER_NAME" git clone https://github.com/Am0nD4rkM4/InfoForge.git "$USER_HOME/InfoForge" 2>/dev/null || echo 'No se pudo clonar InfoForge (repo privado: usa tu SSH/token y clónalo a mano)'
    fi
  fi
fi

log "6/6 LightDM como gestor de inicio..."
# systemctl enable lightdm: le dice a Debian "a partir de ahora, arranca
# LightDM al encender, para que salga la pantalla de login". systemctl es
# el comando que maneja los servicios que arrancan con el sistema.
run systemctl enable lightdm 2>/dev/null || true

log "Listo. Reinicia y elige i3 en LightDM."
echo "Atajos: Mod(Alt)+Return terminal · Mod+T 4 terminales · Mod+M ir al monitor (espacio 1) · Mod+d lanzador · Mod+i InfoForge"
echo "Si vienes de GNOME/KDE, esto es mucho más ligero: solo terminales en mosaico."
