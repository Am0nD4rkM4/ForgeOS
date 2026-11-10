# ForgeOS v2.0 — Debian 13 + i3, estilo Arch

**ForgeOS 2.0 · Basada en Debian 13 Trixie · Escritorio i3 tiling con monitor del sistema · Con InfoForge**

ForgeOS es lo que pediste, Luis: una distro con el espíritu de Arch —mínima, solo terminales en mosaico, todo con teclado— pero basada en Debian, que es con el que estás familiarizado. Sin GNOME ni KDE.

Y sí, esto **ya es un escritorio**: un escritorio no tiene que tener iconos ni ventanas flotantes. Un escritorio es el programa que te pone la barra, las ventanas y los atajos. Aquí ese programa es i3, y es un escritorio tiling: en vez de ventanas encima de otras, las pone en mosaico, sin superponerse.

## Cómo se ve ahora (v2.0)

Al arrancar caes en el **espacio 1, el Monitor**: una terminal dividida en dos, siempre visible.

```
┌──────────────────────────────────────────────────────┐
│ 1 2 3 4 ...  CPU  RAM  Disco  2026-11-09 19:45        │  ← barra i3status
├──────────────────────────────────────────────────────┤
│  btop — administrador de tareas                      │
│  CPU ████████░░  RAM ██████░░░░  Disco /  Red         │
│  procesos: firefox, i3, pipewire...                  │
├──────────────────────────────────────────────────────┤
│  luis@forgeos · uptime 2h · RAM 3.1G/16G · / 42G      │
│  IP 192.168.1.10 · kernel 6.12 · Debian 13           │
└──────────────────────────────────────────────────────┘
```

Arriba está **btop**, el administrador de tareas en terminal: CPU por núcleo, RAM, disco, red y la lista de procesos, todo en vivo. Abajo, **forgeos-sysinfo**: tu nombre de usuario, el equipo, cuánto lleva encendido, RAM, disco e IP, actualizándose cada 5 segundos.

Y la barra de arriba ya llevaba CPU, RAM, disco y carga, así que esos datos los tienes en dos sitios.

Los demás espacios son para trabajar: el 2 es para terminales, y con `Mod+T` abres 4 de golpe en mosaico. Puedes abrir todas las terminales que quieras, no solo 4: cada `Mod+Return` abre una más y el mosaico se reparte solo.

## Dos formas de usarla

### A) La rápida: instalar ForgeOS sobre un Debian que ya tengas

1. Instala Debian 13 netinst **sin escritorio** (desmarca todo en tasksel), en VM o en un PC de pruebas.
2. Copia este proyecto dentro y ejecuta:
   ```bash
   sudo bash install.sh
   sudo reboot
   ```
3. En LightDM elige **i3** y entra. Al entrar ya estás en el Monitor.

### A2) En Kali que ya tienes (con Xfce/GNOME): solo i3, sin tocar lo demás

Si ya tienes Kali instalado, como Luis, no hace falta reinstalar nada:

```bash
sudo bash install-kali-i3.sh
```

Esto instala i3, i3status, rofi, picom y Alacritty, copia la config de ForgeOS a `~/.config/` (con copia de seguridad si ya tenías una config de i3) e intenta clonar InfoForge. **No borra Xfce ni GNOME.** Después cierra sesión, elige la sesión **i3** en el login y entra. Para volver, cierra sesión y elige Xfce/GNOME.

`install.sh` instala Xorg, i3, Alacritty, rofi, picom, Firefox, Thunar, btop, fastfetch, nmap, whois, etc., copia las configs a `~/.config/` e intenta clonar InfoForge (repo privado: necesitarás tu SSH o token).

Prueba en seco, sin instalar nada:
```bash
sudo bash install.sh --dry-run
```

### B) La completa: generar la ISO

En Debian 13, con sudo, ~4 GB libres y buena conexión:
```bash
sudo bash build-iso.sh
# ISO en live-build/live-image-amd64.hybrid.iso (en /tmp/forgeos-build/)
qemu-system-x86_64 -m 2048 -cdrom live-image-amd64.hybrid.iso -boot d
```

Tarda 20-60 minutos. Pruébala en VM antes de instalarla en hardware real. El instalador es Calamares (live-installer).

## Espacios de trabajo

| Espacio | Para qué |
|---|---|
| `Mod+1` Monitor | btop + datos del sistema, siempre abierto |
| `Mod+2` Terminales | Aquí cae `Mod+T` con las 4 terminales |
| `Mod+3` | Libre, por ejemplo el navegador |
| `Mod+4` | Libre, por ejemplo InfoForge |
| `Mod+5` … `Mod+0` | Libres, hasta 10 espacios |

