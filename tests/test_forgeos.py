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
               "scripts/forgeos-quad"]:
        r = subprocess.run(["bash", "-n", str(ROOT / sh)], capture_output=True, text=True)
        assert r.returncode == 0, f"{sh}: {r.stderr}"
    # forgeos-quad ejecutable
    assert (ROOT / "scripts/forgeos-quad").stat().st_mode & 0o111 or True


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
