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
    ];
    android_sdk.accept_license = true;
    android_sdk.accept_android_sdk_licenses = true;  
  };
  anydesk = pkgs.callPackage /etc/nixos/anydesk.nix {};

  stable = import <nixos-25.05> { config = baseconfig; };
  unstable = import <nixos> { config = baseconfig; };
  deprecated = import <nixos-24.11> { config = baseconfig; };
in
{
  nix.settings.trusted-users = [ "root" "zen" ];
  # Enable experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # ./hybrid-sleep-and-hibernate.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel parameters for gaming performance
  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642;
    "fs.file-max" = 524288;
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
  
  services.pipewire.enable = false;
  # services.pipewire = {
  #   enable = true;
  #   alsa.enable = true;
  #   alsa.support32Bit = true;
  #   pulse.enable = true;
  #   # If you want to use JACK applications, uncomment this
  #   jack.enable = true;
  # };

  services.upower = {
    enable = true;
    usePercentageForPolicy = true;
    percentageAction = 15;
    criticalPowerAction = "Hibernate";
  };

  # Enable PAM integration for automatic unlocking (example for greetd)
  security.pam.services.login.enableGnomeKeyring = true;
  services.gnome.gnome-keyring.enable = true;
  services.gvfs.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  # flatpak to install postman compass openlens
  services.flatpak.enable = true; 
  services.dbus.enable = true;

  environment.xfce.excludePackages = [ 
    stable.xfce.xfwm4
    stable.xfce.xfce4-panel
    stable.xfce.xfce4-power-manager
    stable.xfce.xfce4-terminal
    stable.xfce.xfce4-whiskermenu-plugin
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

  # systemd.targets.hybrid-sleep.enable = true;
  # services.logind.extraConfig = ''
  #   IdleAction=hybrid-sleep
  #   IdleActionSec=600s
  # '';

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

  # Enable 32-bit support (essential for gaming)
  # hardware.opengl = {
  #   enable = true;
  #   driSupport32Bit = true;
    
  #   # Vulkan support
  #   extraPackages = with pkgs; [
  #     stable.vulkan-loader
  #     stable.vulkan-validation-layers
  #     stable.vulkan-tools
  #     # AMD specific
  #     stable.amdvlk
  #     # Intel specific
  #     stable.intel-media-driver
  #     # NVIDIA specific (uncomment if using NVIDIA)
  #     # nvidia-vaapi-driver
  #   ];
    
  #   extraPackages32 = with pkgs.pkgsi686Linux; [
  #     stable.vulkan-loader
  #     # AMD specific
  #     stable.amdvlk
  #     # Intel specific
  #     stable.intel-media-driver
  #   ];
  # };

  hardware.enableAllFirmware = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = true;    ## If compatibility with 32-bit applications is desired.
  hardware.pulseaudio.package = unstable.pulseaudioFull;
  hardware.pulseaudio.extraConfig = "load-module module-combine-sink";
  
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
      "wheel" # Enable ‘sudo’ for the user.
      "adbusers" # Enable ‘adb’ for the user.
      "audio"
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
stable.vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.

# Graphical tools for development
# Add antigravity-nix from GitHub
(builtins.getFlake "github:jacopone/antigravity-nix").packages.x86_64-linux.google-antigravity
unstable.zed-editor
unstable.code-cursor
unstable.vscode
unstable.windsurf
unstable.google-authenticator
unstable._1password-gui
unstable.authenticator
# unstable.code-cursor
stable.wireshark
stable.quickgui
stable.gparted
stable.jmeter
#unstable.ciscoPacketTracer8
# unstable.libsForQt5.kdenlive
stable.kdePackages.kdenlive
stable.openshot-qt
stable.libsForQt5.libopenshot
stable.libsForQt5.libopenshot-audio
stable.qtractor
stable.inkscape

# Integrated Development Environment
unstable.neovim
unstable.tmux
unstable.emacs
unstable.zellij
stable.devenv
unstable.nodejs_24

# Command line tools for development
unstable.git
stable.gh
unstable.libiconv
stable.xclip
stable.curl
stable.ripgrep
stable.fd
stable.fasd
stable.vifm-full
stable.tshark
stable.termshark
stable.direnv
stable.tree-sitter
stable.just
stable.thefuck
stable.mosh
stable.lazygit
stable.file
stable.gnumake

# Command line tools for networking
stable.sshfs
stable.fuse3
stable.nss
stable.expat
stable.nmap
unstable.tcpdump
stable.wrk2
stable.wget
stable.ethtool
stable.python312Packages.pyngrok
stable.gatling
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
unstable.metasploit
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
unstable.armitage
unstable.johnny
unstable.burpsuite
unstable.eresi
unstable.cutter
unstable.degate
unstable.iaito
#unstable.autopsy

# Graphical tools for communication and collaboration
anydesk
unstable.remmina
stable.teamviewer
#stable.zoom-us

# Browsers 
unstable.vivaldi
unstable.vivaldi-ffmpeg-codecs
unstable.google-chrome
unstable.firefox

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

# Command line tools to run not nix packages
# stable.patchelf
# stable.steam-run

# Command line tools to Operational System
stable.neofetch
stable.icu
stable.gcc
stable.xdotool
stable.libnotify
stable.yad
stable.lux
stable.killall
stable.htop
stable.tree
unstable.alacritty
stable.dmidecode
stable.wirelesstools
stable.inetutils
stable.lm_sensors
stable.nix-index

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


# Command line tools for multimedia
stable.zip
stable.zlib
stable.unzip
stable.p7zip
stable.xz
unstable.unar
stable.vlc
stable.ffmpeg
stable.xar
stable.p7zip
stable.pbzx
stable.rcodesign

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
stable.gns3-gui
stable.gns3-server

# Command line tools for encryption 
stable.gnome-keyring
stable.libsecret
stable.openssl

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

# Command line tools for downloading
unstable.qbittorrent

# Dependencies for Wine Run Apps
# unstable.jdk
# unstable.jre_minimal

# Lutris and dependencies
# unstable.lutris
# unstable.wineWowPackages.stableFull
# unstable.wineWowPackages.yabridge
# unstable.winetricks

# Vulkan tools and validation
# unstable.vulkan-tools
# unstable.vulkan-loader
# unstable.vulkan-headers
# unstable.vulkan-validation-layers

# Graphics libraries
# unstable.mesa # Includes Vulkan support
# unstable.libGL
# unstable.libGLU
# unstable.amdvlk # Alternative or additional AMD Vulkan driver
# (stable.appimage-run.override {
# extraPkgs = pkgs: [ stable.xorg.libxshmfence ];
# })

# Kerberos support
unstable.krb5

# DXVK and VKD3D
# unstable.dxvk
# unstable.vkd3d

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
    stable.noto-fonts
    stable.noto-fonts-cjk-sans
    stable.noto-fonts-emoji
    stable.liberation_ttf
    stable.fira-code
    stable.fira-code-symbols
    stable.mplus-outline-fonts.githubRelease
    stable.dina-font
    stable.proggyfonts
    stable.meslo-lgs-nf
    stable.vistafonts
    stable.corefonts
    stable.dejavu_fonts
    stable.freefont_ttf
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
      stable.stdenv.cc.cc.lib
      stable.gcc-unwrapped.lib
      stable.libgcc.lib
    ];
    xfconf.enable = true;
    light.brightnessKeys.enable = true;
    adb.enable = true;
    niri.enable = true;
  };
  # List services that you want to enable:
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.config.common.default = "gtk";

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
  system.stateVersion = "25.05"; # Did you read the comment?

  # virtualisation.vmware.host.enable = true;
  virtualisation.libvirtd.enable = false;
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
  nix.optimise.automatic = true;
  nix.optimise.dates = [ "12:00" ]; # Optional; allows customizing optimisation schedule
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
