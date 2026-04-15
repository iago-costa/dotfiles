{ lib, stdenv, fetchurl, makeWrapper, makeDesktopItem, copyDesktopItems, dpkg
, gtk3, libxkbcommon, nss, alsa-lib, libdrm, mesa, libxshmfence
, libxcb, xorg, at-spi2-atk, at-spi2-core, cups, pango, cairo
, gdk-pixbuf, glib, dbus, expat, nspr, systemd, libGL
# Wayland
, wayland, pipewire }:

let
  version = "2.3.13344";
  description = "AI-powered IDE by ByteDance — The Real AI Engine";
in stdenv.mkDerivation {
  pname = "trae";
  inherit version;

  src = fetchurl {
    url = "https://lf-cdn.trae.ai/obj/trae-ai-us/pkg/app/releases/stable/${version}/linux/Trae-linux-x64.deb";
    sha256 = "6af50c118c57acdae151419f02bf6090ab509489611803844b50731c93e9ecae";
  };

  nativeBuildInputs = [ dpkg makeWrapper copyDesktopItems ];

  buildInputs = [
    gtk3 libxkbcommon nss alsa-lib libdrm mesa libxshmfence
    libxcb xorg.libX11 xorg.libXcomposite xorg.libXdamage xorg.libXext
    xorg.libXfixes xorg.libXrandr xorg.libxshmfence xorg.libXtst
    xorg.libxcb xorg.libXScrnSaver
    at-spi2-atk at-spi2-core cups pango cairo gdk-pixbuf glib
    dbus expat nspr systemd libGL
    wayland pipewire
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "trae";
      exec = "trae %F";
      icon = "trae";
      desktopName = "Trae";
      genericName = description;
      categories = [ "Development" "IDE" "TextEditor" ];
      startupNotify = true;
      mimeTypes = [ "x-scheme-handler/trae" ];
    })
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,share/trae,share/icons}

    # Copy the application
    cp -r usr/share/trae/* $out/share/trae/

    # Copy icons if present
    if [ -d usr/share/icons ]; then
      cp -r usr/share/icons/* $out/share/icons/
    fi
    if [ -d usr/share/pixmaps ]; then
      mkdir -p $out/share/pixmaps
      cp -r usr/share/pixmaps/* $out/share/pixmaps/
    fi

    # Symlink the main binary
    ln -s $out/share/trae/bin/trae $out/bin/trae

    runHook postInstall
  '';

  postFixup = let
    libraryPath = lib.makeLibraryPath buildInputs;
  in ''
    # Patch the main binary
    patchelf \
      --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
      --set-rpath "${libraryPath}" \
      $out/share/trae/trae

    # Patch chrome-sandbox
    if [ -f $out/share/trae/chrome-sandbox ]; then
      patchelf \
        --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
        $out/share/trae/chrome-sandbox
      chmod 4755 $out/share/trae/chrome-sandbox
    fi

    # Patch all .so files in the package
    for lib_file in $(find $out/share/trae -name "*.so*" -type f); do
      patchelf --set-rpath "${libraryPath}" "$lib_file" 2>/dev/null || true
    done

    # Wrap with Wayland flags for Niri
    wrapProgram $out/bin/trae \
      --prefix LD_LIBRARY_PATH : "${libraryPath}" \
      --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland"
  '';

  meta = {
    inherit description;
    homepage = "https://trae.ai";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "trae";
  };
}
