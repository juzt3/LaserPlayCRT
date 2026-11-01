#!/bin/sh

# Mostrar solo inicio
echo ""
echo ""
echo ""
echo "=================================================================="
echo "               LASER PLAY CRT HDMI 15khz v8.4                     "
echo "=================================================================="

# Definir rutas de archivos y carpetas
CMDLINE_FILE="/boot/cmdline.txt"
CMDLINE_BACKUP="/boot/cmdline.txt.backup"
NEW_CMDLINE_FILE="/recalbox/share/laser-config/480iscript/cmdline.txt"
BIN_FILE="/recalbox/share/laser-config/480iscript/LASER480.bin"
DEST_BIN_DIR="/lib/firmware"

ARCH="$(uname -m)"
IS_PC=0

# Arranque: Raspberry Pi usa /boot/cmdline.txt; Recalbox PC (x86) usa GRUB.
case "$ARCH" in
  x86_64|i686|i386|amd64)
    IS_PC=1
    echo "  Plataforma x86 (Recalbox PC)"
    # EDID propio de PC (720x480i 13.5MHz, sin modos PAL) y args de GRUB que si funcionaron.
    PC_EDID="/recalbox/share/laser-config/ARCADEres/LASER480-pc.bin"

    # Detectar el conector con sink usando el EDID cacheado (no dispara AUX/probe).
    # Se prefiere un conector HDMI; fallback: primero con EDID; si no, HDMI-A-1.
    EDID_CONN=""
    for c in /sys/class/drm/card*-*/; do
      [ -s "$c/edid" ] || continue
      n=$(basename "$c"); n=${n#card[0-9]*-}
      case "$n" in *HDMI*) EDID_CONN=$n; break ;; esac
    done
    if [ -z "$EDID_CONN" ]; then
      for c in /sys/class/drm/card*-*/; do
        [ -s "$c/edid" ] || continue
        n=$(basename "$c"); n=${n#card[0-9]*-}
        EDID_CONN=$n; break
      done
    fi
    [ -n "$EDID_CONN" ] || EDID_CONN="HDMI-A-1"
    echo "  Conector detectado: $EDID_CONN"

    EDID_ARG="firmware_class.path=/boot video=$EDID_CONN:e drm.edid_firmware=$EDID_CONN:LASER480.bin"

    mount -o remount,rw /boot > /dev/null 2>&1
    if [ -f "$PC_EDID" ]; then
      cp -f "$PC_EDID" /boot/LASER480.bin && echo "  EDID -> /boot/LASER480.bin"
    else
      echo "  AVISO: falta $PC_EDID"
    fi

    # GRUB (BIOS y EFI): limpiar args viejos y agregar los nuevos a la linea linux
    for g in /boot/boot/grub/grub.cfg /boot/grub/grub.cfg /boot/EFI/BOOT/grub.cfg /boot/boot/EFI/BOOT/grub.cfg; do
      [ -f "$g" ] || continue
      cp -f "$g" "$g.bak.laser" 2>/dev/null
      sed -i "s| *firmware_class.path=[^ ]*||g; s| *video=[^ ]*:e||g; s| *drm.edid_firmware=[^ ]*||g" "$g"
      sed -i "s|^\([[:space:]]*linux .*\)$|\1 $EDID_ARG|" "$g" && echo "  GRUB -> $g"
    done

    # boot.md5: recalcular para que Recalbox no revierta los grub.cfg
    if [ -f /boot/boot.md5 ]; then
      for f in ./boot/grub/grub.cfg ./EFI/BOOT/grub.cfg; do
        real="/boot/${f#./}"
        [ -f "$real" ] || continue
        n=$(md5sum "$real" 2>/dev/null | awk '{print $1}')
        [ -n "$n" ] && awk -v h="$n" -v p="$f" 'BEGIN{OFS="  "} { if ($2==p) $1=h; print }' /boot/boot.md5 > /boot/boot.md5.tmp && mv -f /boot/boot.md5.tmp /boot/boot.md5
      done
      echo "  boot.md5 actualizado"
    fi
    mount -o remount,ro /boot > /dev/null 2>&1
    ;;
  *)
    echo "  Plataforma: Raspberry Pi (ARM)"
    # EDID del Pi (con sus modos PAL) -> /lib/firmware
    BIN_FILE="/recalbox/share/laser-config/480iscript/LASER480.bin"
    DEST_BIN_DIR="/lib/firmware"
    # Activar escritura en /boot
    if [ -d "/boot" ]; then
      mount -o remount,rw /boot > /dev/null 2>&1
      [ -f "$CMDLINE_FILE" ] && cp -f "$CMDLINE_FILE" "$CMDLINE_BACKUP" > /dev/null 2>&1
      [ -f "$NEW_CMDLINE_FILE" ] && cp -f "$NEW_CMDLINE_FILE" "$CMDLINE_FILE" > /dev/null 2>&1
      mount -o remount,ro /boot > /dev/null 2>&1
    fi
    ;;
