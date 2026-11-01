#!/bin/sh
# Diagnostico CRT. Deja el resultado en /recalbox/share/laser-config/diag.txt
# (esta en la particion share, se lee desde Windows).

OUT="/recalbox/share/laser-config/diag.txt"

{
  echo "===== fecha ====="
  date
  echo
  echo "===== plataforma ====="
  uname -a
  echo
  echo "===== /proc/cmdline (aqui se ve si el EDID llego al kernel) ====="
  cat /proc/cmdline
  echo
  echo "===== EDID instalado en /lib/firmware ====="
  ls -l /lib/firmware/LASER*.bin 2>/dev/null || echo "(no hay LASER*.bin en /lib/firmware)"
  echo
  echo "===== conectores DRM ====="
  for c in /sys/class/drm/card*-*/; do
    [ -d "$c" ] || continue
    echo "-- $(basename "$c")"
    echo "status  : $(cat "$c/status" 2>/dev/null)"
    echo "enabled : $(cat "$c/enabled" 2>/dev/null)"
    echo "modes:"
    cat "$c/modes" 2>/dev/null
    echo
  done
  echo "===== dmesg: edid / i915 / firmware ====="
  dmesg 2>/dev/null | grep -iE "edid|i915|firmware|framebuffer" | tail -n 80 || echo "(sin dmesg)"
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
  echo "===== recalbox.conf (videomode/ratio/es) ====="
  grep -Ei "videomode|ratio|es\.|force" /recalbox/share/system/recalbox.conf 2>/dev/null
  echo
  echo "===== grub activo (boot) ====="
  grep -H "linux" /boot/grub/grub.cfg /boot/EFI/BOOT/grub.cfg 2>/dev/null
} > "$OUT" 2>&1

echo "Resultado en $OUT"
