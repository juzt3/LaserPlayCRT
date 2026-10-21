#!/bin/sh

# Mostrar solo inicio
echo ""
echo ""
echo ""
echo "================================================================="
echo "               LASER PLAY CRT HDMI 31khz BETA v8.4               "
echo "================================================================="

# Definir rutas de archivos y carpetas
CMDLINE_FILE="/boot/cmdline.txt"
CMDLINE_BACKUP="/boot/cmdline.txt.backup"
NEW_CMDLINE_FILE="/recalbox/share/laser-config/31script/cmdline.txt"
BIN_FILE="/recalbox/share/laser-config/31script/LASER120.bin"
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
 cp "$BIN_FILE" "$DEST_BIN_DIR" > /dev/null 2>&1 && echo "               Modo 31khz instalado correctamente"
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
ARCHIVOS["/recalbox/share/laser-config/ARCADEres/recalbox31/recalbox.conf"]="/recalbox/share/system/recalbox.conf"

ARCHIVOS["/recalbox/share/laser-config/logo.png"]="/recalbox/system/resources/splash/logo.png"
ARCHIVOS["/recalbox/share/laser-config/logo-version.png"]="/recalbox/system/resources/splash/logo-version.png"
ARCHIVOS["/recalbox/share/laser-config/logo-1.png"]="/recalbox/system/resources/splash/tate/logo-1.png"
ARCHIVOS["/recalbox/share/laser-config/logo-2.png"]="/recalbox/system/resources/splash/tate/logo-2.png"
ARCHIVOS["/recalbox/share/laser-config/logo-3.png"]="/recalbox/system/resources/splash/tate/logo-3.png"

ARCHIVOS["/recalbox/share/laser-config/logo.svg"]="/recalbox/share_init/system/.emulationstation/themes/recalbox-next/ports/data/logo.svg"


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
SOURCE_CFG="/recalbox/share/laser-config/CRT Switchres LASER/FinalBurn Neo2/FinalBurn Neo.cfg"
RECALBOX_RA_CONFIG="/recalbox/share/system/configs/retroarch"

echo "Instalando configuraciones de sistema..."

for SYSTEM_DIR in /recalbox/share/roms/*; do
    [ -d "$SYSTEM_DIR" ] || continue
    SYSTEM=$(basename "$SYSTEM_DIR")
    echo "  $SYSTEM"
    cp -f "$SOURCE_CFG" "$RECALBOX_RA_CONFIG/$SYSTEM.cfg"
done


# Copiar parche FBN a múltiples destinos
DEST_DIR="/recalbox/share/system/configs/retroarch/fbneo"

echo ""
echo "==============================================================="
echo "                      Aplicando parche FBN                     "
echo "==============================================================="
echo ""

mkdir -p "$DEST_DIR"

# ---- MK ----
SOURCE_MK="/recalbox/share/laser-config/parche_fbn/mk.cfg"
FILES_MK=(mk.cfg mk2.cfg mk2chal.cfg mk2r11.cfg mk2r14.cfg mk2r20.cfg mk2r21.cfg mk2r30.cfg mk2r31.cfg mk2r32.cfg mk2r32e.cfg mk2r42.cfg mk2r91.cfg mk3.cfg mk3ghw.cfg mk3p40.cfg mk3r10.cfg mk3r20.cfg)

# ---- KUNGFUM ----
SOURCE_KUNGFUM="/recalbox/share/laser-config/parche_fbn/kungfum.cfg"
FILES_KUNGFUM=(kungfum.cfg kungfuma.cfg kungfumd.cfg)

# ---- Aplicar MK ----
if [ -f "$SOURCE_MK" ]; then
  for file in "${FILES_MK[@]}"; do
    cp -f "$SOURCE_MK" "$DEST_DIR/$file" && echo "  MK -> $file"
  done
else
  echo "Error: no se encontró $SOURCE_MK"
fi

# ---- Aplicar KUNGFUM ----
if [ -f "$SOURCE_KUNGFUM" ]; then
  for file in "${FILES_KUNGFUM[@]}"; do
    cp -f "$SOURCE_KUNGFUM" "$DEST_DIR/$file" && echo "  KUNGFUM -> $file"
  done
else
  echo "Error: no se encontró $SOURCE_KUNGFUM"
fi


# Base
CONFIG_BASE="/recalbox/share/system/configs/retroarch"
DEST_DIRS=("mame")

echo ""
echo "==============================================================="
echo "                     Aplicando parche MAME                     "
echo "==============================================================="
echo ""

# ---- MK ----
SOURCE_MK="/recalbox/share/laser-config/parche_mame/mk.cfg"
FILES_MK=(mk.cfg mk2.cfg mk2chal.cfg mk2r11.cfg mk2r14.cfg mk2r20.cfg mk2r21.cfg mk2r30.cfg mk2r31.cfg mk2r32.cfg mk2r32e.cfg mk2r42.cfg mk2r91.cfg mk3.cfg mk3ghw.cfg mk3p40.cfg mk3r10.cfg mk3r20.cfg)

# ---- KUNGFUM ----
SOURCE_KUNGFUM="/recalbox/share/laser-config/parche_mame/kungfum.cfg"
FILES_KUNGFUM=(kungfum.cfg kungfuma.cfg kungfumd.cfg)

# Crear carpetas una sola vez
for DIR in "${DEST_DIRS[@]}"; do
  mkdir -p "$CONFIG_BASE/$DIR"
done

# ---- Aplicar MK ----
if [ -f "$SOURCE_MK" ]; then
  for DIR in "${DEST_DIRS[@]}"; do
    DEST_PATH="$CONFIG_BASE/$DIR"
    for FILE in "${FILES_MK[@]}"; do
      cp -f "$SOURCE_MK" "$DEST_PATH/$FILE" && echo "  MK -> $DIR/$FILE"
    done
  done
else
  echo "Error: no se encontró $SOURCE_MK"
fi

# ---- Aplicar KUNGFUM ----
if [ -f "$SOURCE_KUNGFUM" ]; then
  for DIR in "${DEST_DIRS[@]}"; do
    DEST_PATH="$CONFIG_BASE/$DIR"
    for FILE in "${FILES_KUNGFUM[@]}"; do
      cp -f "$SOURCE_KUNGFUM" "$DEST_PATH/$FILE" && echo "  KUNGFUM -> $DIR/$FILE"
    done
  done
else
  echo "Error: no se encontró $SOURCE_KUNGFUM"
fi


echo ""
echo "               Parche Aplicando correctamente                "
echo ""




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
echo "  video 31khz 60hz y 31khz 120hz compatible con monitor vga CRT."
echo "           Se conecta mediante un DAC de HDMI a VGA."
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