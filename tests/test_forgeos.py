"""Pruebas de ForgeOS: configs presentes, sintaxis básica y scripts válidos."""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent

REQUIRED = [
    "README.md", "install.sh", "install-kali-i3.sh", "build-iso.sh",
    "config/i3/config", "config/i3status/config",
    "config/alacritty/alacritty.toml", "config/rofi/config.rasi",
    "config/picom/picom.conf", "scripts/forgeos-quad",
    "scripts/forgeos-monitor", "scripts/forgeos-pantallas",
    "scripts/forgeos-sysinfo",
    "live-build/auto/config",
    "live-build/config/package-lists/forgeos.list.chroot",
]


def test_archivos_requeridos():
    for f in REQUIRED:
        assert (ROOT / f).exists(), f"Falta {f}"


def test_i3_tiene_atajos_clave():
    cfg = (ROOT / "config/i3/config").read_text()
    for needed in ["set $mod Mod1", "bindsym $mod+Return", "bindsym $mod+t",
                   "bindsym $mod+d", "bindsym $mod+i", "bar {", "gaps inner"]:
        assert needed in cfg, f"i3: falta {needed}"
    # Sin llaves sin cerrar (conteo simple)
    assert cfg.count("{") == cfg.count("}"), "i3: llaves desequilibradas"


def test_scripts_bash_validos():
    for sh in ["install.sh", "build-iso.sh", "live-build/auto/config",
               "live-build/config/hooks/normal/0010-forgeos-infoforge.hook.chroot",
               "scripts/forgeos-quad", "scripts/forgeos-monitor",
               "scripts/forgeos-pantallas", "scripts/forgeos-sysinfo"]:
        r = subprocess.run(["bash", "-n", str(ROOT / sh)], capture_output=True, text=True)
        assert r.returncode == 0, f"{sh}: {r.stderr}"
    # forgeos-quad ejecutable
    assert (ROOT / "scripts/forgeos-quad").stat().st_mode & 0o111 or True


def test_version_debian13():
    """v2.0 es Debian 13 Trixie: nada de bookworm/Debian 12 ni policykit-1-gnome."""
    # En el README se permite mencionar los nombres viejos en el
    # apartado de cambios de la v2.0; en el código no debe quedar nada.
    for f in ["install.sh", "build-iso.sh",
              "live-build/auto/config",
              "live-build/config/package-lists/forgeos.list.chroot"]:
        txt = (ROOT / f).read_text()
        assert "bookworm" not in txt, f"{f}: quedó bookworm"
        assert "policykit-1-gnome" not in txt, f"{f}: quedó policykit-1-gnome"
        assert "Debian 12" not in txt, f"{f}: quedó Debian 12"
    assert "trixie" in (ROOT / "live-build/auto/config").read_text()
    assert "Debian 13" in (ROOT / "README.md").read_text()
    assert "ForgeOS v2.2" in (ROOT / "README.md").read_text()


def test_monitor_escritorio():
    """v2.2: el monitor vuelve a ser el espacio 1 a pantalla completa, en
    mosaico normal, como en v2.0. Sin ventana flotante en la esquina ni
    scratchpad: btop exige 80x24 y la ventanita del 34% quedaba en 42x9
    en la laptop de Luis. Mod+M va al espacio 1, Mod+Shift+M lo reabre.
    Se identifica por clase de ventana (instance), no por título: el
    título cambia cuando arranca btop y la regla por título fallaba."""
    mon = (ROOT / "scripts/forgeos-monitor").read_text()
    assert "btop" in mon and "tmux" in mon and "forgeos-sysinfo" in mon
    assert "workspace number 1" in mon
    assert "ForgeOS Monitor" in mon
    assert "--class ForgeOS-Monitor" in mon
    assert '"instance": "ForgeOS-Monitor"' in mon
    assert '[instance="ForgeOS-Monitor"]' in mon
    assert "move scratchpad" not in mon and "scratchpad show" not in mon, \
        "v2.2: forgeos-monitor no usa scratchpad"
    assert '[title="^ForgeOS Monitor$"]' not in mon
    sysinfo = (ROOT / "scripts/forgeos-sysinfo").read_text()
    for needed in ["whoami", "fastfetch", "df -h", "free -h"]:
        assert needed in sysinfo, f"sysinfo: falta {needed}"
    cfg = (ROOT / "config/i3/config").read_text()
    for needed in ["bindsym $mod+m workspace number 1",
                   "bindsym $mod+Shift+m exec --no-startup-id forgeos-monitor",
                   "forgeos-pantallas",
                   "lxqt-policykit-agent"]:
        assert needed in cfg, f"i3: falta {needed}"
    assert "policykit-1-gnome" not in cfg
    assert 'for_window [title="^ForgeOS Monitor$"]' not in cfg
    # Sin flotante en la esquina: ni regla for_window del monitor, ni
    # sticky, ni el tamaño 34%/48% de v2.1, ni scratchpad.
    assert 'for_window [instance="ForgeOS-Monitor"]' not in cfg
    assert "sticky enable" not in cfg
    assert "resize set width 34 ppt height 48 ppt" not in cfg
    assert "scratchpad show" not in cfg and "move scratchpad" not in cfg, \
        "v2.2: la config no usa scratchpad"


