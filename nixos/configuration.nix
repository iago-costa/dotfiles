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
        "electron-27.3.11"
        "qtwebengine-5.15.19"
    ];
    android_sdk.accept_license = true;
    android_sdk.accept_android_sdk_licenses = true;  
  };
  anydesk = pkgs.callPackage /etc/nixos/anydesk.nix {};
  # trae = pkgs.callPackage /etc/nixos/trae.nix {};  # FIXME: build broken — upstream .deb changed
  # qoder = pkgs.callPackage /etc/nixos/qoder.nix {};  # FIXME: build broken — re-enable after fixing

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

  # Nix store disk space management
  nix.settings.min-free = 2 * 1024 * 1024 * 1024;  # 2GB
  nix.settings.max-free = 10 * 1024 * 1024 * 1024; # 10GB

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
  boot.tmp.cleanOnBoot = true;
  boot.tmp.useTmpfs = true;

  # Performance Optimized Kernel
  boot.kernelPackages = stable.linuxPackages_zen;
  
  # Kernel parameters for performance optimization and AMD Ryzen stability
  boot.kernelParams = [ 
    "scsi_mod.use_blk_mq=1" # Better NVMe multi-queue utilization
    
    # AMD Ryzen / AMDGPU stability fixes
    "processor.max_cstate=5"
    "rcu_nocbs=0-15"
    "idle=nomwait"
    "amdgpu.sg_display=0"

    # AMD P-state driver — finer CPU frequency/thermal control
    "amd_pstate=active"
  ];

  # Kernel parameters for performance optimization
  boot.kernel.sysctl = {
    # Gaming / application support
    "vm.max_map_count" = 2147483642;
    "fs.file-max" = 524288;
    
    "vm.swappiness" = 60; # Moderated physical swap usage (Linux default)
    "vm.vfs_cache_pressure" = 50;
    
    # Disk I/O optimization - write dirty pages earlier for SSD longevity
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;

    # TCP BBR congestion control
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";

    # ── Network Performance Tuning ──
    # TCP buffer sizes (min, default, max) — larger buffers for high-latency links
    "net.core.rmem_max" = 16777216;       # 16 MB
    "net.core.wmem_max" = 16777216;       # 16 MB
    "net.ipv4.tcp_rmem" = "4096 131072 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";

    # TCP Fast Open (client + server)
    "net.ipv4.tcp_fastopen" = 3;

    # Increase backlog for better throughput under load
    "net.core.netdev_max_backlog" = 5000;

    # Enable selective acknowledgments and timestamps
    "net.ipv4.tcp_sack" = 1;
    "net.ipv4.tcp_timestamps" = 1;
    "net.ipv4.tcp_window_scaling" = 1;

    # Reduce TCP keepalive time for faster dead connection detection
    "net.ipv4.tcp_keepalive_time" = 60;
    "net.ipv4.tcp_keepalive_intvl" = 10;
    "net.ipv4.tcp_keepalive_probes" = 6;

    # Faster connection reuse
    "net.ipv4.tcp_tw_reuse" = 1;
    "net.ipv4.tcp_fin_timeout" = 15;

    # Improve responsiveness under load
    "kernel.sched_latency_ns" = 1000000;
    "kernel.sched_min_granularity_ns" = 100000;
  };

  # Set your time zone.
  time.timeZone = "America/Belem";

  
  # Disable background antivirus daemon for performance (use manual scans if needed)
  services.clamav.daemon.enable = false;
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
    percentageLow = 15;
    percentageCritical = 7;
    percentageAction = 5;
    criticalPowerAction = "Ignore";
    allowRiskyCriticalPowerAction = true;
  };

  # Enable PAM integration for automatic unlocking (example for greetd)
  security.pam.services.login.enableGnomeKeyring = true;
  services.gnome.gnome-keyring.enable = true;
  services.gvfs.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Enable Tor service
  services.tor = {
    enable = true;
    client.enable = true;
  };

  # flatpak to install additional apps if needed
  services.flatpak.enable = true; 
  services.dbus.enable = true;
  services.dbus.implementation = "broker";

  # Modern OOM management
  services.earlyoom.enable = false;
  systemd.oomd.enable = true;
  systemd.oomd.enableUserSlices = true;

  # Auto-prioritize active apps
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };



  # Display manager — Niri is the default session
  services.displayManager.defaultSession = "niri";

  # Pure Wayland Login Manager (greetd + tuigreet)
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
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
    settings = {
      Login = {
        HandleLidSwitch = "ignore";
        HandleLidSwitchExternalPower = "lock";
        HandlePowerKey = "poweroff";
        HandlePowerKeyLongPress = "poweroff";
        HandleSuspendKey = "suspend";
        HandleHibernateKey = "hibernate";
        HandleRebootKey = "reboot";
      };
    };
  };


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
      mesa
      # AMD specific drivers and compute
      stable.rocmPackages.clr
      stable.rocmPackages.rocm-runtime
    ];
    
    extraPackages32 = with pkgs.pkgsi686Linux; [
      vulkan-loader
      mesa
    ];
  };

  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableAllFirmware = true;
  # Disabled PulseAudio in favor of PipeWire for Wayland/Niri compatibility
  services.pulseaudio.enable = false;
  
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
  services.blueman.enable = true;

  # Make Qt applications (like VLC) properly render under Wayland/Niri
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.defaultUserShell = stable.zsh;
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
    stable.vim
    stable.neovim
    stable.helix              # Modal editor (Rust-based, built-in LSP)
    stable.emacs
    ((builtins.getFlake "github:jacopone/antigravity-nix").packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-no-fhs.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        wrapProgram $out/bin/antigravity \
          --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland"
      '';
    }))
    unstable.code-cursor
    stable.vscode
    stable.windsurf
    # trae  # FIXME: build broken
    # qoder  # FIXME: build broken

    # ══════════════════════════════════════════════════════════
    # Terminal / Multiplexers
    # ══════════════════════════════════════════════════════════
    stable.ghostty            # GPU-accelerated terminal (Zig-based)
    stable.alacritty
    stable.tmux
    stable.zellij

    # ══════════════════════════════════════════════════════════
    # Backend Development (Languages & DB)
    # ══════════════════════════════════════════════════════════
    stable.go
    stable.rustc
    stable.cargo
    stable.rust-analyzer
    stable.python312
    stable.elixir
    stable.ruby
    # Database clients
    stable.mycli               # Smart MySQL CLI
    stable.pgcli             # Smart PostgreSQL CLI
    stable.litecli           # Smart SQLite CLI
    stable.dbeaver-bin       # Universal visual DB client
    stable.mongodb-compass   # MongoDB GUI
    stable.redis             # In-memory data store
    stable.postman           # API testing GUI
    stable.grpcurl           # gRPC CLI client
    stable.ghz               # gRPC benchmarking
    stable.httpie            # Human-friendly HTTP client
    stable.devenv            # Developer environments
    stable.gnumake           # Makefile support
    stable.go-task           # Taskfile runner (task)
    stable.nodejs            # Node.js runtime (provides npx)

    # ══════════════════════════════════════════════════════════
    # Frontend Development
    # ══════════════════════════════════════════════════════════
    stable.bun               # Fast JS runtime / bundler
    stable.deno              # Secure JS/TS runtime
    stable.pnpm              # Fast Node package manager
    stable.yarn              # Node package manager
    stable.typescript        # TypeScript compiler
    stable.eslint            # JS/TS linter
    stable.prettier          # Code formatter

    # ══════════════════════════════════════════════════════════
    # DevOps / Infrastructure
    # ══════════════════════════════════════════════════════════
    stable.kubectl           # Kubernetes CLI
    stable.kubernetes-helm   # Helm charts
    stable.k9s               # Kubernetes TUI
    stable.freelens-bin      # Kubernetes IDE
    stable.opentofu          # IaC (open-source Terraform fork)
    stable.terraform         # IaC
    stable.ansible           # Configuration management
    stable.packer            # Machine image builder
    stable.vault-bin           # Secrets management
    stable.consul            # Service discovery
    stable.dive              # Docker layer explorer
    stable.act               # Run GitHub Actions locally
    stable.checkov             # IaC security scanner
    stable.tflint            # Terraform linter
    stable.hadolint          # Dockerfile linter
    stable.shellcheck        # Shell script analyzer
    stable.shfmt             # Shell script formatter
    stable.lazydocker        # Docker TUI
    stable.docker-compose    # Container orchestration

    # ── Cloud Provider CLIs ──────────────────────────────────
    stable.google-cloud-sdk  # GCP CLI (gcloud, gsutil, bq)
    stable.awscli2           # AWS CLI v2
    stable.oci-cli           # Oracle Cloud CLI
    stable.doctl             # DigitalOcean CLI
    stable.python312Packages.ovh  # OVHCloud Python SDK/CLI

    # ══════════════════════════════════════════════════════════
    # QA / Testing / Load Testing
    # ══════════════════════════════════════════════════════════
    stable.k6                # Modern load testing (JS scripted)
    stable.vegeta            # HTTP load testing
    stable.hey               # HTTP load generator (ab replacement)
    stable.xh                # Fast HTTP requests (curl alternative)
    stable.jmeter            # Java-based load testing GUI
    stable.wrk2              # HTTP benchmark
    stable.gatling           # HTTP load testing

    # ══════════════════════════════════════════════════════════
    # Data Analytics (Python)
    # ══════════════════════════════════════════════════════════
    stable.python312Packages.pandas        # Data manipulation
    stable.python312Packages.numpy         # Numerical computing
    stable.python312Packages.matplotlib    # Plotting / visualization
    stable.python312Packages.scikit-learn  # Machine learning
    stable.python312Packages.jupyter       # Notebooks
    stable.python312Packages.ipython       # Enhanced Python REPL
    stable.python312Packages.requests      # HTTP for Python
    stable.python312Packages.sqlalchemy    # Python ORM
    stable.python312Packages.polars        # Fast DataFrames
    stable.python312Packages.duckdb        # DuckDB Python bindings
    stable.python312Packages.dask          # Parallel computing
    stable.python312Packages.plotly          # Interactive visualization
    stable.python312Packages.bokeh           # Interactive web plotting
    stable.pspp                            # SPSS alternative (.sav editor)
    # ══════════════════════════════════════════════════════════
    # Data Engineering / Big Data
    # ══════════════════════════════════════════════════════════
    stable.duckdb            # Fast analytical DB
    stable.spark             # Big data processing
    stable.visidata          # Data exploration TUI
    stable.clickhouse-cli    # ClickHouse client

    # ══════════════════════════════════════════════════════════
    # AI / ML Engineering
    # ══════════════════════════════════════════════════════════
    stable.ollama                          # Local LLM runner
    stable.gemini-cli-bin                  # Google Gemini CLI
    stable.aider-chat                      # AI pair programming in terminal
    stable.opencode                        # AI coding agent built for the terminal
    stable.crush                           # Glamourous AI coding agent for your terminal
    stable.goose-cli                       # Open-source, extensible AI agent
    (import ./cline.nix { pkgs = stable; }) # Cline AI CLI (Custom Package)
    stable.python312Packages.fastapi       # ML API framework
    stable.python312Packages.uvicorn       # ASGI server
    stable.python312Packages.pydantic      # Data validation
    stable.python312Packages.httpx         # Async HTTP client
    stable.python312Packages.boto3         # AWS SDK for Python
    stable.python312Packages.rich          # Beautiful terminal output

    # ══════════════════════════════════════════════════════════
    # Language Servers / Linters (Neovim / IDE support)
    # ══════════════════════════════════════════════════════════
    stable.lua-language-server                         # Lua LSP
    stable.stylua                                      # Lua formatter
    stable.gopls                                       # Go LSP
    stable.pyright                                     # Python LSP
    stable.ruff                                        # Python fast linter / formatter
    stable.nixd                                        # Nix LSP
    stable.yaml-language-server                        # YAML LSP
    stable.vscode-langservers-extracted                 # HTML/CSS/JSON LSPs
    stable.nodePackages.typescript-language-server      # TS/JS LSP
    stable.clang-tools                                 # C/C++ LSP (clangd)
    stable.jdt-language-server                         # Java LSP (jdtls)
    stable.omnisharp-roslyn                            # C# LSP
    stable.sqls                                        # SQL LSP
    stable.metals                                      # Scala LSP
    stable.dart                                      # Dart SDK (includes LSP)
    stable.kotlin-language-server                      # Kotlin LSP
    stable.clojure-lsp                                 # Clojure LSP
    stable.haskell-language-server                     # Haskell LSP
    stable.alire                                       # Ada package manager (standard for Ada development)
    stable.tree-sitter                                 # Multi-lang parser

    # ══════════════════════════════════════════════════════════
    # Daily CLI Productivity (Modern Replacements)
    # ══════════════════════════════════════════════════════════
    stable.bat               # cat with syntax highlighting
    stable.eza               # Modern ls replacement
    stable.zoxide            # Smart cd with memory
    stable.fd                # Fast find replacement
    stable.ripgrep           # Fast recursive grep (rg)
    stable.fzf               # Interactive fuzzy finder
    stable.delta             # Better git diffs
    stable.dust              # du visualization
    stable.duf               # df replacement
    stable.procs             # Modern ps replacement
    stable.bottom            # htop alternative (btm)
    stable.tokei             # Count lines of code
    stable.glow              # Render markdown in terminal
    stable.hyperfine         # CLI benchmarking
    stable.tldr              # Simplified man pages
    stable.difftastic        # Syntax-aware diff
    stable.ncdu              # Disk usage analyzer (TUI)
    stable.watchexec         # File watcher + command runner
    stable.yq                # YAML/XML processor
    stable.meld              # Visual diff / merge tool

    # ══════════════════════════════════════════════════════════
    # Git & Version Control
    # ══════════════════════════════════════════════════════════
    stable.git
    stable.git-lfs
    stable.gh                # GitHub CLI
    stable.lazygit           # Git TUI
    stable.gittuf            # Git trust framework

    # ══════════════════════════════════════════════════════════
    # Networking Tools
    # ══════════════════════════════════════════════════════════
    stable.curl
    stable.wget
    stable.aria2             # Download accelerator
    stable.mosh              # Persistent SSH
    stable.sshfs
    stable.fuse3
    stable.nmap
    stable.tcpdump           # Traffic analyzer
    stable.ethtool
    stable.iftop             # Network bandwidth monitor
    stable.iotop             # I/O monitor
    stable.dig
    stable.mitmproxy           # HTTP/HTTPS proxy
    stable.ettercap          # Network sniffer/MITM toolk
    stable.cifs-utils
    stable.wireshark
    stable.tshark
    stable.termshark

    # ══════════════════════════════════════════════════════════
    # Security — CLI Tools
    # ══════════════════════════════════════════════════════════
    stable.uv                # Python package manager
    stable.vulnix            # Nix vulnerability scanner
    stable.lynis             # System audit
    stable.sqlmap            # SQL injection tool
    stable.sqlmc
    stable.laudanum
    stable.nikto             # Web server scanner
    stable.hcxtools          # WiFi capture tools
    stable.hashcat           # Password recovery
    stable.thc-hydra         # Login cracker
    stable.gobuster          # Directory brute-forcer
    stable.wireguard-tools   # VPN
    stable.metasploit          # Exploitation framework
    stable.sssd
    stable.aircrack-ng       # WiFi security
    stable.dockle            # Container security linter
    stable.checkmate
    stable.tracee            # Runtime security
    stable.apktool           # Android reverse engineering
    stable.radare2           # Binary analysis
    stable.ghidra-bin        # Reverse engineering suite
    stable.zap               # OWASP ZAP proxy
    stable.wapiti              # Web vulnerability scanner
    stable.nuclei            # Template-based vulnerability scanner
    stable.octoscan
    stable.osv-scanner       # Open Source vulnerability scanner
    stable.http-scanner
    stable.secretscanner     # Secret detection
    stable.netscanner
    stable.mdns-scanner

    # ══════════════════════════════════════════════════════════
    # Security — GUI Tools
    # ══════════════════════════════════════════════════════════
    stable.johnny            # John the Ripper GUI
    stable.burpsuite         # Web security testing
    stable.cutter            # Reverse engineering GUI
    stable.degate            # IC reverse engineering
    stable.iaito             # Radare2 GUI

    # ══════════════════════════════════════════════════════════
    # Privacy & Anonymity (Tor / Onion)
    # ══════════════════════════════════════════════════════════
    stable.tor               # Core Tor daemon
    stable.tor-browser       # Tor Browser
    stable.nyx               # Tor monitor (TUI)
    stable.torsocks          # Tor-wrap applications
    stable.onioncircuits     # Visualize Tor circuits
    stable.onionshare-gui    # Secure file sharing over Tor
    stable.proxychains-ng    # Proxy wrapper

    # ══════════════════════════════════════════════════════════
    # Screenshot / Screen Capture (Wayland)
    # ══════════════════════════════════════════════════════════
    stable.grim              # Screenshot capture
    stable.slurp             # Region selection
    stable.swappy            # Quick annotation/editing
    stable.flameshot         # Feature-rich screenshots

    # ══════════════════════════════════════════════════════════
    # Wayland / Niri / Desktop Environment
    # ══════════════════════════════════════════════════════════
    stable.fuzzel            # App launcher
    stable.waybar            # Status bar
    stable.wlsunset          # Night light
    stable.swaylock          # Screen locker
    stable.swaybg            # Wallpaper
    stable.swaynotificationcenter  # Notifications
    stable.xwayland-satellite
    stable.polkit_gnome
    stable.quickshell        # Shell framework
    unstable.dms-shell       # DankMaterialShell (via unstable — not yet in stable 25.11)
    unstable.dgop            # System monitor backend (via unstable — not yet in stable 25.11)
    stable.wtype             # Wayland keyboard input simulator
    stable.wl-clipboard      # Wayland clipboard (replaces xclip)
    stable.brightnessctl     # Backlight control (replaces xbacklight)
    stable.gtk_engines
    stable.gtk-engine-murrine
    stable.gnome-themes-extra
    stable.adwaita-icon-theme
    stable.copyq               # Clipboard manager

    # ══════════════════════════════════════════════════════════
    # Browsers
    # ══════════════════════════════════════════════════════════
    (stable.vivaldi.override {
      commandLineArgs = "--enable-features=UseOzonePlatform --ozone-platform=wayland";
    })
    stable.vivaldi-ffmpeg-codecs
    (stable.google-chrome.override {
      commandLineArgs = "--enable-features=UseOzonePlatform --ozone-platform=wayland";
    })
    stable.firefox-bin

    # ══════════════════════════════════════════════════════════
    # Communication / Remote
    # ══════════════════════════════════════════════════════════
    anydesk
    stable.rustdesk-flutter   # Remote desktop (Wayland-native via PipeWire)
    stable.remmina
    stable.teamviewer

    # ══════════════════════════════════════════════════════════
    # Authentication / Passwords
    # ══════════════════════════════════════════════════════════
    stable.google-authenticator
    stable._1password-gui
    stable.authenticator
    stable.libsecret
    stable.openssl

    # ══════════════════════════════════════════════════════════
    # File Manager / Disk Utils
    # ══════════════════════════════════════════════════════════
    stable.nautilus
    stable.gnome-disk-utility
    stable.gparted
    stable.vifm-full         # Terminal file manager

    # ══════════════════════════════════════════════════════════
    # Multimedia
    # ══════════════════════════════════════════════════════════
    stable.vlc                 # Media player
    stable.ffmpeg              # Video/audio converter
    stable.kdePackages.kdenlive  # Video editor
    stable.qtractor            # Audio workstation
    stable.inkscape            # Vector graphics
    stable.gimp                # Image editor
    stable.pavucontrol       # Audio volume control
    stable.alsa-utils        # ALSA utilities
    stable.qbittorrent       # Torrent client
    stable.lux               # Video downloader

    # ══════════════════════════════════════════════════════════
    # Archive / Compression
    # ══════════════════════════════════════════════════════════
    stable.zip
    stable.unzip
    stable.xz
    stable.unar
    stable.xar
    stable.pbzx
    stable.zlib

    # ══════════════════════════════════════════════════════════
    # System Utilities / Libraries
    # ══════════════════════════════════════════════════════════
    stable.fastfetch         # System info (neofetch replacement)
    stable.htop              # Process monitor
    stable.tree              # Directory tree
    stable.psmisc            # Provides fuser, killall, pstree
    stable.lsof              # List open files
    stable.inxi              # System info (detailed)
    stable.dmidecode         # Hardware info
    stable.lm_sensors        # Temperature / fans
    stable.wirelesstools
    stable.inetutils
    stable.libnotify
    stable.yad               # GUI dialogs from shell
    stable.nix-index         # Nix package file search
    stable.bc                # Calculator
    stable.file              # File type detection
    stable.jq                # JSON processor
    stable.just              # Command runner
    stable.pay-respects      # Correct previous command
    stable.direnv            # Per-directory env vars
    stable.fasd              # Quick directory access
    stable.rcodesign         # Apple code signing

    # ══════════════════════════════════════════════════════════
    # Temperature Monitoring & Thermal Management
    # ══════════════════════════════════════════════════════════

    stable.s-tui             # Terminal CPU stress test & temp monitor
    stable.stress            # System stress testing (used by s-tui)
    stable.stress-ng         # Advanced stress testing
    stable.zenmonitor        # AMD Ryzen temperature monitor
    stable.linuxPackages_zen.cpupower  # Manual CPU frequency control

    # ══════════════════════════════════════════════════════════
    # Specialized Tools
    # ══════════════════════════════════════════════════════════
    stable.android-tools     # Android development tools
    stable.logseq            # Knowledge management (stable.logseq found earlier)
    stable.texstudio         # LaTeX editor
    stable.texlive.combined.scheme-medium # LaTeX compiler (pdflatex, etc)
    stable.tectonic          # Modern C++ LaTeX compiler (no setup required)
    # stable.spec-kit          # Spec-Driven Development toolkit (not in stable 25.11)

    # ══════════════════════════════════════════════════════════
    # Study / Education
    # ══════════════════════════════════════════════════════════
    stable.anki-bin          # Spaced repetition flashcards (binary is often preferred for Anki)
    stable.obsidian          # Second brain / Markdown knowledge base
    stable.zotero            # Top tier reference and research management
    stable.mendeley          # Elsevier reference manager (unfree)
    # stable.jabref            # Open-source BibTeX/BibLaTeX bibliography manager
    stable.xournalpp         # PDF annotation and handwritten notes
    stable.kdePackages.okular # Feature-rich document and PDF viewer
    stable.super-productivity  # ToDo list, Time tracker, Pomodoro timer (stable: Electron 39 broken on unstable)

    # ══════════════════════════════════════════════════════════
    # Financial Markets / Trading (B3 & USA)
    # ══════════════════════════════════════════════════════════

    # ── MT5 / Wine Management ────────────────────────────────
    stable.bottles             # Wine prefix manager (install MT5 here)

    # ── Windows VM (ProfitPro / Nelogica) ────────────────────
    # ProfitPro is a .NET Windows app that does NOT work in Wine/Bottles.
    # Run it in a lightweight Windows 10/11 VM via QEMU/KVM instead.
    stable.virt-manager        # GUI for managing QEMU/KVM virtual machines
    stable.spice-gtk           # SPICE client (clipboard, USB, display for VMs)
    stable.win-spice           # Windows SPICE guest drivers
    stable.virtio-win          # VirtIO drivers for Windows guests (disk, network, GPU)
    stable.quickemu            # Easy VM launcher (used by win10-vm.sh script)

    # ── Technical Analysis C Libraries ───────────────────────
    stable.ta-lib              # TA-Lib C library (technical indicators)
    stable.quantlib            # QuantLib C++ (quantitative finance)

    # ── Python: Market Data & Finance ────────────────────────
    stable.python312Packages.yfinance         # Yahoo Finance (stocks, ETFs, options)
    stable.python312Packages.mplfinance       # Candlestick / OHLCV charts
    stable.python312Packages.beautifulsoup4   # Web scraping (B3/SEC filings)
    stable.python312Packages.lxml             # Fast XML/HTML parsing
    stable.python312Packages.selenium         # Browser automation (broker portals)
    stable.python312Packages.tweepy           # Twitter API (market sentiment)
    stable.python312Packages.arrow            # Human-friendly dates/times

    # ── Python: Technical & Statistical Analysis ─────────────
    stable.python312Packages.scipy            # Scientific computing
    stable.python312Packages.statsmodels      # Econometrics / time-series
    stable.python312Packages.seaborn          # Statistical visualization

    # ── Python: Async & Real-Time Data ───────────────────────
    stable.python312Packages.websockets       # WebSocket protocol
    stable.python312Packages.websocket-client # WebSocket client
    stable.python312Packages.aiohttp         # Async HTTP client/server

    # ── Python: Scheduling & Notifications ───────────────────
    stable.python312Packages.schedule          # Lightweight job scheduler
    stable.python312Packages.apscheduler      # Advanced Python scheduler
    stable.python312Packages.python-telegram-bot  # Telegram trade alerts
    stable.python312Packages.pytz             # Timezone handling (B3 = America/Sao_Paulo)

    # ── Python: Reporting & Data Export ──────────────────────
    stable.python312Packages.openpyxl         # Excel read/write
    stable.python312Packages.xlsxwriter       # Excel report generation
    stable.python312Packages.pyyaml           # YAML config files

    # ══════════════════════════════════════════════════════════
    # Gaming (Lutris / Wine / Vulkan)
    # ══════════════════════════════════════════════════════════
    stable.lutris
    stable.gamescope           # Nested compositor (fix Wine/XWayland in Niri)
    stable.wineWow64Packages.waylandFull
    stable.winetricks
    stable.mangohud
    stable.vulkan-extension-layer

    stable.mesa-demos
    stable.dxvk              # DirectX -> Vulkan
    stable.scanmem           # GameConqueror (Memory Editor for games)

    # ══════════════════════════════════════════════════════════

  ];

  fonts.packages = [
    stable.noto-fonts
    stable.noto-fonts-cjk-sans
    stable.noto-fonts-color-emoji
    stable.liberation_ttf
    stable.fira-code
    stable.fira-code-symbols
    stable.mplus-outline-fonts.githubRelease
    stable.dina-font
    stable.proggyfonts
    stable.meslo-lgs-nf
    stable.vista-fonts
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
      stable.glibc
      stable.libGL
      stable.libGLU
      stable.libxml2
      stable.icu
      stable.libiconv
      stable.zlib
      stable.expat
      stable.nss
    ];
    niri.enable = true;
  };

  # ── Thermal Management ────────────────────────────────────────

  # Thermal daemon — dynamic thermal management for CPU/GPU
  services.thermald.enable = true;

  # Auto CPU frequency scaling based on temperature & load
  services.auto-cpufreq = {
    enable = true;
    settings = {
      battery = {
        governor = "powersave";
        turbo = "never";
      };
      charger = {
        governor = "powersave";
        turbo = "never";
      };
    };
  };

  # Load AMD temperature sensor kernel module
  boot.kernelModules = [ "k10temp" "zenpower" ];

  # ── Disable CPU Turbo Boost at Boot (thermal safety) ──────────
  # Prevents CPU from exceeding safe thermal limits under load
  systemd.services.disable-cpu-boost = {
    description = "Disable CPU turbo boost for thermal stability";
    wantedBy = [ "multi-user.target" ];
    after = [ "sysinit.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "/bin/sh -c 'echo 0 > /sys/devices/system/cpu/cpufreq/boost'";
      ExecStop  = "/bin/sh -c 'echo 1 > /sys/devices/system/cpu/cpufreq/boost'";
    };
  };

  # Set Google Chrome as default browser for all applications
  xdg.mime.defaultApplications = {
    "x-scheme-handler/http" = "google-chrome.desktop";
    "x-scheme-handler/https" = "google-chrome.desktop";
    "x-scheme-handler/about" = "google-chrome.desktop";
    "x-scheme-handler/unknown" = "google-chrome.desktop";
    "text/html" = "google-chrome.desktop";
    "application/xhtml+xml" = "google-chrome.desktop";
  };

  # Screen sharing and Portals for Niri
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ 
    pkgs.xdg-desktop-portal-gnome
    pkgs.xdg-desktop-portal-gtk 
  ];
  xdg.portal.config = {
    niri = {
      default = [ "gnome" "gtk" ];
      # Use GTK portal for OpenURI — GNOME portal shows invisible confirmation
      # dialog under Niri, blocking cursor:// and other custom protocol redirects
      "org.freedesktop.impl.portal.OpenURI" = [ "gtk" ];
    };
    # Fallback for apps that don't match a specific desktop
    common.default = [ "gtk" "gnome" ];
  };
  
  # Ensure Nautilus file picker works in browsers
  services.gnome.sushi.enable = true;  # Quick file previewer

  networking.firewall.enable = false;
  networking.networkmanager.enable = true;

  # ── DNS Optimization ──
  # Use fast public DNS instead of slow ISP DNS
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" "1.0.0.1" "8.8.4.4" ];
  networking.networkmanager.dns = "none"; # Prevent NM from overwriting resolv.conf

  # ── Force Ethernet 100 Mb/s ──
  # Auto-negotiation is falling to 10 Mb/s (likely bad cable) — force 100 Mb/s
  networking.networkmanager.dispatcherScripts = [{
    source = pkgs.writeText "force-100mbps" ''
      #!/bin/sh
      IFACE=$1
      ACTION=$2
      if [ "$IFACE" = "enp1s0" ] && [ "$ACTION" = "up" ]; then
        ${pkgs.ethtool}/bin/ethtool -s enp1s0 speed 100 duplex full autoneg on
      fi
    '';
    type = "basic";
  }];
  
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

  # Disable documentation builds to bypass broken unstable packages (e.g. python3.12-doc)
  documentation.doc.enable = false;
  
  programs.dconf = {
    enable = true; # virt-manager requires dconf to remember settings
    profiles.user.databases = [{
      settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
        };
      };
    }];
  };

  virtualisation.docker.enable = true;
  users.extraGroups.docker.members = [ "zen" ];
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "zen" ];
  # virtualisation.virtualbox.host.enableExtensionPack = true;
  # virtualisation.virtualbox.guest.enable = true;
  # virtualisation.virtualbox.guest.dragAndDrop = true;

  # Environment variables for Vulkan and gaming
  environment.sessionVariables = {
    # Default browser for CLI tools and IDEs
    BROWSER = "google-chrome-stable";

    # Antigravity — use Google Chrome for browser subagent interactions
    CHROME_PATH = "${stable.google-chrome}/bin/google-chrome-stable";
    ANTIGRAVITY_BROWSER = "${stable.google-chrome}/bin/google-chrome-stable";

    # Force xdg-open to use XDG Desktop Portal (D-Bus) instead of
    # spawning browser directly — returns focus to calling app immediately
    NIXOS_XDG_OPEN_USE_PORTAL = "1";

    # Vulkan ICD selection
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/radeon_icd.i686.json";
    
    # Wine/Lutris optimizations
    WINE_LARGE_ADDRESS_AWARE = "1";
    # NOTE: WINEDLLOVERRIDES removido — desabilitava mscoree (.NET runtime),
    # quebrando apps .NET no Bottles (ex: trydpro). Configura por bottle no Bottles.
    # NOTE: DXVK_HUD removido do global — configure por bottle se precisar depurar.
    WINEFSYNC = "1";
    
    # Kerberos fix
    KRB5_CONFIG = "/etc/krb5.conf";

    # Wayland native support for Electron/Chromium
    NIXOS_OZONE_WL = "1";

    # Global Cursor Consistency
    XCURSOR_SIZE = "16";
    XCURSOR_THEME = "volantes_cursors";

    # Force Dark Theme for GTK and Qt apps
    GTK_THEME = "Adwaita:dark";
  };

  environment.shellAliases = {
    nix-up = "sudo nixos-rebuild switch --upgrade --cores 0 -j auto";
    nix-boot = "sudo nixos-rebuild boot --upgrade --cores 0 -j auto";
  };

  # Optimise Nix store
  nix.settings.auto-optimise-store = false;
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

  # ZRAM Swap - compression in RAM to save disk space
  zramSwap = {
    enable = false;
  };

}

