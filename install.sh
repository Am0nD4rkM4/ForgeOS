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
  echo "Ejecuta con sudo: sudo bash install.sh"
  exit 1
fi

log "ForgeOS — Debian 13 + i3"
log "1/6 Actualizando apt..."
run apt-get update -qq
run apt-get install -y -qq curl git sudo

log "2/6 Instalando Xorg, i3 y utilidades..."
run apt-get install -y -qq \
  xorg xinit lightdm i3 i3status i3lock dmenu rofi picom nitrogen \
  alacritty tmux neovim htop btop fastfetch curl wget git unzip zip \
  fonts-jetbrains-mono fonts-firacode x11-xserver-utils \
  network-manager network-manager-gnome blueman pavucontrol \
  pipewire-audio brightnessctl flameshot \
  firefox-esr thunar thunar-archive-plugin file-roller \
  lxqt-policykit

log "3/6 Herramientas de red / seguridad (opcionales, para InfoForge)..."
run apt-get install -y -qq \
  nmap whois dnsutils curl jq traceroute iproute2 iputils-ping \
  python3 python3-pip 2>/dev/null || true

log "4/6 Configuración de i3, Alacritty, rofi, picom..."
USER_NAME="${SUDO_USER:-${USER:-$(whoami)}}"
USER_HOME="/home/$USER_NAME"
[[ "$USER_NAME" == "root" ]] && USER_HOME="/root"
if [[ -n "$USER_HOME" && -d "$USER_HOME" ]]; then
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
run systemctl enable lightdm 2>/dev/null || true

log "Listo. Reinicia y elige i3 en LightDM."
echo "Atajos: Mod(Alt)+Return terminal · Mod+T 4 terminales · Mod+M ir al monitor (espacio 1) · Mod+d lanzador · Mod+i InfoForge"
echo "Si vienes de GNOME/KDE, esto es mucho más ligero: solo terminales en mosaico."