esac

# Activar escritura general
mount -o remount,rw / > /dev/null 2>&1

# Copiar archivo binario (solo ARM; en PC ya se copio el EDID propio a /boot)
if [ "$IS_PC" = "0" ] && [ -f "$BIN_FILE" ]; then
  mkdir -p "$DEST_BIN_DIR" > /dev/null 2>&1
  cp "$BIN_FILE" "$DEST_BIN_DIR" > /dev/null 2>&1 && echo "               Modo 15khz instalado correctamente"
else
  [ "$IS_PC" = "0" ] && echo "  Error: No se encontró el archivo $BIN_FILE"
fi

# Volver a solo lectura
mount -o remount,ro / > /dev/null 2>&1

# Borrar overrides de SwitchRes que rompian los juegos
mount -o remount,rw / > /dev/null 2>&1
rm -f "/recalbox/share/system/configs/retroarch/switchres.ini"
rm -f "/recalbox/share/system/.config/retroarch/config/switchres.ini"
rm -f /recalbox/share/system/.config/retroarch/config/*/*.switchres.ini

# Kodi: configgen pierde el flag de entrelazado y fuerza 480p (31kHz).
# En 15kHz forzamos 480i para que el CRT pueda sincronizar.
KODI_RES="/usr/lib/python3/site-packages/configgen/generators/kodi/kodiResolution.py"
[ -f "$KODI_RES" ] || KODI_RES=$(ls /usr/lib/python3*/site-packages/configgen/generators/kodi/kodiResolution.py 2>/dev/null | head -n 1)
if [ -n "$KODI_RES" ] && [ -f "$KODI_RES" ]; then
  sed -i 's/"p" if resolution.progressive else "i"/"i" if resolution.height > 288 else "p"/' "$KODI_RES" \
    && echo "               Kodi: 480i forzado en 15kHz"
fi
mount -o remount,ro / > /dev/null 2>&1
echo "               Overrides SwitchRes viejos eliminados"



echo ""
echo "================================================================="
echo "              APLICANDO CONFIGURACION de TEMA CRT                     "
echo "================================================================="
echo "                Tema CRT aplicado correctamente                  "

# Lista de archivos a reemplazar: origen => destino
declare -A ARCHIVOS
ARCHIVOS["/recalbox/share/laser-config/ARCADEres/retroarchcustom.cfg"]="/recalbox/share/system/configs/retroarch/retroarchcustom.cfg"
ARCHIVOS["/recalbox/share/laser-config/ARCADEres/es_settings.cfg"]="/recalbox/share_init/system/.emulationstation/es_settings.cfg"
ARCHIVOS["/recalbox/share/laser-config/ARCADEres/recalbox.conf"]="/recalbox/share/system/recalbox.conf"

