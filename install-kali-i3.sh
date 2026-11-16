#!/usr/bin/env bash
# ForgeOS — instalar i3 en un Kali Linux que ya tiene Xfce / GNOME
# No borra ni reemplaza tu escritorio actual: i3 se instala al lado y lo
# eliges en la pantalla de login (selector de sesión).
# Uso en Kali:
#   sudo bash install-kali-i3.sh            # instalación completa
#   sudo bash install-kali-i3.sh --dry-run  # solo muestra lo que haría
#   sudo bash install-kali-i3.sh --no-infoforge
#
# Después: cierra sesión, en el login elige la sesión "i3" y entra.
# Primera vez en i3: elige Mod = Alt y acepta generar la config.
set -euo pipefail
# set -euo pipefail: "si algo falla, para el script en seco".
# -e = si un comando da error, el script se detiene. -u = si se usa una
# variable que no existe, da error. -o pipefail = si algo falla dentro
# de una tubería (|), también cuenta como error.

DRY_RUN=false
NO_INFOFORGE=false
# DRY_RUN=false: dos interruptores que empiezan apagados. DRY_RUN es el
# modo "ensayo": con --dry-run solo dice lo que haría, sin instalar nada.
# NO_INFOFORGE es "no clonar InfoForge".
for arg in "$@"; do
  # for arg in "$@": repasa cada argumento que le pasaste al script.
  # "$@" son todos esos argumentos, y en cada vuelta arg vale uno distinto.
  case "$arg" in
    # case "$arg" in: mira qué vale arg y salta a la rama que coincida.
    # ;; significa "fin de esta rama". *: "cualquier otra cosa".
    --dry-run) DRY_RUN=true ;;
    --no-infoforge) NO_INFOFORGE=true ;;
    --no-nitrogen) : ;;
    # --no-nitrogen ya no hace falta: nitrogen es opcional desde el
    # arreglo de Kali, se intenta aparte y si no está, se omite solo.
    # ":" significa "no hacer nada". Se acepta para no dar error.
    *) echo "Opción desconocida: $arg"; exit 2 ;;
    # Si el argumento no es ninguno de los dos conocidos, avisa y sale
    # con código 2 (error).
  esac
done

run() {
  # run() es una función auxiliar que tú creaste: "corre este comando, o
  # solo dilo si estamos en modo ensayo". "$@" son los argumentos que le
  # pases a run, y "$*" es lo mismo pero pegado en un solo texto.
  if $DRY_RUN; then echo "[dry-run] $*"; else "$@"; fi
}
log() { echo "==> $*"; }
# log() es otra función auxiliar: imprime un título con ==> delante,
# para que se vean los pasos en la terminal.

if [[ $EUID -ne 0 && $DRY_RUN == false ]]; then
  # $EUID es el número de usuario que corre el script: 0 es root.
  # -ne 0 significa "distinto de 0", o sea, "no eres root".
  # && significa "y además". O sea: "si no eres root Y no es un ensayo".
  echo "Ejecuta con sudo: sudo bash install-kali-i3.sh"
  exit 1
  # exit 1: sale del script con código 1, que significa "hubo un error".
fi

# Usuario real (no root): SUDO_USER si viene de sudo, si no USER, si no whoami.
# ${SUDO_USER:-${USER:-$(whoami)}} significa: "usa SUDO_USER si existe,
# si no USER, si no, lo que diga whoami". whoami es un comando que dice
# "¿quién soy yo?". USER_HOME es tu carpeta personal, /home/am0nd4rk.
# Si el usuario es root, su casa es /root, no /home/root.
USER_NAME="${SUDO_USER:-${USER:-$(whoami)}}"
USER_HOME="/home/$USER_NAME"
[[ "$USER_NAME" == "root" ]] && USER_HOME="/root"

log "ForgeOS en Kali — i3 tiling (Xfce/GNOME se quedan, no se tocan)"

log "1/4 Actualizando apt..."
# apt-get update: le pide a Kali la lista nueva de paquetes disponibles.
# -qq es "muy callado": que no llene la terminal de texto.
run apt-get update -qq

log "2/4 Instalando i3 y ayudantes (sin tocar Xfce/GNOME ni el login)..."
# Aquí solo se instala i3 y sus ayudantes, no Xorg ni LightDM: Kali ya
# tiene su propio sistema gráfico y su login, y no se tocan.
# i3 = escritorio en mosaico. i3status = barra de arriba. i3lock = bloquear.
# dmenu/rofi = lanzadores. picom = transparencias.
# alacritty = terminal. tmux = varias terminales en una. htop/btop = CPU y RAM.
# fastfetch = datos del sistema. flameshot = capturas. fonts-* = las letras.
# brightnessctl = brillo. pavucontrol = volumen.
# nitrogen NO va en la lista principal: en Kali no tiene candidato para
# instalar ("E: El paquete «nitrogen» no tiene un candidato para la
# instalación") y, como apt instala todo en un solo comando, un paquete
# que falta tumba toda la instalación aunque los demás sí existan.
# nitrogen solo pone el fondo de pantalla; la config de i3 ya lo llama
# con "|| true", así que si no está, i3 arranca igual, solo sin fondo.
run apt-get install -y -qq \
  i3 i3status i3lock dmenu rofi picom \
  alacritty tmux htop btop fastfetch flameshot \
  fonts-jetbrains-mono fonts-firacode x11-xserver-utils \
  brightnessctl pavucontrol
