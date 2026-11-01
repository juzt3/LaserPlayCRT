#!/usr/bin/env python3
# LaserPlay CRT - ajuste de geometria del modo CRT.
# Edita el DTD del EDID (/boot/LASER480.bin). Al aplicar, tambien fija
# system.es.videomode. htotal/vtotal se mantienen (15.7kHz / 60Hz estables).
import sys, os

EDID = "/boot/LASER480.bin"
RC   = "/recalbox/share/system/recalbox.conf"
B    = 0xA6     # inicio del DTD en el bloque CEA
HT   = 1716     # htotal fijo
VT   = 525      # vtotal fijo
ORIG = dict(hactive=1320, vactive=480, hfront=152, hsync=124, vfront=9, vsync=2)


def get(d):
    return dict(
        hactive=((d[B+4] >> 4) << 8) | d[B+2],
        hblank =((d[B+4] & 0x0F) << 8) | d[B+3],
        vactive=((d[B+7] >> 4) << 8) | d[B+5],
        vblank =((d[B+7] & 0x0F) << 8) | d[B+6],
        hfront = d[B+8] | ((d[B+11] & 0x03) << 8),
        hsync  = d[B+9] | (((d[B+11] >> 2) & 0x03) << 8),
        vfront = (d[B+10] >> 4) | (((d[B+11] >> 4) & 0x03) << 4),
        vsync  = (d[B+10] & 0x0F) | (((d[B+11] >> 6) & 0x03) << 4),
    )


def put(d, v):
    d[B+2] = v['hactive'] & 0xFF
    d[B+4] = (d[B+4] & 0x0F) | (((v['hactive'] >> 8) & 0x0F) << 4)
    d[B+3] = v['hblank'] & 0xFF
    d[B+4] = (d[B+4] & 0xF0) | ((v['hblank'] >> 8) & 0x0F)
    d[B+5] = v['vactive'] & 0xFF
    d[B+7] = (d[B+7] & 0x0F) | (((v['vactive'] >> 8) & 0x0F) << 4)
    d[B+6] = v['vblank'] & 0xFF
    d[B+7] = (d[B+7] & 0xF0) | ((v['vblank'] >> 8) & 0x0F)
    d[B+8] = v['hfront'] & 0xFF
    d[B+11] = (d[B+11] & 0xFC) | ((v['hfront'] >> 8) & 0x03)
    d[B+9] = v['hsync'] & 0xFF
    d[B+11] = (d[B+11] & 0xF3) | (((v['hsync'] >> 8) & 0x03) << 2)
    d[B+10] = (d[B+10] & 0x0F) | ((v['vfront'] & 0x0F) << 4)
    d[B+11] = (d[B+11] & 0xCF) | (((v['vfront'] >> 4) & 0x03) << 4)
    d[B+10] = (d[B+10] & 0xF0) | (v['vsync'] & 0x0F)
    d[B+11] = (d[B+11] & 0x3F) | (((v['vsync'] >> 4) & 0x03) << 6)


def getch():
    import termios, tty
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        ch = sys.stdin.read(1)
        if ch == "\x1b":
            ch += sys.stdin.read(2)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)
    return ch


def draw(g):
    hb = HT - g['hactive'] - g['hfront'] - g['hsync']
    vb = VT - g['vactive'] - g['vfront'] - g['vsync']
    print("\033[2J\033[H", end="")
    print("LaserPlay CRT - geometria (aplica al reiniciar)\r")
    print("==================================================\r")
    print("  H posicion : %4d    h=izquierda   l=derecha\r" % g['hfront'])
    print("  V posicion : %4d    k=arriba      j=abajo\r" % g['vfront'])
    print("  H tamano   : %4d    u=achicar      i=agrandar\r" % g['hactive'])
    print("  V tamano   : %4d    n=achicar      m=agrandar\r" % g['vactive'])
    print("--------------------------------------------------\r")
    print("  hback=%d   vback=%d\r" % (hb, vb))
    print("  modo = %dx%d  (se fija system.es.videomode)\r" % (g['hactive'], g['vactive']))
    print("==================================================\r")
    print("  [a] aplicar y salir   [r] reset   [q] salir sin guardar\r")


