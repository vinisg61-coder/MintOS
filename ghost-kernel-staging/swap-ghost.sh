#!/bin/bash
# swap-ghost.sh — integra Ghost kernel no MintOS quando liberado
# Uso: ./ghost-kernel-staging/swap-ghost.sh [build|restore]
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAGING="$ROOT/ghost-kernel-staging"
PREBUILT="$ROOT/prebuilts/kernels/a52sxq"
BACKUP="$STAGING/backup-stock"

if [[ "$1" == "restore" ]]; then
    echo "Restaurando kernel stock..."
    cp -f "$BACKUP"/boot.img "$PREBUILT/boot.img"
    cp -f "$BACKUP"/dtbo.img "$PREBUILT/dtbo.img"
    [ -f "$BACKUP/vendor_boot.img" ] && cp -f "$BACKUP/vendor_boot.img" "$PREBUILT/vendor_boot.img" || true
    echo "OK - stock restaurado"
    exit 0
fi

# build mode (default) — espera que ghost já foi buildado em /tmp/ghost-kernel/out
GHOST_OUT="/tmp/ghost-kernel/out/arch/arm64/boot"
if [ ! -d "$GHOST_OUT" ]; then
    GHOST_OUT="/tmp/ghost-kernel/out"
fi

if [ ! -f "$GHOST_OUT/Image" ] && [ ! -f "$STAGING/boot.img" ]; then
    echo "Ghost ainda não buildado. Rode build_reproducible.sh no ghost-kernel primeiro."
    echo "Ou coloque boot.img/dtbo.img manualmente em ghost-kernel-staging/"
    exit 1
fi

mkdir -p "$BACKUP"
echo "Backup stock em $BACKUP"
cp -f "$PREBUILT/boot.img" "$BACKUP/boot.img" 2>/dev/null || true
cp -f "$PREBUILT/dtbo.img" "$BACKUP/dtbo.img" 2>/dev/null || true
cp -f "$PREBUILT/vendor_boot.img" "$BACKUP/vendor_boot.img" 2>/dev/null || true

if [ -f "$STAGING/boot.img" ] && [ -s "$STAGING/boot.img" ]; then
    echo "Usando boot.img de staging"
    cp -f "$STAGING/boot.img" "$PREBUILT/boot.img"
    cp -f "$STAGING/dtbo.img" "$PREBUILT/dtbo.img" 2>/dev/null || true
    [ -f "$STAGING/vendor_boot.img" ] && cp -f "$STAGING/vendor_boot.img" "$PREBUILT/vendor_boot.img" || true
else
    echo "Copiando de $GHOST_OUT"
    cp -f "$GHOST_OUT/Image" "$PREBUILT/boot.img" 2>/dev/null || cp -f "$GHOST_OUT/boot.img" "$PREBUILT/boot.img"
    cp -f "$GHOST_OUT/dtbo.img" "$PREBUILT/dtbo.img" 2>/dev/null || true
    cp -f "$GHOST_OUT/vendor_boot.img" "$PREBUILT/vendor_boot.img" 2>/dev/null || true
fi

echo "OK - Ghost integrado em $PREBUILT"
echo "Agora: source ./buildenv.sh a52sxq && ./scripts/make_rom.sh"
