#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Remove Silence — Remove trechos de silêncio do vídeo        ║
# ║  Uso: ./remove_silence.sh video.mp4 [threshold_dB] [min_s]  ║
# ║  Perfeito para cortar "tempos mortos" de tutoriais.          ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

INPUT="${1:?Uso: $0 <video.mp4> [threshold_dB] [min_silence_seconds]}"
THRESHOLD="${2:--35}"        # dB abaixo do qual é considerado silêncio
MIN_SILENCE="${3:-1.5}"      # Duração mínima de silêncio para cortar (segundos)
BASENAME=$(basename "${INPUT%.*}")
EXT="${INPUT##*.}"
OUTPUT_DIR="$(dirname "$INPUT")/trimmed"
TEMP_DIR=$(mktemp -d)
mkdir -p "$OUTPUT_DIR"

OUTPUT="$OUTPUT_DIR/${BASENAME}_no_silence.${EXT}"

echo "🔇 Detectando silêncio (threshold: ${THRESHOLD}dB, mín: ${MIN_SILENCE}s)..."

# Detecta intervalos de silêncio
SILENCE_LOG="$TEMP_DIR/silence.txt"
ffmpeg -i "$INPUT" -af "silencedetect=noise=${THRESHOLD}dB:d=${MIN_SILENCE}" \
    -f null /dev/null 2>&1 | grep "silence_" > "$SILENCE_LOG" || true

# Parse silence intervals
SEGMENTS_FILE="$TEMP_DIR/segments.txt"
FILTER_FILE="$TEMP_DIR/filter.txt"

# Extrai pares start/end de silêncio
python3 -c "
import re, sys

lines = open('$SILENCE_LOG').read()
starts = [float(x) for x in re.findall(r'silence_start: ([\d.]+)', lines)]
ends = [float(x) for x in re.findall(r'silence_end: ([\d.]+)', lines)]

# Obtém duração total do vídeo
import subprocess
dur = float(subprocess.check_output([
    'ffprobe', '-v', 'error', '-show_entries', 'format=duration',
    '-of', 'csv=p=0', '$INPUT'
]).decode().strip())

# Gera intervalos de NÃO-silêncio (os trechos que queremos manter)
segments = []
prev_end = 0.0
for s, e in zip(starts, ends):
    if s > prev_end + 0.1:
        segments.append((prev_end, s))
    prev_end = e
if prev_end < dur:
    segments.append((prev_end, dur))

if not segments:
    print('Nenhum silêncio detectado', file=sys.stderr)
    sys.exit(1)

# Gera arquivo de segmentos para ffmpeg concat
with open('$SEGMENTS_FILE', 'w') as f:
    for i, (start, end) in enumerate(segments):
        f.write(f'{start},{end}\n')

print(f'Encontrados {len(starts)} trechos de silêncio')
print(f'Mantendo {len(segments)} segmentos de conteúdo')
total_removed = sum(e - s for s, e in zip(starts, ends))
print(f'Removendo ~{total_removed:.1f}s de silêncio')
" || { echo "ℹ Nenhum silêncio significativo encontrado."; cp "$INPUT" "$OUTPUT"; exit 0; }

# Corta e concatena os segmentos
CONCAT_FILE="$TEMP_DIR/concat.txt"
SEG_NUM=0
while IFS=',' read -r START END; do
    SEG_OUT="$TEMP_DIR/seg_$(printf '%04d' $SEG_NUM).${EXT}"
    ffmpeg -y -ss "$START" -to "$END" -i "$INPUT" -c copy \
        -avoid_negative_ts make_zero "$SEG_OUT" 2>/dev/null
    echo "file '$SEG_OUT'" >> "$CONCAT_FILE"
    SEG_NUM=$((SEG_NUM + 1))
done < "$SEGMENTS_FILE"

# Concatena todos os segmentos
ffmpeg -y -f concat -safe 0 -i "$CONCAT_FILE" -c copy "$OUTPUT" 2>/dev/null

# Limpa
rm -rf "$TEMP_DIR"

ORIG_SIZE=$(du -h "$INPUT" | cut -f1)
NEW_SIZE=$(du -h "$OUTPUT" | cut -f1)
echo ""
echo "✅ Silêncio removido: $OUTPUT"
echo "   Original: $ORIG_SIZE → Resultado: $NEW_SIZE"
