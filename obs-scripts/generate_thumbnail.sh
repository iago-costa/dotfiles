#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Generate Thumbnail — Gera thumbnail profissional            ║
# ║  Uso: ./generate_thumbnail.sh video.mp4 [timestamp]          ║
# ║  Default: extrai frame dos 30% do vídeo (geralmente o melhor)║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

INPUT="${1:?Uso: $0 <video.mp4> [HH:MM:SS]}"
BASENAME=$(basename "${INPUT%.*}")
OUTPUT_DIR="$(dirname "$INPUT")/thumbnails"
mkdir -p "$OUTPUT_DIR"

# Se timestamp fornecido, usa ele; senão calcula 30% do vídeo
if [ -n "${2:-}" ]; then
    TIMESTAMP="$2"
else
    DURATION=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$INPUT")
    SEEK=$(echo "$DURATION * 0.3" | bc)
    TIMESTAMP=$(printf "%.0f" "$SEEK")
fi

TIMESTAMP_CLEAN=$(echo "$TIMESTAMP" | tr ':' '-')
OUTPUT="$OUTPUT_DIR/${BASENAME}_thumb_${TIMESTAMP_CLEAN}.png"

echo "🖼 Extraindo frame em ${TIMESTAMP}..."

# Extrai frame em alta qualidade
ffmpeg -y -ss "$TIMESTAMP" -i "$INPUT" \
    -vframes 1 \
    -q:v 2 \
    "$OUTPUT" 2>/dev/null

# Gera versão 1280x720 (YouTube standard)
OUTPUT_YT="$OUTPUT_DIR/${BASENAME}_thumb_1280x720.jpg"
ffmpeg -y -i "$OUTPUT" \
    -vf "scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2:black" \
    -q:v 2 \
    "$OUTPUT_YT" 2>/dev/null

echo "✅ Thumbnails gerados:"
echo "   Original: $OUTPUT"
echo "   YouTube (1280x720): $OUTPUT_YT"
echo "   Dica: Abra no GIMP/Inkscape para adicionar texto e elementos visuais"