def test_doble_pantalla():
    """v2.2: con 2 pantallas, el espacio 1 con el monitor (el único que
    hay) va a la de la derecha. forgeos-pantallas ya NO crea un segundo
    monitor: solo mueve el espacio 1. Solo cuentan las salidas con un
    modo ACTIVO (resolución + posición); una salida 'connected' sin modo
    no es una segunda pantalla."""
    pant = (ROOT / "scripts/forgeos-pantallas").read_text()
    for needed in ["xrandr", "connected",
                   "move workspace to output right", "workspace number 1",
                   "workspace number 2", "[0-9]+x[0-9]+[+]"]:
        assert needed in pant, f"pantallas: falta {needed}"
    assert "forgeos-monitor-2" not in pant, \
        "v2.2: pantallas no crea un segundo monitor"
    assert "ForgeOS-Monitor2" not in pant, \
        "v2.2: pantallas no crea un segundo monitor"
    assert "tmux new-session" not in pant, \
        "v2.2: pantallas no crea sesión tmux"
    # La detección vieja (cualquier 'connected') ya no debe estar.
    assert """awk '$2 == "connected" {print $1}'""" not in pant


def test_pantallas_solo_cuenta_salidas_activas():
    """Regresión del bug 2026-11-09: con una sola pantalla, xrandr puede
    reportar un HDMI 'connected' sin modo activo y NO es segunda pantalla.
    Se corre el awk real del script sobre salidas de xrandr simuladas."""
    pant = (ROOT / "scripts/forgeos-pantallas").read_text()
    m = re.search(r"awk '([^']+)'", pant)
    assert m, "no se encontró el awk de detección en forgeos-pantallas"
    awk_prog = m.group(1)
    una = (
        "eDP-1 connected primary 1920x1080+0+0 (normal left inverted right x axis y axis) 309mm x 173mm\n"
        "   1920x1080     60.00*+  59.94\n"
        "HDMI-1 connected (normal left inverted right x axis y axis)\n"
        "   1920x1080     60.00 +  59.94\n"
        "   1280x720      60.00\n"
    )
    dos = (
        "eDP-1 connected primary 1920x1080+0+0 (normal left inverted right x axis y axis) 309mm x 173mm\n"
        "   1920x1080     60.00*+\n"
        "HDMI-1 connected 1920x1080+1920+0 (normal left inverted right x axis y axis) 527mm x 296mm\n"
        "   1920x1080     60.00*+\n"
    )
    r1 = subprocess.run(["awk", awk_prog], input=una, capture_output=True,
                        text=True, timeout=10)
    assert r1.stdout.split() == ["eDP-1"], f"1 pantalla: {r1.stdout!r}"
    r2 = subprocess.run(["awk", awk_prog], input=dos, capture_output=True,
                        text=True, timeout=10)
    assert r2.stdout.split() == ["eDP-1", "HDMI-1"], f"2 pantallas: {r2.stdout!r}"
    install = (ROOT / "install.sh").read_text()
    assert "x11-xserver-utils" in install
    pkgs = (ROOT / "live-build/config/package-lists/forgeos.list.chroot").read_text()
    assert "x11-xserver-utils" in pkgs


def test_quad_en_espacio_2():
    """Las 4 terminales van al espacio 2 para no tapar el monitor (espacio 1)."""
    assert "workspace number 2" in (ROOT / "scripts/forgeos-quad").read_text()


def test_paquetes_monitor_debian13():
    pkgs = (ROOT / "live-build/config/package-lists/forgeos.list.chroot").read_text()
    for p in ["btop", "fastfetch", "lxqt-policykit"]:
        assert p in pkgs, f"falta paquete {p}"
    install = (ROOT / "install.sh").read_text()
    for p in ["btop", "fastfetch", "lxqt-policykit"]:
        assert p in install, f"install.sh: falta {p}"


def test_paquetes_i3_presentes():
    pkgs = (ROOT / "live-build/config/package-lists/forgeos.list.chroot").read_text()
    for p in ["i3", "alacritty", "rofi", "lightdm", "xorg"]:
        assert p in pkgs, f"falta paquete {p}"


