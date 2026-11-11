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

DRY_RUN=false
NO_INFOFORGE=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --no-infoforge) NO_INFOFORGE=true ;;
    *) echo "Opción desconocida: $arg"; exit 2 ;;
  esac
done

run() {
  if $DRY_RUN; then echo "[dry-run] $*"; else "$@"; fi
}
log() { echo "==> $*"; }

if [[ $EUID -ne 0 && $DRY_RUN == false ]]; then
  echo "Ejecuta con sudo: sudo bash install-kali-i3.sh"
  exit 1
fi

# Usuario real (no root): SUDO_USER si viene de sudo, si no USER, si no whoami.
USER_NAME="${SUDO_USER:-${USER:-$(whoami)}}"
USER_HOME="/home/$USER_NAME"
[[ "$USER_NAME" == "root" ]] && USER_HOME="/root"

log "ForgeOS en Kali — i3 tiling (Xfce/GNOME se quedan, no se tocan)"

log "1/4 Actualizando apt..."
run apt-get update -qq

log "2/4 Instalando i3 y ayudantes (sin tocar Xfce/GNOME ni el login)..."
run apt-get install -y -qq \
  i3 i3status i3lock dmenu rofi picom nitrogen \
  alacritty tmux htop btop fastfetch flameshot \
  fonts-jetbrains-mono fonts-firacode x11-xserver-utils \
  brightnessctl pavucontrol

log "3/4 Copiando la config de ForgeOS (con copia de seguridad si ya tenías i3)..."
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
