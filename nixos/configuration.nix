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

  # ── Legacy X11/Xfce/Xmonad (DISABLED) ──────────────────────────
  # environment.xfce.excludePackages = [ 
  #   stable.xfce.xfwm4
  #   stable.xfce.xfce4-panel
  #   stable.xfce.xfce4-power-manager
  #   stable.xfce.xfce4-terminal
  #   stable.xfce.xfce4-whiskermenu-plugin
  #   stable.xfce.thunar
  # ];

  # Spice VDAgent
  services.spice-vdagentd.enable = true;

  # Display manager — Niri is the default session
  services.displayManager.defaultSession = "niri";

  # services.xserver = {
  #   enable = true;   
  #   desktopManager = {
  #     xfce = {
  #        enable = true;
  #        noDesktop = true;
  #        enableXfwm = false;
  #        enableScreensaver = false;
  #     };
  #   };
  #   windowManager = {
  #     xmonad = {
  #       enable = true;
  #       enableContribAndExtras = true;
  #       extraPackages = haskellPackages : [
  #         haskellPackages.xmonad-contrib
  #         haskellPackages.xmonad-extras
  #         haskellPackages.xmonad
  #       ];
  #     };
  #   };
  # };

  # Pure Wayland Login Manager (greetd + tuigreet)
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd niri";
        user = "greeter";
      };
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
  # services.xserver.xkb.layout = "us";
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

    # ══════════════════════════════════════════════════════════
    # Editors / IDEs
    # ══════════════════════════════════════════════════════════
    unstable.vim
    unstable.neovim
    unstable.emacs
    unstable.antigravity-fhs
    unstable.code-cursor
    unstable.vscode
    unstable.windsurf

    # ══════════════════════════════════════════════════════════
    # Terminal / Multiplexers
    # ══════════════════════════════════════════════════════════
    unstable.alacritty
    unstable.tmux
    unstable.zellij

    # ══════════════════════════════════════════════════════════
    # Backend Development (Languages & DB)
    # ══════════════════════════════════════════════════════════
    unstable.go
    unstable.rustc
    unstable.cargo
    unstable.rust-analyzer
    unstable.python312
    unstable.elixir
    unstable.ruby
    unstable.php
    unstable.pgcli             # Smart PostgreSQL CLI
    unstable.mycli             # Smart MySQL CLI
    unstable.litecli           # Smart SQLite CLI
    unstable.dbeaver-bin       # Universal visual DB client
    unstable.mongodb-compass   # MongoDB GUI
    unstable.redis             # In-memory data store
    unstable.postman           # API testing GUI
    unstable.grpcurl           # gRPC CLI client
    unstable.ghz               # gRPC benchmarking
    unstable.httpie            # Human-friendly HTTP client
    unstable.devenv            # Developer environments

    # ══════════════════════════════════════════════════════════
    # Frontend Development
    # ══════════════════════════════════════════════════════════
    unstable.bun               # Fast JS runtime / bundler
    unstable.deno              # Secure JS/TS runtime
    unstable.pnpm              # Fast Node package manager
    unstable.yarn              # Node package manager
    unstable.typescript        # TypeScript compiler
    unstable.eslint            # JS/TS linter
    unstable.prettier          # Code formatter

    # ══════════════════════════════════════════════════════════
    # DevOps / Infrastructure
    # ══════════════════════════════════════════════════════════
    unstable.kubectl           # Kubernetes CLI
    unstable.kubernetes-helm   # Helm charts
    unstable.k9s               # Kubernetes TUI
    unstable.freelens-bin      # Kubernetes IDE
    unstable.opentofu          # IaC (open-source Terraform fork)
    unstable.terraform         # IaC
    unstable.ansible           # Configuration management
    unstable.packer            # Machine image builder
    unstable.vault             # Secrets management
    unstable.consul            # Service discovery
    unstable.dive              # Docker layer explorer
    unstable.act               # Run GitHub Actions locally
    unstable.checkov           # IaC security scanner
    unstable.tflint            # Terraform linter
    unstable.hadolint          # Dockerfile linter
    unstable.shellcheck        # Shell script analyzer
    unstable.shfmt             # Shell script formatter

    # ══════════════════════════════════════════════════════════
    # QA / Testing / Load Testing
    # ══════════════════════════════════════════════════════════
    unstable.k6                # Modern load testing (JS scripted)
    unstable.vegeta            # HTTP load testing
    unstable.hey               # HTTP load generator (ab replacement)
    unstable.xh                # Fast HTTP requests (curl alternative)
    unstable.jmeter            # Java-based load testing GUI
    unstable.wrk2              # HTTP benchmark
    unstable.gatling           # HTTP load testing

    # ══════════════════════════════════════════════════════════
    # Data Analytics (Python)
    # ══════════════════════════════════════════════════════════
    unstable.python312Packages.pandas        # Data manipulation
    unstable.python312Packages.numpy         # Numerical computing
    unstable.python312Packages.matplotlib    # Plotting / visualization
    unstable.python312Packages.scikit-learn  # Machine learning
    unstable.python312Packages.jupyter       # Notebooks
    unstable.python312Packages.ipython       # Enhanced Python REPL
    unstable.python312Packages.requests      # HTTP for Python
    unstable.python312Packages.sqlalchemy    # Python ORM

    # ══════════════════════════════════════════════════════════
    # AI / ML Engineering
    # ══════════════════════════════════════════════════════════
    unstable.ollama                          # Local LLM runner
    unstable.gemini-cli                      # Google Gemini CLI
    unstable.python312Packages.fastapi       # ML API framework
    unstable.python312Packages.uvicorn       # ASGI server
    unstable.python312Packages.pydantic      # Data validation
    unstable.python312Packages.httpx         # Async HTTP client
    unstable.python312Packages.boto3         # AWS SDK for Python
    unstable.python312Packages.rich          # Beautiful terminal output

    # ══════════════════════════════════════════════════════════
    # Language Servers / Linters (Neovim / IDE support)
    # ══════════════════════════════════════════════════════════
    unstable.lua-language-server                         # Lua LSP
    unstable.stylua                                      # Lua formatter
    unstable.gopls                                       # Go LSP
    unstable.pyright                                     # Python LSP
    unstable.ruff                                        # Python fast linter / formatter
    unstable.nixd                                        # Nix LSP
    unstable.yaml-language-server                        # YAML LSP
    unstable.vscode-langservers-extracted                 # HTML/CSS/JSON LSPs
    unstable.nodePackages.typescript-language-server      # TS/JS LSP
    unstable.tree-sitter                                 # Multi-lang parser

    # ══════════════════════════════════════════════════════════
    # Daily CLI Productivity (Modern Replacements)
    # ══════════════════════════════════════════════════════════
    unstable.bat               # cat with syntax highlighting
    unstable.eza               # Modern ls replacement
    unstable.zoxide            # Smart cd with memory
    unstable.fzf               # Interactive fuzzy finder
    unstable.delta             # Better git diffs
    unstable.dust              # du visualization
    unstable.duf               # df replacement
    unstable.procs             # Modern ps replacement
    unstable.bottom            # htop alternative (btm)
    unstable.tokei             # Count lines of code
    unstable.glow              # Render markdown in terminal
    unstable.hyperfine         # CLI benchmarking
    unstable.tldr              # Simplified man pages
    unstable.difftastic        # Syntax-aware diff
    unstable.ncdu              # Disk usage analyzer (TUI)
    unstable.watchexec         # File watcher + command runner
    unstable.yq                # YAML/XML processor
    unstable.meld              # Visual diff / merge tool

    # ══════════════════════════════════════════════════════════
    # Git & Version Control
    # ══════════════════════════════════════════════════════════
    unstable.git
    unstable.git-lfs
    unstable.gh                # GitHub CLI
    unstable.lazygit           # Git TUI
    unstable.gittuf            # Git trust framework

    # ══════════════════════════════════════════════════════════
    # Networking Tools
    # ══════════════════════════════════════════════════════════
    unstable.curl
    unstable.wget
    unstable.aria2             # Download accelerator
    unstable.mosh              # Persistent SSH
    unstable.sshfs
    unstable.fuse3
    unstable.nmap
    unstable.tcpdump
    unstable.ethtool
    unstable.iftop             # Network bandwidth monitor
    unstable.iotop             # I/O monitor
    unstable.dig
    unstable.doggo             # Modern dig alternative
    unstable.mitmproxy         # HTTP/HTTPS proxy
    unstable.python312Packages.pyngrok
    unstable.cifs-utils
    unstable.nss
    unstable.expat
    stable.wireshark
    unstable.tshark
    unstable.termshark

    # ══════════════════════════════════════════════════════════
    # Security — CLI Tools
    # ══════════════════════════════════════════════════════════
    unstable.uv                # Python package manager
    unstable.vulnix            # Nix vulnerability scanner
    unstable.clamav            # Antivirus
    unstable.lynis             # System audit
    unstable.sqlmap            # SQL injection tool
    unstable.sqlmc
    unstable.laudanum
    unstable.nikto             # Web server scanner
    unstable.hcxtools          # WiFi capture tools
    unstable.hashcat           # Password recovery
    unstable.thc-hydra         # Login cracker
    unstable.gobuster          # Directory brute-forcer
    unstable.wireguard-tools   # VPN
    stable.metasploit          # Exploitation framework
    unstable.sssd
    unstable.aircrack-ng       # WiFi security
    unstable.dockle            # Container security linter
    unstable.checkmate
    unstable.tracee            # Runtime security
    unstable.apktool           # Android reverse engineering
    unstable.radare2           # Binary analysis
    unstable.ghidra-bin        # Reverse engineering suite
    unstable.trivy             # Vulnerability scanner
    unstable.wapiti            # Web vulnerability scanner
    unstable.grype             # Vulnerability scanner
    unstable.octoscan
    unstable.osv-scanner       # Open Source vulnerability scanner
    unstable.http-scanner
    unstable.secretscanner     # Secret detection
    unstable.netscanner
    unstable.mdns-scanner

    # ══════════════════════════════════════════════════════════
    # Security — GUI Tools
    # ══════════════════════════════════════════════════════════
    unstable.johnny            # John the Ripper GUI
    unstable.burpsuite         # Web security testing
    unstable.cutter            # Reverse engineering GUI
    unstable.degate            # IC reverse engineering
    unstable.iaito             # Radare2 GUI

    # ══════════════════════════════════════════════════════════
    # Screenshot / Screen Capture (Wayland)
    # ══════════════════════════════════════════════════════════
    unstable.grim              # Screenshot capture
    unstable.slurp             # Region selection
    unstable.swappy            # Quick annotation/editing
    unstable.flameshot         # Feature-rich screenshots

    # ══════════════════════════════════════════════════════════
    # Wayland / Niri / Desktop Environment
    # ══════════════════════════════════════════════════════════
    unstable.fuzzel            # App launcher
    unstable.waybar            # Status bar
    unstable.wlsunset          # Night light
    unstable.swaylock          # Screen locker
    unstable.swaybg            # Wallpaper
    unstable.swaynotificationcenter  # Notifications
    unstable.xwayland-satellite
    unstable.polkit_gnome
    unstable.quickshell        # Shell framework
    unstable.dms-shell         # DankMaterialShell
    unstable.dgop              # System monitor backend
    unstable.wtype             # Wayland keyboard input simulator
    stable.gtk_engines
    stable.gtk-engine-murrine
    stable.xorg.xhost
    stable.xorg.xmessage
    stable.xorg.xbacklight
    stable.haskellPackages.xmobar
    stable.copyq               # Clipboard manager
    stable.lightlocker         # Screen locker
    stable.redshift            # Night light (X11)

    # ══════════════════════════════════════════════════════════
    # Browsers
    # ══════════════════════════════════════════════════════════
    stable.vivaldi
    stable.vivaldi-ffmpeg-codecs
    stable.google-chrome
    stable.firefox

    # ══════════════════════════════════════════════════════════
    # Communication / Remote
    # ══════════════════════════════════════════════════════════
    anydesk
    unstable.remmina
    unstable.teamviewer

    # ══════════════════════════════════════════════════════════
    # Authentication / Passwords
    # ══════════════════════════════════════════════════════════
    unstable.google-authenticator
    unstable._1password-gui
    unstable.authenticator
    unstable.gnome-keyring
    unstable.libsecret
    unstable.openssl

    # ══════════════════════════════════════════════════════════
    # File Manager / Disk Utils
    # ══════════════════════════════════════════════════════════
    unstable.nautilus
    unstable.gnome-disk-utility
    unstable.gparted
    unstable.vifm-full         # Terminal file manager

    # ══════════════════════════════════════════════════════════
    # Multimedia
    # ══════════════════════════════════════════════════════════
    stable.vlc                 # Media player
    stable.ffmpeg              # Video/audio converter
    stable.kdePackages.kdenlive  # Video editor
    stable.qtractor            # Audio workstation
    stable.inkscape            # Vector graphics
    stable.gimp                # Image editor
    unstable.pavucontrol       # PulseAudio volume control
    unstable.pulseaudio        # Audio utilities
    unstable.alsa-utils        # ALSA utilities
    unstable.qbittorrent       # Torrent client
    unstable.lux               # Video downloader

    # ══════════════════════════════════════════════════════════
    # Archive / Compression
    # ══════════════════════════════════════════════════════════
    unstable.zip
    unstable.unzip
    unstable.p7zip             # Duplicate removed
    unstable.xz
    unstable.unar
    unstable.xar
    unstable.pbzx
    unstable.zlib

    # ══════════════════════════════════════════════════════════
    # System Utilities / Libraries
    # ══════════════════════════════════════════════════════════
    unstable.neofetch          # System info
    unstable.htop              # Process monitor
    unstable.tree              # Directory tree
    unstable.killall
    unstable.lsof              # List open files
    unstable.inxi              # System info (detailed)
    unstable.dmidecode         # Hardware info
    unstable.lm_sensors        # Temperature / fans
    unstable.wirelesstools
    unstable.inetutils
    unstable.xdotool
    unstable.xclip
    unstable.libnotify
    unstable.yad               # GUI dialogs from shell
    unstable.nix-index         # Nix package file search
    unstable.bc                # Calculator
    unstable.file              # File type detection
    unstable.jq                # JSON processor
    unstable.just              # Command runner
    unstable.pay-respects      # Correct previous command
    unstable.direnv            # Per-directory env vars
    unstable.fasd              # Quick directory access
    unstable.libiconv          # Character encoding
    unstable.rcodesign         # Apple code signing
    unstable.glibc
    unstable.libGL
    unstable.libGLU
    unstable.libxml2
    unstable.icu

    # ══════════════════════════════════════════════════════════
    # Specialized Tools
    # ══════════════════════════════════════════════════════════
    unstable.android-tools     # Android development tools
    unstable.logseq            # Knowledge management (stable.logseq found earlier)
    unstable.texstudio         # LaTeX editor

    # ══════════════════════════════════════════════════════════
    # Gaming (Lutris / Wine / Vulkan)
    # ══════════════════════════════════════════════════════════
    unstable.lutris
    unstable.wineWow64Packages.waylandFull
    unstable.winetricks
    unstable.gamemode
    unstable.mangohud
    unstable.vulkan-tools
    unstable.vulkan-loader
    unstable.vulkan-validation-layers
    unstable.vulkan-extension-layer
    unstable.mesa              # RADV (default AMD driver)
    unstable.mesa-demos
    unstable.dxvk              # DirectX -> Vulkan

    # ══════════════════════════════════════════════════════════
    # Fonts
    # ══════════════════════════════════════════════════════════
    unstable.corefonts         # Duplicate removed
    unstable.liberation_ttf    # Duplicate removed

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
    # xfconf.enable = true;

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