ARCHIVOS["/recalbox/share/laser-config/logo.png"]="/recalbox/system/resources/splash/logo.png"
ARCHIVOS["/recalbox/share/laser-config/logo-version.png"]="/recalbox/system/resources/splash/logo-version.png"
ARCHIVOS["/recalbox/share/laser-config/logo-1.png"]="/recalbox/system/resources/splash/tate/logo-1.png"
ARCHIVOS["/recalbox/share/laser-config/logo-2.png"]="/recalbox/system/resources/splash/tate/logo-2.png"
ARCHIVOS["/recalbox/share/laser-config/logo-3.png"]="/recalbox/system/resources/splash/tate/logo-3.png"


# Asegurar escritura
mount -o remount,rw / > /dev/null 2>&1
mount -o remount,rw /boot > /dev/null 2>&1

# Reemplazar archivos con backup
for ORIGEN in "${!ARCHIVOS[@]}"; do
  DESTINO="${ARCHIVOS[$ORIGEN]}"
  if [ -f "$ORIGEN" ]; then
    [ -f "$DESTINO" ] && cp -f "$DESTINO" "${DESTINO}.bak"
    mkdir -p "$(dirname "$DESTINO")"
    cp -f "$ORIGEN" "$DESTINO"
  fi
done

# ------------------------------------------------------------------
# PC (x86): ajustes propios de la mini PC
# ------------------------------------------------------------------
if [ "$IS_PC" = "1" ]; then
  RC="/recalbox/share/system/recalbox.conf"
  if [ -f "$RC" ]; then
    # es.videomode tiene que coincidir con el modo (720x480 = 4:3 como el Pi)
    sed -i 's|^system\.es\.videomode=.*|system.es.videomode=720x480|' "$RC"
    # conservar el theme que el usuario ya eligio (no imponer ninguno)
    OLD_THEME=$(grep -m1 '^emulationstation\.theme\.folder=' "${RC}.bak" 2>/dev/null)
    [ -n "$OLD_THEME" ] && sed -i "s|^emulationstation\.theme\.folder=.*|$OLD_THEME|" "$RC"
    echo "  es.videomode=720x480"
  fi

  # Herramientas para centrar/mover la imagen (userscripts manuales)
  TOOLS="/recalbox/share/laser-config/ARCADEres"
  MAN="/recalbox/share/userscripts/manual"
  mkdir -p "$MAN"
  cp -f "$TOOLS/crt-geometry.py" "$MAN/" 2>/dev/null

  mk_script() {
    printf '#!/bin/sh\npython3 /recalbox/share/userscripts/manual/crt-geometry.py %s >> /recalbox/share/laser-config/crt-pos.txt 2>&1\n' "$1" > "$MAN/$2"
  }
  mk_script "4 0 0 0"   crt-derecha.sh
  mk_script "-4 0 0 0"  crt-izquierda.sh
  mk_script "0 2 0 0"   crt-abajo.sh
  mk_script "0 -2 0 0"  crt-arriba.sh
  mk_script "0 0 -8 0"  crt-ancho-menos.sh
  mk_script "0 0 8 0"   crt-ancho-mas.sh
  mk_script "0 0 0 -4"  crt-alto-menos.sh
  mk_script "0 0 0 4"   crt-alto-mas.sh
  mk_script "reset"     crt-reset.sh
  # Limpieza: ya no se usa un userscript de arranque (es.videomode lo fija el instalador)
  rm -f /recalbox/share/userscripts/start.sh
  echo "  Herramientas de geometria instaladas (userscripts/manual)"
fi

# Volver a solo lectura (opcional)
mount -o remount,ro / > /dev/null 2>&1
mount -o remount,ro /boot > /dev/null 2>&1




CONFIG_BASE="/recalbox/share/system/.config/retroarch/config"

echo ""
echo "==============================================================="
echo "                LIMPIANDO CONFIG RETROARCH                     "
echo "==============================================================="
echo ""

