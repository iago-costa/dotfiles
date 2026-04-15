{ lib, stdenv, fetchurl, makeWrapper, makeDesktopItem, copyDesktopItems, autoPatchelfHook
, gtk3, libxkbcommon, nss, alsa-lib, libdrm, mesa, libxshmfence
, libxcb, xorg, at-spi2-atk, at-spi2-core, cups, pango, cairo
, gdk-pixbuf, glib, dbus, expat, nspr, systemd, libGL
# Wayland
, wayland, pipewire
# RPM extraction
, rpmextract, cpio }:

let
  description = "AI-powered agentic coding platform by Alibaba";
in stdenv.mkDerivation {
  pname = "qoder";
  # Rolling "latest" release — update hash after each upstream push
  version = "latest";

  src = fetchurl {
    url = "https://download.qoder.com/release/latest/qoder_x86_64.rpm";
    # NOTE: Qoder uses a rolling "latest" URL with no versioned releases.
    # If this hash becomes stale, run:
    #   nix-prefetch-url https://download.qoder.com/release/latest/qoder_x86_64.rpm
    # and replace the hash below with the new one from the error output.
    sha256 = "0000000000000000000000000000000000000000000000000000";
  };

  nativeBuildInputs = [ makeWrapper copyDesktopItems autoPatchelfHook rpmextract cpio ];

  buildInputs = [
    gtk3 libxkbcommon nss alsa-lib libdrm mesa libxshmfence
    libxcb xorg.libX11 xorg.libXcomposite xorg.libXdamage xorg.libXext
    xorg.libXfixes xorg.libXrandr xorg.libxshmfence xorg.libXtst
    xorg.libxcb xorg.libXScrnSaver
    at-spi2-atk at-spi2-core cups pango cairo gdk-pixbuf glib
    dbus expat nspr systemd libGL
    wayland pipewire stdenv.cc.cc.lib
  ];

  unpackPhase = ''
    rpmextract $src
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "qoder";
      exec = "qoder %F";
      icon = "qoder";
      desktopName = "Qoder";
      genericName = description;
      categories = [ "Development" "IDE" "TextEditor" ];
      startupNotify = true;
      mimeTypes = [ "x-scheme-handler/qoder" ];
    })
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,share/qoder,share/icons}

    # Copy the application from extracted RPM
    if [ -d usr/share/qoder ]; then
      cp -r usr/share/qoder/* $out/share/qoder/
    fi

    # Copy icons
    if [ -d usr/share/pixmaps ]; then
      mkdir -p $out/share/pixmaps
      cp -r usr/share/pixmaps/* $out/share/pixmaps/
    fi
    if [ -d usr/share/icons ]; then
      cp -r usr/share/icons/* $out/share/icons/
    fi

    # Create main binary wrapper
    ln -s $out/share/qoder/bin/qoder $out/bin/qoder

    # Tunnel tool if present
    if [ -f $out/share/qoder/bin/qoder-tunnel ]; then
      ln -s $out/share/qoder/bin/qoder-tunnel $out/bin/qoder-tunnel
    fi

    runHook postInstall
  '';

  postFixup = let
    libraryPath = lib.makeLibraryPath buildInputs;
  in ''
    # Wrap with Wayland flags for Niri
    wrapProgram $out/bin/qoder \
      --prefix LD_LIBRARY_PATH : "${libraryPath}" \
      --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland"
  '';

  meta = {
    inherit description;
    homepage = "https://qoder.com";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "qoder";
  };
}
