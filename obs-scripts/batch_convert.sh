#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Batch Convert — Converte vídeos para formato YouTube/TikTok ║
# ║  Uso: ./batch_convert.sh <pasta> [formato]                  ║
# ║  Formatos: youtube (1080p H.264) | tiktok (1080x1920 9:16)  ║
# ╚══════════════════════════════════════════════════════════════╝
set -euo pipefail

INPUT_DIR="${1:?Uso: $0 <pasta_de_videos> [youtube|tiktok]}"
FORMAT="${2:-youtube}"

OUTPUT_DIR="${INPUT_DIR}/converted_${FORMAT}"
mkdir -p "$OUTPUT_DIR"

echo "🎬 Convertendo vídeos em '${INPUT_DIR}' → formato: ${FORMAT}"
echo ""

COUNT=0
ERRORS=0

for VIDEO in "$INPUT_DIR"/*.{mp4,mkv,mov,avi,webm} 2>/dev/null; do
    [ -f "$VIDEO" ] || continue
    BASENAME=$(basename "${VIDEO%.*}")
    OUTPUT="$OUTPUT_DIR/${BASENAME}.mp4"

    if [ -f "$OUTPUT" ]; then
        echo "⏭ Pulando (já existe): $BASENAME"
        continue
    fi

    echo "🔄 Convertendo: $BASENAME..."

    case "$FORMAT" in
        youtube)
            # 1080p, H.264, AAC, otimizado para streaming
            ffmpeg -y -i "$VIDEO" \
                -c:v libx264 -preset medium -crf 20 \
                -c:a aac -b:a 192k -ar 48000 \
                -vf "scale=-2:1080" \
                -movflags +faststart \
                -pix_fmt yuv420p \
                "$OUTPUT" 2>/dev/null && \
                COUNT=$((COUNT + 1)) || ERRORS=$((ERRORS + 1))
            ;;
        tiktok)
            # 9:16 vertical, 1080x1920, H.264
            ffmpeg -y -i "$VIDEO" \
                -c:v libx264 -preset medium -crf 22 \
                -c:a aac -b:a 128k -ar 44100 \
                -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black" \
                -movflags +faststart \
                -pix_fmt yuv420p \
                -t 180 \
                "$OUTPUT" 2>/dev/null && \
                COUNT=$((COUNT + 1)) || ERRORS=$((ERRORS + 1))
            ;;
        *)
            echo "❌ Formato desconhecido: $FORMAT (use 'youtube' ou 'tiktok')"
            exit 1
            ;;
    esac
done

echo ""
echo "════════════════════════════════════════"
echo "✅ Convertidos: $COUNT | ❌ Erros: $ERRORS"
echo "📁 Saída: $OUTPUT_DIR"