if [ -d "$CONFIG_BASE" ]; then
  for dir in "$CONFIG_BASE"/*; do
    # Obtener nombre de la carpeta
    name=$(basename "$dir")

    if [ "$name" != "remaps" ]; then
      echo "Eliminando: $name"
      rm -rf "$dir"
    else
      echo "Conservando: remaps"
    fi
  done
else
  echo "Error: no existe $CONFIG_BASE"
fi

echo ""
echo "Limpieza completa."







echo "                                                "
echo "================================================================="
echo "                   Generando configuraciones                      "
echo "================================================================="
echo "                                                "


# Copiar configuracion LASER a los sistemas de Recalbox
# Recalbox 10.1 lee los overrides por sistema en configs/retroarch/<sistema>.cfg
SOURCE_CFG="/recalbox/share/laser-config/CRT Switchres LASER/FinalBurn Neo/FinalBurn Neo.cfg"
SOURCE_SW="/recalbox/share/laser-config/ARCADEres/switchres.ini"
RECALBOX_RA_CONFIG="/recalbox/share/system/configs/retroarch"
RA_NATIVE_CONFIG="/recalbox/share/system/.config/retroarch/config"

# switchres.ini por core: sin esto el Pi genera modelines con dotclock muy bajo
# y los ajustes de ancho (h_size) no se aplican.
CORE_NAMES="/recalbox/share/system/configs/retroarch.corenames"
[ -f "$CORE_NAMES" ] || CORE_NAMES="/recalbox/system/resources/retroarch.corenames"

echo "Instalando configuraciones de sistema..."

if [ -f "$CORE_NAMES" ]; then
  while IFS=';' read -r CORE _REST || [ -n "$CORE" ]; do
    [ -n "$CORE" ] || continue
    mkdir -p "$RA_NATIVE_CONFIG/$CORE"
    cp -f "$SOURCE_SW" "$RA_NATIVE_CONFIG/$CORE/$CORE.switchres.ini"
  done < "$CORE_NAMES"
fi

for SYSTEM_DIR in /recalbox/share/roms/*; do
    [ -d "$SYSTEM_DIR" ] || continue
    SYSTEM=$(basename "$SYSTEM_DIR")
    echo "  $SYSTEM"
    cp -f "$SOURCE_CFG" "$RECALBOX_RA_CONFIG/$SYSTEM.cfg"
done

echo ""
echo ""
echo ""
echo "             CONFIGURACIONES CREADAS CORRECTAMENTE.  "
echo ""
echo ""
echo ""
echo "================================================================"
echo "       Proceso completado con exito, reinicie el sistema.       "
echo "================================================================"
echo ""
echo "                      -----IMPORTANTE-----                           "
echo ""
if [ "$IS_PC" = "1" ]; then
  echo "      En PC (x86) el EDID se aplica sobre el conector HDMI-A-1"
  echo "      (puerto DP++ con adaptador DP->HDMI) y la imagen sale"
  echo "      a 15 kHz (720x480i, 4:3 como las consolas)."
  echo "      Si no hay imagen, reconecta el cable DP->HDMI o ajusta"
  echo "      'video=HDMI-A-1:e' en /boot/grub/grub.cfg si tu puerto"
  echo "      se llama distinto (ls /sys/class/drm/)."
  echo "      Para centrar: Userscripts manuales crt-derecha/izquierda/"
  echo "      arriba/abajo/ancho/alto (se acumulan; se ve al reconectar"
  echo "      el cable o reiniciar)."
else
  echo "      Luego de reniciar el sistema la salida HDMI emitira"
  echo "          video 15khz 60hz compatible con TV CRT RGB."
  echo "      Conectar a TV CRT 15kHz con entrada RGB o COMPONENTE "
  echo "      usando DAC HDMI a VGA o transcoder HDMI a COMPONENTE."
fi
echo ""
echo "             Que lo disfrutes, Laser Play Arcades"
echo ""
echo "" 
echo "                  Este script NO ES OFICIAL,"
echo "  y no tiene relacion con el equipo de desarrollo de Recalbox."
echo ""
echo "      MAS INFO EN https://www.youtube.com/@laserplayarcades"
echo ""
echo ""
