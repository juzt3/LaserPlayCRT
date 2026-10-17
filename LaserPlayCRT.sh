#!/bin/bash

# Espera para asegurar que /share esté listo
sleep 5

# Archivos origen
FILE1="/recalbox/share/laser-config/ARCADEres/TVcrtARCADE15.sh"
FILE2="/recalbox/share/laser-config/ARCADEres/MONITORcrtPC31.sh"

# Destino
DEST="/recalbox/share/userscripts/manual"

# Crear carpeta destino si no existe
mkdir -p "$DEST"

# Copia inteligente (solo si cambian o no existen)
cp -u "$FILE1" "$DEST"
cp -u "$FILE2" "$DEST"