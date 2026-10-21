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

# Activar escritura en /boot
if [ -d "/boot" ]; then
  mount -o remount,rw /boot > /dev/null 2>&1
  [ -f "$CMDLINE_FILE" ] && cp -f "$CMDLINE_FILE" "$CMDLINE_BACKUP" > /dev/null 2>&1
  [ -f "$NEW_CMDLINE_FILE" ] && cp -f "$NEW_CMDLINE_FILE" "$CMDLINE_FILE" > /dev/null 2>&1
  mount -o remount,ro /boot > /dev/null 2>&1
fi

# Activar escritura general
mount -o remount,rw / > /dev/null 2>&1

# Copiar archivo binario si existe
if [ -f "$BIN_FILE" ]; then
  mkdir -p "$DEST_BIN_DIR" > /dev/null 2>&1
 cp "$BIN_FILE" "$DEST_BIN_DIR" > /dev/null 2>&1 && echo "               Modo 15khz instalado correctamente"
else
  echo "  Error: No se encontró el archivo $BIN_FILE"
fi

# Volver a solo lectura
mount -o remount,ro / > /dev/null 2>&1

# Borrar overrides de SwitchRes que rompian los juegos
mount -o remount,rw / > /dev/null 2>&1
rm -f "/recalbox/share/system/configs/retroarch/switchres.ini"
rm -f "/recalbox/share/system/.config/retroarch/config/switchres.ini"
rm -f /recalbox/share/system/.config/retroarch/config/*/*.switchres.ini
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
echo "      Luego de reniciar el sistema la salida HDMI emitira"
echo "          video 15khz 60hz compatible con TV CRT RGB."
echo "      Conectar a TV CRT 15kHz con entrada RGB o COMPONENTE "
echo "      usando DAC HDMI a VGA o transcoder HDMI a COMPONENTE."
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