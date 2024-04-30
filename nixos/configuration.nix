# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, ... }:
let  
  baseconfig = { 
    allowUnfree = true; 
    #allowBroken = true;
    vivaldi = {
        proprietaryCodecs = true;
        enableWideVine = true;
    };
    permittedInsecurePackages = [
        "electron-25.9.0"
    ];
    pulseaudio = true;
  };
  stable = import <nixos-23.11> { config = baseconfig; };
  unstable = import <nixos> { config = baseconfig; };
  deprecated = import <nixos-23.05> { config = baseconfig; };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./hybrid-sleep-and-hibernate.nix
    ];

  nixpkgs.config.allowUnfree = true;

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

  services.upower = {
    enable = true;
    usePercentageForPolicy = true;
    percentageAction = 15;
    criticalPowerAction = "Hibernate";
  };

  services.gnome.gnome-keyring.enable = true;
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.flatpak.enable = true;
  # flatpak install postman compass openlens

  environment.xfce.excludePackages = [ 
    stable.xfce.xfwm4
    stable.xfce.xfce4-panel
    stable.xfce.xfce4-power-manager
    stable.xfce.xfce4-terminal
    stable.xfce.xfce4-whiskermenu-plugin
  ];

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
        #defaultSession = "xfce+xmonad";
        #defaultSession = "xmonad";
        #startx.enable = true;
        sessionCommands = ''
            xset -dpms  # Disable Energy Star, as we are going to suspend anyway and it may hide "success" on that
            xset s blank # `noblank` may be useful for debugging 
            xset s 300 # seconds
            ${pkgs.lightlocker}/bin/light-locker --idle-hint --lock-on-suspend --lock-on-lid --lock-on-lid-close --lock-after-screensaver 0 &
        '';
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

  systemd.targets.hybrid-sleep.enable = true;
  services.logind.extraConfig = ''
    IdleAction=hybrid-sleep
    IdleActionSec=600s
  '';

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.defaultUserShell = pkgs.zsh;
  users.users.zen = {
    isNormalUser = true;
    initialPassword = "pw123"; 
    group = "users";
    extraGroups = [ 
      "wheel" # Enable ‘sudo’ for the user.
      "adbusers" # Enable ‘adb’ for the user.
    ]; 
    packages = with pkgs; [
      firefox
      tree
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    stable.lightlocker
    unstable.wget
    unstable.htop
    unstable.vivaldi
    unstable.vivaldi-ffmpeg-codecs
    unstable.xfce.xfce4-clipman-plugin
    unstable.zellij
    unstable.zsh
    unstable.alacritty
    unstable.gnome.gnome-keyring
    unstable.libsecret
    unstable.gparted
    unstable.ethtool
    unstable.neovim
    unstable.git
    unstable.gnumake
    unstable.gcc
    unstable.redshift
    unstable.thefuck
    (unstable.appimage-run.override {
      extraPkgs = pkgs: [ pkgs.xorg.libxshmfence ];
    })
    unstable.nodejs_22
    unstable.xclip
    unstable.patchelf
    unstable.steam-run
    unstable.fuse
    unstable.fuse3
    unstable.libGL
    unstable.libGLU
    unstable.libxml2
    stable.logseq
    unstable.docker
    unstable.docker-compose
    unstable.wrk2
    unstable.dmidecode
    unstable.neofetch
    unstable.direnv
    unstable.xz
    unstable.nox
    unstable.file
    unstable.wpsoffice
    #stable.zoom-us
    unstable.openssl
    unstable.ripgrep
    unstable.fd
    unstable.unzip
    unstable.fasd
    unstable.gh
    unstable.gatling
    unstable.jmeter
    unstable.vscode
    #unstable.etcher
    stable.ghc
    stable.haskellPackages.xmobar
    stable.lux
    stable.xorg.xmessage
    stable.xorg.xbacklight
    stable.lm_sensors
    stable.pulseaudio-ctl
    stable.yad
    stable.libnotify
    stable.xdotool
    unstable.libsForQt5.okular
    unstable.vifm-full
    unstable.gcc-unwrapped
    unstable.networkmanager_dmenu
    unstable.wirelesstools
    unstable.nix-index
    unstable.xorg.xhost
    unstable.wireshark
    unstable.tshark
    unstable.termshark
    unstable.zip
    unstable.just
    unstable.mosh
    unstable.qemu
    unstable.quickemu
    unstable.quickgui
    unstable.tmux
    unstable.emacs
    #unstable.distrobox
    #unstable.busybox
    #deprecated.haskellPackages.ghcup
    #unstable.haskellPackages.base-compat-batteries_0_13_1
    #unstable.haskellPackages.base-compat_0_13_1
    #deprecated.haskellPackages.streamly
    unstable.sshfs
    #unstable.winbox
    unstable.wine64
    unstable.virt-manager
    unstable.inetutils
    unstable.p7zip
    unstable.anydesk
    unstable.teamviewer
    #unstable.rustdesk
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    unstable.meslo-lgs-nf
    unstable.vistafonts
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
    nix-ld.libraries = with pkgs; [
      # Add any missing dynamic libraries for unpackaged programs
      # here, NOT in environment.systemPackages
      # add stdlibc++.so.6
      unstable.stdenv.cc.cc.lib
      unstable.gcc-unwrapped.lib
      unstable.zlib
      unstable.fuse3
      unstable.icu
      unstable.zlib
      unstable.nss
      unstable.openssl
      unstable.curl
      unstable.expat
      unstable.libgcc.lib
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
  system.stateVersion = "unstable"; # Did you read the comment?

  #users.extraGroups.vboxusers.members = [ "zen" ];
  #virtualisation.virtualbox.host.enable = true;
  #virtualisation.virtualbox.host.enableExtensionPack = true;
  #virtualisation.virtualbox.guest.enable = true;
  #virtualisation.virtualbox.guest.x11 = true;

  virtualisation.libvirtd.enable = true;
  programs.dconf.enable = true; # virt-manager requires dconf to remember settings

  virtualisation.docker.enable = true;
  users.extraGroups.docker.members = [ "zen" ];
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  nix.settings.auto-optimise-store = true;
  nix.optimise.automatic = true;
  nix.optimise.dates = [ "12:00" ]; # Optional; allows customizing optimisation schedule
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 4d";
  };
}
