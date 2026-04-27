#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Quick Clip — Extrai os últimos N segundos de um vídeo       ║
# ║  Uso: ./quick_clip.sh video.mp4 [segundos]                  ║
# ║  Default: últimos 60 segundos                                ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

INPUT="${1:?Uso: $0 <video> [segundos]}"
SECONDS_BACK="${2:-60}"
OUTPUT_DIR="$(dirname "$INPUT")/clips"
mkdir -p "$OUTPUT_DIR"

# Obtém duração total
DURATION=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$INPUT")
DURATION_INT=$(printf "%.0f" "$DURATION")

if (( SECONDS_BACK >= DURATION_INT )); then
    echo "⚠ Vídeo tem apenas ${DURATION_INT}s. Copiando inteiro."
    SECONDS_BACK=$DURATION_INT
fi

START_TIME=$((DURATION_INT - SECONDS_BACK))
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BASENAME=$(basename "${INPUT%.*}")
OUTPUT="$OUTPUT_DIR/${BASENAME}_clip_${TIMESTAMP}.mp4"

echo "✂ Extraindo últimos ${SECONDS_BACK}s de '${INPUT}'..."
echo "  Início: $(date -u -d @$START_TIME +%H:%M:%S) → Fim: $(date -u -d @$DURATION_INT +%H:%M:%S)"

ffmpeg -y -ss "$START_TIME" -i "$INPUT" \
    -c copy \
    -avoid_negative_ts make_zero \
    "$OUTPUT" 2>/dev/null

echo "✅ Clip salvo: $OUTPUT"
echo "   Duração: ${SECONDS_BACK}s | Tamanho: $(du -h "$OUTPUT" | cut -f1)"
