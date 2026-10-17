#!/bin/sh

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