# ForgeOS v1.2 — Debian 12 + i3, estilo Arch

**ForgeOS 1.2 · Basada en Debian 12 Bookworm · Escritorio i3 tiling · Con InfoForge**

ForgeOS es lo que pediste, Luis: una distro con el espíritu de Arch —mínima, solo terminales en mosaico, todo con teclado— pero basada en Debian, que es con el que estás familiarizado. Sin GNOME ni KDE. Al arrancar ves una barra superior y una terminal. Y nada más, hasta que tú abras más.

## Cómo se ve

```
┌──────────────────────────────────────────────┐
│ 1 2 3 4 ...  CPU  RAM  Disco  2026-11-07 18:00 │  ← barra i3status
├──────────────────────┬───────────────────────┤
│                      │                       │
│   terminal 1         │   terminal 2          │
│   $ infoforge        │   $ htop               │
│                      │                       │
├──────────────────────┼───────────────────────┤
│                      │                       │
│   terminal 3         │   terminal 4          │
│   $ nmap ...         │   $ vim ...            │
│                      │                       │
└──────────────────────┴───────────────────────┘
```

Abres una terminal y ocupa toda la pantalla. Abres otra y se divide. Con `Mod+T` abres las 4 de golpe, en mosaico.

## Dos formas de usarla

### A) La rápida: instalar ForgeOS sobre un Debian que ya tengas

1. Instala Debian 12 netinst **sin escritorio** (desmarca todo en tasksel), en VM o en un PC de pruebas.
2. Copia este proyecto dentro y ejecuta:
   ```bash
   sudo bash install.sh
   sudo reboot
   ```
3. En LightDM elige **i3** y entra.

### A2) En Kali que ya tienes (con Xfce/GNOME): solo i3, sin tocar lo demás

Si ya tienes Kali instalado, como Luis, no hace falta reinstalar nada:

```bash
sudo bash install-kali-i3.sh
```

Esto instala i3, i3status, rofi, picom y Alacritty, copia la config de ForgeOS a `~/.config/` (con copia de seguridad si ya tenías una config de i3) e intenta clonar InfoForge. **No borra Xfce ni GNOME.** Después cierra sesión, elige la sesión **i3** en el login y entra. Para volver, cierra sesión y elige Xfce/GNOME.

`install.sh` instala Xorg, i3, Alacritty, rofi, picom, Firefox, Thunar, nmap, whois, etc., copia las configs a `~/.config/` e intenta clonar InfoForge (repo privado: necesitarás tu SSH o token).

Prueba en seco, sin instalar nada:
```bash
sudo bash install.sh --dry-run
```

### B) La completa: generar la ISO

En Debian 12, con sudo, ~4 GB libres y buena conexión:
```bash
sudo bash build-iso.sh
# ISO en live-build/live-image-amd64.hybrid.iso (en /tmp/forgeos-build/)
qemu-system-x86_64 -m 2048 -cdrom live-image-amd64.hybrid.iso -boot d
```

Tarda 20-60 minutos. Pruébala en VM antes de instalarla en hardware real. El instalador es Calamares (live-installer).

## Atajos de i3 (Mod = Alt)

| Atajo | Qué hace |
|---|---|
| `Mod+Return` | Nueva terminal |
| `Mod+Shift+Return` | Terminal con tmux |
| `Mod+T` | **4 terminales en mosaico** |
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
- **Terminal:** Alacritty (JetBrains Mono), tmux, neovim
- **Sistema:** htop, btop, NetworkManager, Bluetooth, PulseAudio, brightnessctl
- **Archivos y web:** Thunar, Firefox ESR, flameshot
- **Seguridad / InfoForge:** nmap, whois, dnsutils, jq, traceroute, python3, InfoForge (al clonar el repo)

## Estructura

```
forgeos/
├── README.md
├── install.sh            # Debian mínimo -> ForgeOS
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
├── scripts/forgeos-quad   # abre 4 terminales en mosaico
└── tests/test_forgeos.py
```

## Pruebas

```bash
python3 tests/test_forgeos.py
bash -n install.sh build-iso.sh live-build/auto/config
```

## Advertencias honestas

- Esto es una **derivada de Debian**, no una distro desde cero. No tiene gestor de paquetes propio ni repositorios propios: usa los de Debian.
- La ISO **no está construida aquí**: este proyecto es el código y la configuración para construirla. Construirla requiere Debian 12, sudo, internet y tiempo.
- No instales esto en tu PC principal sin probarlo antes en VM.

## Licencia

MIT. Creado por Tweeky para Luis. ForgeOS usa Debian 12 y i3, con sus propias licencias.