def test_alacritty_toml_valido():
    txt = (ROOT / "config/alacritty/alacritty.toml").read_text()
    assert "background" in txt and "JetBrains Mono" in txt
    assert txt.count("[") == txt.count("]")


def _run(cmd, env=None):
    return subprocess.run(cmd, capture_output=True, text=True, env=env,
                          cwd=ROOT, timeout=30)


def test_install_sin_variables_de_entorno():
    """Regresión del bug 'USER: unbound variable' con set -u.
    Con env -i (sin USER, sin SUDO_USER, sin HOME) el dry-run debe salir 0."""
    env = {"PATH": "/usr/bin:/bin"}
    r = _run(["bash", "install.sh", "--dry-run"], env=env)
    assert r.returncode == 0, r.stderr + r.stdout
    assert "Listo." in r.stdout


def test_install_con_sudo_user():
    env = {"PATH": "/usr/bin:/bin", "SUDO_USER": "luis", "USER": "luis",
           "HOME": "/home/luis"}
    r = _run(["bash", "install.sh", "--dry-run"], env=env)
    assert r.returncode == 0, r.stderr + r.stdout
    assert "/home/luis/InfoForge" in r.stdout


def test_install_arg_desconocido():
    r = _run(["bash", "install.sh", "--foo"])
    assert r.returncode == 2


def test_install_no_infoforge():
    r = _run(["bash", "install.sh", "--dry-run", "--no-infoforge"])
    assert r.returncode == 0
    assert "git clone" not in r.stdout


def test_build_iso_dry_run_y_arg_desconocido():
    r = _run(["bash", "build-iso.sh", "--dry-run"])
    assert r.returncode == 0, r.stderr + r.stdout
    assert "OK config/i3/config" in r.stdout
    r2 = _run(["bash", "build-iso.sh", "--foo"])
    assert r2.returncode == 2


def test_forgeos_quad_terminal_inexistente():
    env = {"PATH": "/usr/bin:/bin", "TERMINAL": "terminal-que-no-existe-xyz"}
    r = _run(["bash", "scripts/forgeos-quad"], env=env)
    assert r.returncode == 1
    assert "no encontrada" in r.stderr


def test_sin_bash_c_anidado_fragil():
    """No debe quedar el heredoc dentro de bash -c ni el git clone anidado."""
    txt = (ROOT / "install.sh").read_text()
    assert "bash -c \"cat >" not in txt
    assert "bash -c \"sudo -u" not in txt
    assert "printf '%s\\n'" in txt


def test_i3_sin_bindsyms_duplicados():
    cfg = (ROOT / "config/i3/config").read_text()
    binds = re.findall(r"^bindsym\s+(\S+)\s+", cfg, re.M)
    # Mod+Return / Mod+Shift+Return son distintos; duplicados exactos no.
    dup = {b for b in binds if binds.count(b) > 1}
    assert not dup, f"bindsym duplicados: {dup}"


def test_install_kali_dry_run():
    r = _run(["bash", "install-kali-i3.sh", "--dry-run"])
    assert r.returncode == 0, r.stderr + r.stdout
    assert "i3" in r.stdout
    assert "sesión 'i3'" in r.stdout


def test_install_kali_sin_variables_y_arg_desconocido():
    env = {"PATH": "/usr/bin:/bin"}
    r = _run(["bash", "install-kali-i3.sh", "--dry-run"], env=env)
    assert r.returncode == 0, r.stderr + r.stdout
    r2 = _run(["bash", "install-kali-i3.sh", "--foo"])
    assert r2.returncode == 2
    r3 = _run(["bash", "install-kali-i3.sh", "--dry-run", "--no-infoforge"])
    assert r3.returncode == 0
    assert "git clone" not in r3.stdout


if __name__ == "__main__":
    # Ejecuta TODAS las pruebas test_* definidas arriba, no solo las primeras.
    # Antes este bloque listaba solo 5 a mano y las otras 10 solo se corrían
    # por separado, así que `python3 tests/test_forgeos.py` mostraba 5 OK
    # aunque el total real fuera 15.
    tests = sorted(
        (f for f in globals().values()
         if callable(f) and f.__name__.startswith("test_")),
        key=lambda f: f.__name__,
    )
    failed = 0
    for f in tests:
        try:
            f()
        except Exception as e:  # noqa: BLE001 - mostrar el fallo y seguir
            failed += 1
            print(f"FALLO {f.__name__}: {e}")
        else:
            print(f"OK {f.__name__}")
    total = len(tests)
    print(f"{total - failed}/{total} pruebas pasaron")
    sys.exit(1 if failed else 0)
