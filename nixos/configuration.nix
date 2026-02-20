# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, ... }:
let
  # Config to install android sdk

  baseconfig = { 
    allowUnfree = true; 
    #allowBroken = true;
    vivaldi = {
        proprietaryCodecs = true;
        enableWideVine = true;
    };
    permittedInsecurePackages = [
        "electron-27.3.11"
        "qtwebengine-5.15.19"
    ];
    android_sdk.accept_license = true;
    android_sdk.accept_android_sdk_licenses = true;  
  };
  anydesk = pkgs.callPackage /etc/nixos/anydesk.nix {};

  stable = import <nixos-25.11> { config = baseconfig; };
  unstable = import <nixos> { config = baseconfig; };
  deprecated = import <nixos-25.05> { config = baseconfig; };
in
{
  nix.settings.trusted-users = [ "root" "zen" ];
  # Enable experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.substituters = [ "https://cache.nixos.org/" ];
  nix.settings.trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "qtwebengine-5.15.19"
  ];

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # ./hybrid-sleep-and-hibernate.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel parameters for performance optimization
  boot.kernel.sysctl = {
    # Gaming / application support
    "vm.max_map_count" = 2147483642;
    "fs.file-max" = 524288;
    
    # Memory management - prefer RAM over swap
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
    
    # Disk I/O optimization - write dirty pages earlier for SSD longevity
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
  };

  # Set your time zone.
  time.timeZone = "America/Belem";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkbOptions in tty.
  # };
  
  # Enable the ClamAV antivirus daemon and updater.
  services.clamav.daemon.enable = true;
  services.clamav.updater.enable = true;

  security.rtkit.enable = true;
  security.polkit.enable = true;  # Required for Quickshell/Niri network management
  
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;
    wireplumber.enable = true;
  };

  services.upower = {
    enable = true;
    usePercentageForPolicy = true;
    percentageAction = 15;
    criticalPowerAction = "Ignore";
    allowRiskyCriticalPowerAction = true;
  };

  # Enable PAM integration for automatic unlocking (example for greetd)
  security.pam.services.login.enableGnomeKeyring = true;
  services.gnome.gnome-keyring.enable = true;
  services.gvfs.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  # flatpak to install additional apps if needed
  services.flatpak.enable = true; 
  services.dbus.enable = true;

  environment.xfce.excludePackages = [ 
    stable.xfce.xfwm4
    stable.xfce.xfce4-panel
    stable.xfce.xfce4-power-manager
    stable.xfce.xfce4-terminal
    stable.xfce.xfce4-whiskermenu-plugin
    stable.xfce.thunar
  ];

  # Spice VDAgent
  services.spice-vdagentd.enable = true;

  # Enable the X11 windowing system.
  services.displayManager.defaultSession = "niri";
  services.xserver = {
    enable = true;   
    desktopManager = {
      #xterm.enable = false;
      xfce = {
         enable = true;
         noDesktop = true;
         enableXfwm = false;
         enableScreensaver = false;
      };
    };
    windowManager = {
      xmonad = {
        enable = true;
        enableContribAndExtras = true;
        extraPackages = haskellPackages : [
          haskellPackages.xmonad-contrib
          haskellPackages.xmonad-extras
          haskellPackages.xmonad
        ];
      };
    };
    displayManager = {
        # defaultSession = "xfce+xmonad";
        # defaultSession = "xmonad";
        # startx.enable = true;
        # sessionCommands = ''
        #     xset -dpms  # Disable Energy Star, as we are going to suspend anyway and it may hide "success" on that
        #     xset s blank # `noblank` may be useful for debugging 
        #     xset s 300 # seconds
        #     ${pkgs.lightlocker}/bin/light-locker --idle-hint --lock-on-suspend --lock-on-lid --lock-on-lid-close --lock-after-screensaver 0 &
        # '';
    };
  };
  
  services.libinput = { # Enable touchpad support.
    enable = true;
    touchpad = {
      naturalScrolling = true;
    };
  };

  powerManagement = {
    enable = true;
  };

  # Enable logind for power management (required for Quickshell/DMS power buttons)
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
    powerKey = "poweroff";
    powerKeyLongPress = "poweroff";
    suspendKey = "suspend";
    hibernateKey = "hibernate";
    rebootKey = "reboot";
  };

  #systemd.services.nix-security-scan = {
  #  description = "Weekly system security scan";
  #  script = pkgs.writeScript "nixos-scan-runner" ''
  #    #!${pkgs.bash}/bin/bash
  #    # Copy the full script from above and paste it here
  #    # Or, if you saved it to a file: /path/to/your/nixos-scan.sh
  #    /etc/nixos/nixos-scan.sh
  #  '';
  #  serviceConfig = {
  #    Type = "oneshot";
  #    User = "root";
  #  };
  #};

  #systemd.timers.nix-security-scan = {
  #  description = "Run security scan weekly";
  #  wantedBy = [ "timers.target" ];
  #  timerConfig = {
  #    OnCalendar = "Sun 03:00:00"; # Every Sunday at 3:00 AM
  #    Persistent = true;
  #  };
  #};

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable OpenGL/Vulkan graphics (required for VMs, quickgui, gaming)
  # Note: NixOS 25.05+ uses hardware.graphics instead of hardware.opengl
  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # 32-bit support for Wine, games, etc.
    
    # Extra packages for Vulkan and hardware video acceleration
    extraPackages = with pkgs; [
      vulkan-loader
      vulkan-validation-layers
      vulkan-tools
      # Mesa VA-API driver (hardware video decode)
      mesa.drivers
      # Intel specific (uncomment if using Intel GPU)
      # intel-media-driver
      # intel-vaapi-driver
      # AMD specific (uncomment if using AMD GPU)
      # amdvlk
    ];
    
    extraPackages32 = with pkgs.pkgsi686Linux; [
      vulkan-loader
      mesa.drivers
    ];
  };

  hardware.enableAllFirmware = true;
  # Disabled PulseAudio in favor of PipeWire for Wayland/Niri compatibility
  hardware.pulseaudio.enable = false;
  
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
  services.blueman.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.defaultUserShell = unstable.zsh;
  users.users.zen = {
    isNormalUser = true;
    # isSystemUser = true;
    initialPassword = "pw123"; 
    group = "users";
    extraGroups = [ 
      "wheel" # Enable 'sudo' for the user.
      "adbusers" # Enable 'adb' for the user.
      "audio"
      "networkmanager" # Allow GUI network management
      "libvirtd" # Enable libvirt/QEMU VM management
      "kvm" # Enable KVM hardware acceleration
    ]; 
    packages = [
      
    ];
  };

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-vkcapture
      obs-gstreamer
      obs-backgroundremoval
      #obs-pipewire-audio-capture
    ];
  };

  # GameMode for performance optimization
  programs.gamemode.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = [
    unstable.vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.

    # Graphical tools for development
    # Add antigravity-nix from GitHub
    unstable.antigravity-fhs
    # unstable.zed-editor
    unstable.code-cursor
    unstable.vscode
    unstable.windsurf
    unstable.google-authenticator
    unstable._1password-gui
    unstable.authenticator
    # unstable.code-cursor
    stable.wireshark
    unstable.quickgui
    unstable.postman
    unstable.mongodb-compass
    unstable.freelens-bin
    unstable.gparted
    unstable.jmeter
    #unstable.ciscoPacketTracer8
    # unstable.libsForQt5.kdenlive
    stable.kdePackages.kdenlive
    # stable.openshot-qt
    # stable.libsForQt5.libopenshot
    # stable.libsForQt5.libopenshot-audio
    stable.qtractor
    stable.inkscape
    stable.gimp  # Full-featured image editor

    # Screenshot capture and quick editing (Wayland/Niri compatible)
    unstable.grim      # Screenshot capture for Wayland
    unstable.slurp     # Region selection for screenshots
    unstable.swappy    # Quick screenshot annotation/editing
    unstable.flameshot # Feature-rich screenshot with annotations
    # unstable.ksnip       # Screenshot tool with annotation features

    # Integrated Development Environment
    unstable.neovim
    unstable.tmux
    unstable.emacs
    unstable.zellij
    unstable.devenv
    unstable.nodejs_24

    # Command line tools for development
    unstable.git
    unstable.git-lfs
    unstable.gh
    unstable.libiconv
    unstable.xclip
    unstable.curl
    unstable.ripgrep
    unstable.fd
    unstable.fasd
    unstable.vifm-full
    unstable.tshark
    unstable.termshark
    unstable.direnv
    unstable.tree-sitter
    unstable.just
    unstable.pay-respects
    unstable.mosh
    unstable.lazygit
    unstable.jq
    unstable.bc
    unstable.file
    unstable.gnumake

    # Command line tools for networking
    unstable.sshfs
    unstable.fuse3
    unstable.nss
    unstable.expat
    unstable.nmap
    unstable.tcpdump
    unstable.wrk2
    unstable.wget
    unstable.ethtool
    unstable.python312Packages.pyngrok
    unstable.gatling
    unstable.iftop
    unstable.iotop
    unstable.dig
    unstable.doggo
    unstable.mitmproxy
    unstable.aria2
    unstable.cifs-utils

    # Security cli tools
    unstable.uv
    unstable.vulnix
    unstable.clamav
    unstable.lynis
    unstable.sqlmap
    unstable.sqlmc
    unstable.laudanum
    unstable.nikto
    unstable.hcxtools
    unstable.hashcat
    unstable.thc-hydra
    unstable.gobuster
    unstable.wireguard-tools
    stable.metasploit
    unstable.sssd
    unstable.aircrack-ng
    unstable.gittuf
    unstable.dockle
    unstable.checkmate
    unstable.tracee
    unstable.apktool
    unstable.radare2
    unstable.ghidra-bin
    unstable.trivy
    unstable.wapiti
    # unstable.wpscan
    unstable.grype
    unstable.octoscan
    unstable.osv-scanner
    unstable.http-scanner
    unstable.secretscanner
    unstable.netscanner
    unstable.mdns-scanner
    # unstable.angryipscanner

    # Security gui tools
    # unstable.armitage  # BROKEN - fails to build in unstable
    unstable.johnny
    unstable.burpsuite
    # unstable.eresi
    unstable.cutter
    unstable.degate
    unstable.iaito
    # unstable.autopsy

    # Graphical tools for communication and collaboration
    anydesk
    unstable.remmina
    unstable.teamviewer
    # stable.rustdesk  # Disabled: no binary cache, compiles from source every time
    #stable.zoom-us

    # Browsers 
    stable.vivaldi
    stable.vivaldi-ffmpeg-codecs
    stable.google-chrome
    stable.firefox

    # tools for graphics and customization of the Operational System
    stable.gtk_engines
    stable.gtk-engine-murrine
    stable.xorg.xhost
    stable.xorg.xmessage
    stable.xorg.xbacklight
    stable.haskellPackages.xmobar    

    # Graphical tools for writing and reading
    stable.logseq
    # stable.wpsoffice
    # stable.libsForQt5.okular
    stable.texstudio    
    # unstable.pdf4qt

    # Utilities Graphical and Operational System 
    stable.copyq
    stable.lightlocker
    stable.redshift

    # File Manager
    unstable.nautilus
    unstable.gnome-disk-utility

    # Command line tools to run not nix packages
    # unstable.patchelf
    # unstable.steam-run

    # Command line tools to Operational System
    unstable.neofetch
    unstable.icu
    unstable.gcc
    unstable.xdotool
    unstable.libnotify
    unstable.yad
    unstable.lux
    unstable.killall
    unstable.htop
    unstable.tree
    unstable.alacritty
    unstable.dmidecode
    unstable.wirelesstools
    unstable.inetutils
    unstable.lm_sensors
    unstable.nix-index

    # Niri / Wayland tools
    unstable.fuzzel
    unstable.waybar
    unstable.wlsunset
    unstable.swaylock
    unstable.swaybg
    unstable.swaynotificationcenter
    unstable.xwayland-satellite
    unstable.polkit_gnome
    unstable.quickshell
    unstable.dms-shell
    unstable.dgop  # System monitoring backend for DMS (CPU, memory, network, GPU)
    unstable.wtype # Wayland keyboard input simulator


    # Command line tools for multimedia
    unstable.zip
    unstable.zlib
    unstable.unzip
    unstable.p7zip
    unstable.xz
    unstable.unar
    stable.vlc
    stable.ffmpeg
    unstable.xar
    unstable.p7zip
    unstable.pbzx
    unstable.rcodesign

    # Android development tools
    unstable.android-tools

    # Command line tools for virtualization and containers
    stable.qemu
    unstable.docker
    unstable.docker-compose
    unstable.podman
    unstable.podman-compose
    unstable.lazydocker

    # Command line tools for virtualization with Graphical interface
    stable.virt-manager
    stable.quickemu
    unstable.gns3-gui
    unstable.gns3-server

    # Windows VM support - VirtIO drivers and SPICE for optimized graphics
    unstable.virtio-win            # VirtIO drivers ISO for Windows guest (storage, network, GPU)
    unstable.spice-gtk             # SPICE client with 3D OpenGL acceleration
    unstable.looking-glass-client  # Low-latency display capture for GPU passthrough (optional)

    # Command line tools for encryption 
    unstable.gnome-keyring
    unstable.libsecret
    unstable.openssl

    # Command line tools for graphics
    unstable.glibc
    unstable.libGL
    unstable.libGLU
    unstable.libxml2

    # Graphical tools to audio
    unstable.pavucontrol
    unstable.pulseaudio
    unstable.lsof
    unstable.inxi

    # Command line tools for audio
    unstable.alsa-utils

    # Command line tools for AI
    unstable.ollama
    unstable.gemini-cli

    # Command line tools for downloading
    unstable.qbittorrent

    # Dependencies for Wine Run Apps
    # unstable.jdk
    # unstable.jre_minimal

    # Lutris and Gaming Dependencies
    unstable.lutris
    unstable.wineWow64Packages.waylandFull
    unstable.winetricks
    unstable.gamemode
    unstable.mangohud

    # Vulkan tools and validation
    unstable.vulkan-tools
    unstable.vulkan-loader
    unstable.vulkan-validation-layers
    unstable.vulkan-extension-layer

    # Graphics libraries
    unstable.mesa # RADV (default AMD driver)
    unstable.dxvk

    # Additional Wine dependencies
    # unstable.xorg.libXcursor
    # unstable.xorg.libXi
    # unstable.xorg.libXinerama
    # unstable.xorg.libXrandr
    # unstable.freetype
    # unstable.fontconfig

    # System monitoring
    unstable.mesa-demos

    # Font rendering
    unstable.corefonts
    unstable.liberation_ttf

  ];

  fonts.packages = [
    unstable.noto-fonts
    unstable.noto-fonts-cjk-sans
    unstable.noto-fonts-color-emoji
    unstable.liberation_ttf
    unstable.fira-code
    unstable.fira-code-symbols
    unstable.mplus-outline-fonts.githubRelease
    unstable.dina-font
    unstable.proggyfonts
    unstable.meslo-lgs-nf
    unstable.vista-fonts
    unstable.corefonts
    unstable.dejavu_fonts
    unstable.freefont_ttf
  ];
  
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs = {
    zsh.enable = true;
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    nix-ld.enable = true;
    nix-ld.libraries = [
      # Add any missing dynamic libraries for unpackaged programs
      # here, NOT in environment.systemPackages
      # add stdlibc++.so.6
      unstable.stdenv.cc.cc.lib
      unstable.gcc-unwrapped.lib
      unstable.libgcc.lib
    ];
    xfconf.enable = true;
    light.brightnessKeys.enable = true;

    niri.enable = true;
  };
  # List services that you want to enable:
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ 
    pkgs.xdg-desktop-portal-gtk 
    pkgs.xdg-desktop-portal-gnome
    pkgs.xdg-desktop-portal-wlr  # Screen sharing for Wayland (AnyDesk, etc)
  ];
  xdg.portal.config.common.default = "gtk";
  xdg.portal.wlr.enable = true;  # Enable wlroots portal for screen capture
  
  # Ensure Nautilus file picker works in browsers
  services.gnome.sushi.enable = true;  # Quick file previewer

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;
  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  
  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

  # virtualisation.vmware.host.enable = true;
  
  # Libvirt/QEMU for Windows 10 VM with optimized graphics
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      # Note: OVMF UEFI firmware is now included by default in NixOS 26.05+
      swtpm.enable = true;          # TPM emulation for Windows 11 compatibility
      runAsRoot = false;
    };
  };
  
  programs.dconf.enable = true; # virt-manager requires dconf to remember settings

  virtualisation.docker.enable = true;
  users.extraGroups.docker.members = [ "zen" ];
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "zen" ];
  # virtualisation.virtualbox.host.enableExtensionPack = true;
  virtualisation.virtualbox.guest.enable = true;
  virtualisation.virtualbox.guest.dragAndDrop = true;

  # Environment variables for Vulkan and gaming
  environment.sessionVariables = {
    # Vulkan ICD selection
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/radeon_icd.i686.json";
    
    # Wine/Lutris optimizations
    WINE_LARGE_ADDRESS_AWARE = "1";
    DXVK_HUD = "compiler";
    
    # Stack size increase (fixes stack overflow errors)
    WINEDLLOVERRIDES = "mscoree,mshtml=";
    WINEFSYNC = "1";
    
    # Kerberos fix
    KRB5_CONFIG = "/etc/krb5.conf";
  };

  # Optimise Nix store
  nix.settings.auto-optimise-store = true;
  nix.settings.max-jobs = "auto";  # Use all available cores for builds
  nix.settings.cores = 0;          # Use all cores per job
  nix.optimise.automatic = true;
  nix.optimise.dates = [ "12:00" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";  # Even more aggressive cleanup
  };

  # Systemd Journal Optimization
  services.journald.extraConfig = ''
    SystemMaxUse=100M
    SystemMaxFileSize=20M
    RuntimeMaxUse=50M
  '';

  # SSD Optimization - periodic TRIM
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };
}