# Intentar nitrogen aparte, sin tumbar nada si Kali no lo tiene.
# "|| true" significa: "si esto falla, no es error, sigue adelante".
if $DRY_RUN; then
  echo "[dry-run] intentar instalar nitrogen (opcional, solo fondo de pantalla)"
else
  apt-get install -y -qq nitrogen 2>/dev/null || echo "Aviso: nitrogen no está disponible en Kali, se omite (solo es el fondo de pantalla)."
fi

log "3/4 Copiando la config de ForgeOS (con copia de seguridad si ya tenías i3)..."
# SCRIPT_DIR es la carpeta donde está este script: dirname "$0" dice
# "la carpeta del script" y cd + pwd la convierte en ruta completa.
# Así el script encuentra sus archivos config/ y scripts/ esté donde esté.
# mkdir -p crea las carpetas de configuración si no existen.
# Si ya tenías una config de i3, se guarda una copia de seguridad con la
# fecha y hora en el nombre (config.bak-20261116-023000), antes de sobrescribirla.
# cp copia cada config, chmod +x hace ejecutables los scripts, y chown -R
# les pone tu usuario como dueño, para que puedas editarlos sin ser root.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -d "$USER_HOME" ]]; then
  run mkdir -p "$USER_HOME/.config/i3" "$USER_HOME/.config/i3status" \
    "$USER_HOME/.config/alacritty" "$USER_HOME/.config/rofi" "$USER_HOME/.config/picom"
  # Si ya existía una config de i3, guardarla antes de sobrescribirla.
  if [[ -f "$USER_HOME/.config/i3/config" ]]; then
    STAMP="$(date +%Y%m%d-%H%M%S)"
    if $DRY_RUN; then
      echo "[dry-run] copia de seguridad de $USER_HOME/.config/i3/config a config.bak-$STAMP"
    else
      cp "$USER_HOME/.config/i3/config" "$USER_HOME/.config/i3/config.bak-$STAMP"
      echo "Copia de seguridad: ~/.config/i3/config.bak-$STAMP"
    fi
  fi
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

log "4/4 InfoForge..."
# Paso 4: bajar InfoForge de GitHub con git clone, en tu carpeta personal.
# Solo si NO_INFOFORGE está apagado. Si la carpeta ya existe, no se clona.
# Primero lo intenta por SSH (git@github.com:...): si tienes clave SSH,
# no pide nada. GIT_SSH_COMMAND con BatchMode=yes significa "no preguntes
# nada, si no puedes, falla rápido". Si SSH falla, lo intenta por HTTPS.
# GIT_TERMINAL_PROMPT=0 significa "no pidas usuario/contraseña en mitad
# del script". Si los dos fallan, avisa cómo clonarlo a mano y sigue.
if [[ "$NO_INFOFORGE" == false ]]; then
  if [[ -d "$USER_HOME/InfoForge" || -d "$USER_HOME/infoforge-linux" ]]; then
    log "InfoForge ya existe en tu home, no lo clono de nuevo."
  else
    if $DRY_RUN; then
      echo "[dry-run] git clone git@github.com:Am0nD4rkM4/InfoForge.git $USER_HOME/InfoForge (como $USER_NAME; si falla, HTTPS)"
    else
      # El repo es privado: primero SSH (si tienes clave, no pide nada),
      # luego HTTPS. Ambos con fallo rápido, sin quedarse pidiendo
      # usuario/contraseña en mitad del script.
      CLONED=false
      if [[ "$USER_NAME" == "root" ]]; then
        GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=10" git clone git@github.com:Am0nD4rkM4/InfoForge.git "$USER_HOME/InfoForge" 2>/dev/null && CLONED=true
        [[ "$CLONED" == false ]] && GIT_TERMINAL_PROMPT=0 git clone https://github.com/Am0nD4rkM4/InfoForge.git "$USER_HOME/InfoForge" 2>/dev/null && CLONED=true
      else
        sudo -u "$USER_NAME" env GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=10" git clone git@github.com:Am0nD4rkM4/InfoForge.git "$USER_HOME/InfoForge" 2>/dev/null && CLONED=true
        [[ "$CLONED" == false ]] && sudo -u "$USER_NAME" env GIT_TERMINAL_PROMPT=0 git clone https://github.com/Am0nD4rkM4/InfoForge.git "$USER_HOME/InfoForge" 2>/dev/null && CLONED=true
      fi
      if [[ "$CLONED" == false ]]; then
        echo 'No se pudo clonar InfoForge (repo privado). Clónalo a mano:'
        echo '  gh auth login && git clone https://github.com/Am0nD4rkM4/InfoForge.git ~/InfoForge'
        echo '  o con tu clave SSH: git clone git@github.com:Am0nD4rkM4/InfoForge.git ~/InfoForge'
        echo 'Sin InfoForge, Alt+I no funcionará hasta que lo clones.'
      fi
    fi
  fi
fi

log "Listo."
echo "Ahora: cierra sesión, en el login elige la sesión 'i3' y entra."
echo "Primera vez: Mod = Alt, acepta generar la config."
echo "Atajos: Alt+Return terminal · Alt+T 4 terminales · Alt+M ir al monitor (espacio 1) · Alt+D lanzador · Alt+I InfoForge"
echo "Para volver a Xfce/GNOME: cierra sesión y elige esa sesión en el login."
