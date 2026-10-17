#!/bin/sh
# Diagnostico de video. Deja el resultado en /recalbox/share/laser-config/diag.txt
# (esta en la particion FAT, se lee desde Windows).

OUT="/recalbox/share/laser-config/diag.txt"

{
  echo "===== fecha ====="
  date
  echo
  echo "===== /boot/cmdline.txt ====="
  cat /boot/cmdline.txt 2>/dev/null
  echo
  echo "===== EDID instalado ====="
  ls -l /lib/firmware/LASER*.bin 2>/dev/null
  echo
  echo "===== conectores DRM ====="
  for c in /sys/class/drm/card*-HDMI*/; do
    [ -d "$c" ] || continue
    echo "-- $c"
    echo "status      : $(cat $c/status 2>/dev/null)"
    echo "mode actual : $(cat $c/mode 2>/dev/null)"
    echo "modes:"
    cat $c/modes 2>/dev/null
    echo
  done
  echo "===== tvservice ====="
  tvservice -s 2>/dev/null || echo "(no hay tvservice)"
  echo
  echo "===== fbset ====="
  fbset 2>/dev/null || echo "(no hay fbset)"
  echo
  echo "===== overrides switchres presentes ====="
  ls -l /recalbox/share/system/.config/retroarch/config/*/*.switchres.ini 2>/dev/null || echo "(ninguno)"
  echo
  echo "===== switchres.ini global ====="
  ls -l /recalbox/share/system/configs/retroarch/switchres.ini 2>/dev/null || echo "(ninguno)"
  echo
  echo "===== FinalBurn Neo.cfg ====="
  cat "/recalbox/share/system/.config/retroarch/config/FinalBurn Neo/FinalBurn Neo.cfg" 2>/dev/null
  echo
  echo "===== Snes9x.cfg ====="
  cat "/recalbox/share/system/.config/retroarch/config/Snes9x/Snes9x.cfg" 2>/dev/null
  echo
  echo "===== recalbox.conf (videomode/ratio) ====="
  grep -Ei "videomode|ratio|es\.|force" /recalbox/share/system/recalbox.conf 2>/dev/null
} > "$OUT" 2>&1

echo "Resultado en $OUT"
