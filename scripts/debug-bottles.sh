#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
# debug-bottles.sh — Diagnóstico do trydpro no Bottles
# ─────────────────────────────────────────────────────────
#
# Uso:
#   bash scripts/debug-bottles.sh          → modo debug normal
#   bash scripts/debug-bottles.sh --crash  → só mostra crashes/erros críticos
#   bash scripts/debug-bottles.sh --dll    → debug de DLL loading (verbose)
#
# O que faz:
#   1. Encontra o bottle trydpro
#   2. Roda o trydpro.exe com WINEDEBUG detalhado
#   3. Exibe os logs em tempo real no terminal
# ─────────────────────────────────────────────────────────

set -euo pipefail

# ── Configurações ──────────────────────────────────────
BOTTLE_NAME="trydpro"
BOTTLES_DIR="$HOME/.local/share/bottles/bottles"
BOTTLE_PATH="$BOTTLES_DIR/$BOTTLE_NAME"

# Tenta encontrar o executável automaticamente
find_exe() {
  find "$BOTTLE_PATH/drive_c" -iname "tryd*.exe" 2>/dev/null | head -1
}

# ── Verificações ───────────────────────────────────────
if [ ! -d "$BOTTLE_PATH" ]; then
  echo "❌ Bottle '$BOTTLE_NAME' não encontrado em: $BOTTLE_PATH"
  echo ""
  echo "Bottles disponíveis:"
  ls "$BOTTLES_DIR" 2>/dev/null || echo "  (nenhum)"
  exit 1
fi

EXE_PATH=$(find_exe)
if [ -z "$EXE_PATH" ]; then
  echo "❌ Executável tryd*.exe não encontrado em $BOTTLE_PATH/drive_c"
  echo ""
  echo "Procurando todos os .exe no bottle:"
  find "$BOTTLE_PATH/drive_c" -iname "*.exe" 2>/dev/null | grep -v -i "windows\|system32\|syswow64" | head -20
  exit 1
fi

# ── Runner do Bottles ──────────────────────────────────
# Bottles usa seu próprio wine (soda/caffe/wine-ge)
RUNNER_NAME=$(grep -o '"Runner": "[^"]*"' "$BOTTLE_PATH/bottle.yml" 2>/dev/null | cut -d'"' -f4 || echo "")
RUNNERS_DIR="$HOME/.local/share/bottles/runners"
WINE_BIN=""

if [ -n "$RUNNER_NAME" ] && [ -d "$RUNNERS_DIR/$RUNNER_NAME" ]; then
  WINE_BIN="$RUNNERS_DIR/$RUNNER_NAME/bin/wine"
  echo "🍷 Runner: $RUNNER_NAME"
else
  # Fallback: wine do sistema
  WINE_BIN=$(command -v wine 2>/dev/null || echo "")
  echo "⚠️  Runner do Bottles não encontrado, usando wine do sistema"
fi

if [ -z "$WINE_BIN" ] || [ ! -x "$WINE_BIN" ]; then
  echo "❌ Wine não encontrado!"
  exit 1
fi

# ── Modo de debug ───────────────────────────────────────
MODE="${1:---normal}"

case "$MODE" in
  --crash)
    WINEDEBUG="+err,+seh,+loaddll"
    echo "🔍 Modo: apenas crashes e erros críticos"
    ;;
  --dll)
    WINEDEBUG="+loaddll,+module,+err,+seh"
    echo "🔍 Modo: debug de DLL loading (verbose)"
    ;;
  *)
    WINEDEBUG="+err,+warn,+loaddll,+seh,+dotnet"
    echo "🔍 Modo: debug padrão"
    ;;
esac

echo ""
echo "════════════════════════════════════════════════"
echo " Bottle:     $BOTTLE_NAME"
echo " Executável: $(basename $EXE_PATH)"
echo " Wine:       $WINE_BIN"
echo " Log:        /tmp/trydpro-wine-debug.log"
echo "════════════════════════════════════════════════"
echo ""
echo "▶ Iniciando com logs detalhados... (Ctrl+C para parar)"
echo ""

# ── Variáveis para rodar o bottle corretamente ──────────
export WINEPREFIX="$BOTTLE_PATH"
export WINEARCH="win64"
export WINEFSYNC="1"
export WINE_LARGE_ADDRESS_AWARE="1"
# NÃO setar WINEDLLOVERRIDES aqui — deixa o .NET funcionar

# VK_ICD para AMD
export VK_ICD_FILENAMES="/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/radeon_icd.i686.json"

export WINEDEBUG="$WINEDEBUG"

# Roda e salva log simultaneamente
"$WINE_BIN" "$EXE_PATH" 2>&1 | tee /tmp/trydpro-wine-debug.log

echo ""
echo "════════════════════════════════════════════════"
echo "Log salvo em: /tmp/trydpro-wine-debug.log"
echo ""
echo "Para ver erros críticos:"
echo "  grep -E 'err:|Unhandled|crash|FAULT|fixme:dotnet' /tmp/trydpro-wine-debug.log | head -50"