def clamp(g):
    g['hactive'] = max(800, min(HT - g['hsync'] - 16, g['hactive']))
    g['vactive'] = max(240, min(VT - g['vsync'] - 4, g['vactive']))
    g['hfront'] = max(4, min(HT - g['hactive'] - g['hsync'] - 4, g['hfront']))
    g['vfront'] = max(1, min(VT - g['vactive'] - g['vsync'] - 1, g['vfront']))
    return g


def apply(g):
    d = bytearray(open(EDID, "rb").read())
    v = dict(hactive=g['hactive'], hblank=HT - g['hactive'],
             vactive=g['vactive'], vblank=VT - g['vactive'],
             hfront=g['hfront'], hsync=g['hsync'],
             vfront=g['vfront'], vsync=g['vsync'])
    put(d, v)
    d[255] = (-sum(d[128:255])) & 0xFF
    os.system("mount -o remount,rw /boot 2>/dev/null")
    open(EDID, "wb").write(d)
    try:
        src = open(RC).read()
        out = []
        for ln in src.splitlines():
            if ln.startswith("system.es.videomode="):
                ln = "system.es.videomode=%dx%d" % (g['hactive'], g['vactive'])
            out.append(ln)
        open(RC + ".laserbak", "w").write(src)
        tmp = RC + ".tmp"
        open(tmp, "w").write("\n".join(out) + "\n")
        os.replace(tmp, RC)
    except Exception:
        pass
    os.system("mount -o remount,ro /boot 2>/dev/null")


def main():
    d = bytearray(open(EDID, "rb").read())
    g = get(d)
    g = dict(hactive=g['hactive'], vactive=g['vactive'],
             hfront=g['hfront'], hsync=g['hsync'],
             vfront=g['vfront'], vsync=g['vsync'])

    # Modo CLI (para userscripts del menu, sin terminal):
    #   crt-geometry.py DH DV DANCHO DALTO     (deltas; Hpos>0 = derecha, Vpos>0 = abajo)
    #   crt-geometry.py reset
    if len(sys.argv) > 1:
        if sys.argv[1] == "reset":
            g.update(ORIG)
        else:
            g['hfront'] -= int(sys.argv[1]) if len(sys.argv) > 1 else 0
            g['vfront'] -= int(sys.argv[2]) if len(sys.argv) > 2 else 0
            g['hactive'] += int(sys.argv[3]) if len(sys.argv) > 3 else 0
            g['vactive'] += int(sys.argv[4]) if len(sys.argv) > 4 else 0
        g = clamp(g)
        apply(g)
        print("Aplicado: Hpos=%d Vpos=%d ancho=%d alto=%d" %
              (g['hfront'], g['vfront'], g['hactive'], g['vactive']))
        print("Reinicia, o reconecta el DP->HDMI, para verlo.")
        return

    if not sys.stdin.isatty():
        print("Sin terminal. Usar con argumentos, ej: crt-geometry.py 4 0 0 0")
        return

    while True:
        draw(g)
        c = getch()
        if c == "a":
            apply(g)
            print("\033[2J\033[H", end="")
            print("Aplicado. Reinicia (o reconecta el DP->HDMI) para verlo.\r")
            return
        if c == "q":
            return
        if c == "r":
            g.update(ORIG)
        elif c in ("h", "\x1b[D"):
            g['hfront'] += 2
        elif c in ("l", "\x1b[C"):
            g['hfront'] -= 2
        elif c in ("k", "\x1b[A"):
            g['vfront'] += 1
        elif c in ("j", "\x1b[B"):
            g['vfront'] -= 1
        elif c == "u":
            g['hactive'] -= 8
        elif c == "i":
            g['hactive'] += 8
        elif c == "n":
            g['vactive'] -= 4
        elif c == "m":
            g['vactive'] += 4
        g = clamp(g)


if __name__ == "__main__":
    main()
