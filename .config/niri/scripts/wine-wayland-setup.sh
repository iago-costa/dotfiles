#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Wine Wayland Fix — Configure Wine registry to minimize     ║
# ║  keyboard/mouse input grabs on tiling Wayland compositors.  ║
# ║                                                             ║
# ║  Usage: bash wine-wayland-setup.sh [WINEPREFIX]             ║
# ║  Default prefix: ~/.wine                                    ║
# ╚══════════════════════════════════════════════════════════════╝

PREFIX="${1:-$HOME/.wine}"
export WINEPREFIX="$PREFIX"

echo "🔧 Configuring Wine prefix: $PREFIX"
echo ""

# 1. Let window manager control Wine windows (prevents grab)
wine reg add "HKCU\Software\Wine\X11 Driver" /v Managed /t REG_SZ /d Y /f 2>/dev/null
echo "✅ Window manager control: enabled"

# 2. Let window manager decorate windows
wine reg add "HKCU\Software\Wine\X11 Driver" /v Decorated /t REG_SZ /d Y /f 2>/dev/null
echo "✅ Window manager decorations: enabled"

# 3. Disable grab for fullscreen windows (prevents keyboard steal)
wine reg add "HKCU\Software\Wine\X11 Driver" /v GrabFullscreen /t REG_SZ /d N /f 2>/dev/null
echo "✅ Fullscreen grab: disabled"

# 4. Disable mouse warp on focus (reduces grab issues)
wine reg add "HKCU\Software\Wine\X11 Driver" /v GrabPointer /t REG_SZ /d N /f 2>/dev/null
echo "✅ Pointer grab: disabled"

# 5. Disable clip cursor (prevents mouse from being locked)
wine reg add "HKCU\Software\Wine\X11 Driver" /v ClipCursor /t REG_SZ /d N /f 2>/dev/null
echo "✅ Cursor clip: disabled"

# 6. Set DPI to 96 to prevent oversized windows
wine reg add "HKCU\Control Panel\Desktop" /v LogPixels /t REG_DWORD /d 96 /f 2>/dev/null
echo "✅ DPI: 96 (standard)"

# 7. Disable window activation stealing
wine reg add "HKCU\Software\Wine\X11 Driver" /v UseTakeFocus /t REG_SZ /d N /f 2>/dev/null
echo "✅ Focus stealing: disabled"

echo ""
echo "🎉 Done! Wine prefix '$PREFIX' is optimized for Wayland/Niri."
echo ""
echo "To apply to a Lutris game prefix, run:"
echo "  bash $0 ~/.local/share/lutris/runners/wine/PREFIX_PATH"
echo ""
echo "Or find your game's prefix in Lutris:"
echo "  Right-click game → Configure → Game options → Wine prefix"
