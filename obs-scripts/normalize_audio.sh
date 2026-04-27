#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Normalize Audio — Normaliza áudio de vídeos gravados        ║
# ║  Uso: ./normalize_audio.sh video.mp4                         ║
# ║  Aplica loudness normalization (EBU R128) para YouTube.      ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

INPUT="${1:?Uso: $0 <video.mp4>}"
BASENAME=$(basename "${INPUT%.*}")
EXT="${INPUT##*.}"
OUTPUT_DIR="$(dirname "$INPUT")/normalized"
mkdir -p "$OUTPUT_DIR"
OUTPUT="$OUTPUT_DIR/${BASENAME}_normalized.${EXT}"

echo "🔊 Analisando níveis de áudio..."
# Fase 1: Medir loudness atual
STATS=$(ffmpeg -i "$INPUT" -af loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json -f null /dev/null 2>&1 | \
    grep -A 20 '"input_i"')

INPUT_I=$(echo "$STATS" | grep '"input_i"' | grep -oP '[-\d.]+')
INPUT_TP=$(echo "$STATS" | grep '"input_tp"' | grep -oP '[-\d.]+')
INPUT_LRA=$(echo "$STATS" | grep '"input_lra"' | grep -oP '[-\d.]+')
INPUT_THRESH=$(echo "$STATS" | grep '"input_thresh"' | grep -oP '[-\d.]+')

echo "  Loudness atual: ${INPUT_I} LUFS (target: -16 LUFS para YouTube)"
echo "  True Peak: ${INPUT_TP} dBTP"

# Fase 2: Aplicar normalização com os valores medidos
echo "🎚 Normalizando para -16 LUFS (padrão YouTube)..."
ffmpeg -y -i "$INPUT" \
    -af "loudnorm=I=-16:TP=-1.5:LRA=11:measured_I=${INPUT_I}:measured_TP=${INPUT_TP}:measured_LRA=${INPUT_LRA}:measured_thresh=${INPUT_THRESH}:linear=true" \
    -c:v copy \
    "$OUTPUT" 2>/dev/null

echo "✅ Áudio normalizado: $OUTPUT"
echo "   Tamanho: $(du -h "$OUTPUT" | cut -f1)"