## Atajos de i3 (Mod = Alt)

| Atajo | Qué hace |
|---|---|
| `Mod+M` | **Ir al Monitor** (btop + datos del sistema) |
| `Mod+Shift+M` | Solo btop en una terminal |
| `Mod+Return` | Nueva terminal |
| `Mod+Shift+Return` | Terminal con tmux |
| `Mod+T` | **4 terminales en mosaico** (espacio 2) |
| `Mod+D` | Lanzador rofi |
| `Mod+I` | InfoForge interactivo |
| `Mod+Shift+I` | InfoForge — sistema local |
| `Mod+H/J/K/L` o flechas | Moverse entre ventanas |
| `Mod+Shift+H/J/K/L` | Mover ventana |
| `Mod+V` / `Mod+B` | Dividir vertical / horizontal |
| `Mod+F` | Pantalla completa |
| `Mod+Shift+F` | Ventana flotante |
| `Mod+1` … `Mod+0` | Espacios de trabajo 1-10 |
| `Mod+Shift+1` … | Mover ventana a ese espacio |
| `Mod+R` y luego `H/J/K/L` | Redimensionar |
| `Mod+Shift+Q` | Cerrar ventana |
| `Mod+Shift+C` / `Mod+Shift+R` | Recargar / reiniciar i3 |
| `Mod+Shift+E` | Salir de i3 |
| `Mod+Control+L` | Bloquear pantalla |
| `Print` | Captura con flameshot |

¿Prefieres la tecla Super (Windows) como Mod? Cambia la primera línea de `config/i3/config`: `set $mod Mod4`.

## Qué lleva preinstalado

- **Escritorio:** i3, i3status, i3lock, rofi, picom, nitrogen, LightDM
- **Monitor:** btop, fastfetch, `forgeos-monitor`, `forgeos-sysinfo`
- **Terminal:** Alacritty (JetBrains Mono), tmux, neovim
- **Sistema:** htop, btop, NetworkManager, Bluetooth, PulseAudio, brightnessctl
- **Archivos y web:** Thunar, Firefox ESR, flameshot
- **Seguridad / InfoForge:** nmap, whois, dnsutils, jq, traceroute, python3, InfoForge (al clonar el repo)

## Estructura

```
forgeos/
├── README.md
├── install.sh            # Debian 13 mínimo -> ForgeOS
├── install-kali-i3.sh    # i3 en Kali, sin tocar Xfce/GNOME
├── build-iso.sh          # live-build -> ISO
├── live-build/
│   ├── auto/config
│   └── config/
│       ├── package-lists/forgeos.list.chroot
│       └── hooks/normal/0010-forgeos-infoforge.hook.chroot
├── config/
│   ├── i3/config
│   ├── i3status/config
│   ├── alacritty/alacritty.toml
│   ├── rofi/config.rasi
│   └── picom/picom.conf
├── scripts/
│   ├── forgeos-quad      # abre 4 terminales en mosaico (espacio 2)
│   ├── forgeos-monitor   # escritorio monitor: btop + datos (espacio 1)
│   └── forgeos-sysinfo   # usuario, uptime, RAM, disco, IP
└── tests/test_forgeos.py
```

## Pruebas

```bash
python3 tests/test_forgeos.py
bash -n install.sh build-iso.sh live-build/auto/config
```

## Cambios de la v2.0 respecto a la v1.2

- Base **Debian 13 Trixie** en vez de Debian 12 Bookworm (live-build `trixie`, instalador actualizado).
- `policykit-1-gnome` ya no existe en Debian 13, se cambió por `lxqt-policykit`.
- Nuevo **escritorio monitor**: espacio 1 con btop y datos del sistema al arrancar, `Mod+M` para volver a él.
- `forgeos-quad` ahora abre las 4 terminales en el espacio 2, para no tapar el monitor.
- Se añadió `fastfetch` para los datos del sistema.

## Advertencias honestas

- Esto es una **derivada de Debian**, no una distro desde cero. No tiene gestor de paquetes propio ni repositorios propios: usa los de Debian.
- La ISO **no está construida aquí**: este proyecto es el código y la configuración para construirla. Construirla requiere Debian 13, sudo, internet y tiempo.
- No instales esto en tu PC principal sin probarlo antes en VM.

## Licencia

MIT. Creado por Tweeky para Luis. ForgeOS usa Debian 13 y i3, con sus propias licencias.
