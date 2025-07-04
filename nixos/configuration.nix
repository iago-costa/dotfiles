# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, ... }:
let  
  buildToolsVersion = "33.0.2";
  androidenv = pkgs.androidenv.override {
    licenseAccepted = true;
  };
  androidComposition = androidenv.composeAndroidPackages {
    includeNDK = true;
    ndkVersions = [ "28.1.13356709" ];
    includeCmake = true;
    cmakeVersions = [ "3.18.1" ];
    includeSystemImages = true;
    includeEmulator = true;
    platformVersions = [ "33" "34" ];
    buildToolsVersions = [ buildToolsVersion "30.0.3" ];
    abiVersions = [ "x86_64" ];
    extraLicenses = [
      "android-googletv-license"
      "android-sdk-arm-dbt-license"        
      "android-sdk-license"
      "android-sdk-preview-license"
      "google-gdk-license"
      "intel-android-extra-license"
      "intel-android-sysimage-license"
      "mips-android-sysimage-license"
    ];
  };

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
  anydesk = pkgs.callPackage /home/zen/anydesk.nix {};
  # flutter = pkgs.callPackage /home/zen/flutter.nix {};

  stable = import <nixos-25.05> { config = baseconfig; };
  unstable = import <nixos> { config = baseconfig; };
  deprecated = import <nixos-24.11> { config = baseconfig; };
in
{
  nixpkgs.config.allowUnfree = true;

  environment.sessionVariables = {
    ANDROID_JAVA_HOME=pkgs.jdk.home;
    FLUTTER_PATH = "${pkgs.flutter}/bin";
    DART_PATH = "${pkgs.dart}/bin";
    ANDROID_SDK_ROOT = "${androidComposition.androidsdk}/libexec/android-sdk";
    # ANDROID_NDK_ROOT = "${androidComposition.androidsdk}/libexec/android-sdk/ndk-bundle";
    # Use the same buildToolsVersion here
    GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidComposition.androidsdk}/libexec/android-sdk/build-tools/${buildToolsVersion}/aapt2";
    CHROME_EXECUTABLE = "${pkgs.google-chrome}/bin/google-chrome-stable";
  };

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # ./hybrid-sleep-and-hibernate.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };

  services.upower = {
    enable = true;
    usePercentageForPolicy = true;
    percentageAction = 15;
    criticalPowerAction = "Hibernate";
  };

  # services.gnome.gnome-keyring.enable = true;
  services.gvfs.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
# flatpak to install postman compass openlens
  services.flatpak.enable = true; 

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
  services.displayManager.defaultSession = "xfce+xmonad";
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

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  hardware.opengl.enable = true;
  hardware.opengl.driSupport32Bit = true;
  
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
      obs-pipewire-audio-capture
    ];
  };


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = [
    androidComposition.androidsdk
    # androidComposition.ndk-bundle
    # stable.cmake
    stable.glibc
    unstable.flutter329
    stable.jdk17


    stable.vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    # packages graphical
    anydesk
    stable.redshift
    stable.gnome-keyring
    unstable.vscode
    unstable.vivaldi
    unstable.vivaldi-ffmpeg-codecs
    unstable.google-chrome
    unstable.firefox
    stable.logseq
    stable.gparted
    stable.virt-manager
    stable.quickemu
    stable.quickgui
    stable.gns3-gui
    stable.gns3-server
    stable.gtk_engines
    stable.gtk-engine-murrine
    stable.lightlocker
    stable.lux
    stable.xorg.xhost
    stable.xorg.xmessage
    stable.xorg.xbacklight
    stable.pulseaudio-ctl
    stable.yad
    stable.libnotify
    stable.xdotool
    unstable.wine64
    stable.libsForQt5.okular
    stable.wireshark
    stable.wpsoffice
    stable.jmeter
    stable.teamviewer
    (stable.appimage-run.override {
     extraPkgs = pkgs: [ stable.xorg.libxshmfence ];
     })
    #stable.zoom-us
    #unstable.winbox
    #unstable.ciscoPacketTracer8
    #unstable.rustdesk
    stable.tree-sitter
    stable.gcc
    stable.nodejs
    stable.killall
    unstable.alacritty
    stable.tree
    stable.haskellPackages.xmobar
    stable.ghc
    stable.dmidecode
    stable.wirelesstools
    stable.inetutils
    stable.lm_sensors
    stable.sshfs
    stable.qemu
    stable.xclip
    stable.curl
    stable.wget
    stable.htop
    unstable.git
    stable.gh
    unstable.neovim
    unstable.tmux
    stable.emacs
    unstable.zellij
    stable.libsecret
    stable.ethtool
    stable.ripgrep
    stable.fd
    stable.fasd
    stable.vifm-full
    stable.tshark
    stable.termshark
    stable.neofetch
    stable.wrk2
    stable.file
    stable.direnv
    stable.zip
    stable.unzip
    stable.p7zip
    stable.xz
    stable.just
    stable.thefuck
    stable.mosh
    stable.gnumake
    stable.patchelf
    stable.steam-run
    unstable.docker
    unstable.docker-compose
    stable.gatling
    stable.nox
    stable.nix-index
    stable.nmap
    unstable.glibc
    unstable.libGL
    unstable.libGLU
    unstable.libxml2
    stable.zlib
    stable.fuse3
    stable.icu
    stable.nss
    stable.openssl
    stable.expat
    stable.copyq
    stable.lazygit
    unstable.ollama
    stable.vlc
    unstable.pdf4qt
    stable.code-cursor
    stable.ffmpeg
    stable.python312Packages.pyngrok
    unstable.unar
    #unstable.distrobox
    #unstable.busybox
    #deprecated.haskellPackages.ghcup
    #unstable.haskellPackages.base-compat-batteries_0_13_1
    #unstable.haskellPackages.base-compat_0_13_1
    #deprecated.haskellPackages.streamly

    stable.xar
    stable.p7zip
    stable.pbzx
    stable.rcodesign

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
  system.stateVersion = "24.11"; # Did you read the comment?


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

  nix.settings.auto-optimise-store = true;
  nix.optimise.automatic = true;
  nix.optimise.dates = [ "12:00" ]; # Optional; allows customizing optimisation schedule
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
