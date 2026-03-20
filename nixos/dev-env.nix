# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Universal Dev Environment — Nix Shell                                     ║
# ║                                                                            ║
# ║  Cross-platform (Linux, macOS, WSL) development shell.                     ║
# ║  Prioritizes pre-built binaries (nixpkgs cache) — no local compilation.    ║
# ║                                                                            ║
# ║  SETUP (one-time):                                                         ║
# ║    1. Install Nix:                                                         ║
# ║       sh <(curl -L https://nixos.org/nix/install) --daemon                 ║
# ║                                                                            ║
# ║    2. Enable flakes (add to ~/.config/nix/nix.conf):                       ║
# ║       experimental-features = nix-command flakes                           ║
# ║                                                                            ║
# ║  USAGE:                                                                    ║
# ║    • Full environment:   nix-shell dev-env.nix                             ║
# ║    • Specific profile:   nix-shell dev-env.nix -A backend                  ║
# ║    • Available profiles: backend, frontend, devops, data, ai, security,    ║
# ║                          qa, tools, all (default)                          ║
# ║                                                                            ║
# ║  TIP: Add alias to your .bashrc/.zshrc:                                    ║
# ║    alias devenv='nix-shell ~/dev-env.nix'                                  ║
# ║    alias devenv-back='nix-shell ~/dev-env.nix -A backend'                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

let
  # Pin nixpkgs for reproducibility — update hash to bump versions
  nixpkgs = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
  };

  # Auto-detect current platform (x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin)
  system = builtins.currentSystem;
  isLinux  = builtins.match ".*-linux"  system != null;
  isDarwin = builtins.match ".*-darwin" system != null;

  pkgs = import nixpkgs {
    inherit system;
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [ ];
    };
  };

  # Helper: include package only on Linux
  linuxOnly = pkg: if isLinux then [ pkg ] else [];
  # Helper: include list of packages only on Linux
  linuxOnlyList = list: if isLinux then list else [];

  # ────────────────────────────────────────────────────────────────────────────
  # Package Groups — Pre-built binaries only (no source compilation)
  # ────────────────────────────────────────────────────────────────────────────

  # Editors (CLI only — GUI editors install via native package manager)
  editors = with pkgs; [
    vim
    neovim
  ];

  # Terminal / Multiplexers
  terminals = with pkgs; [
    tmux
    zellij
  ];

  # Backend Development (Languages & DB clients)
  backendDev = with pkgs; [
    go
    rustc
    cargo
    rust-analyzer
    python312
    elixir
    ruby
    # Database clients (all pre-built)
    mycli                       # Smart MySQL CLI
    pgcli                       # Smart PostgreSQL CLI
    litecli                     # Smart SQLite CLI
    redis                       # In-memory data store
    grpcurl                     # gRPC CLI client
    ghz                         # gRPC benchmarking
    httpie                      # Human-friendly HTTP client
    devenv                      # Developer environments
    gnumake                     # Makefile support
  ];

  # Frontend Development
  frontendDev = with pkgs; [
    bun                         # Fast JS runtime / bundler
    deno                        # Secure JS/TS runtime
    pnpm                        # Fast Node package manager
    yarn                        # Node package manager
    typescript                  # TypeScript compiler
    eslint                      # JS/TS linter
    prettier                    # Code formatter
  ];

  # DevOps / Infrastructure
  devops = with pkgs; [
    kubectl                     # Kubernetes CLI
    kubernetes-helm             # Helm charts
    k9s                         # Kubernetes TUI
    opentofu                    # IaC (open-source Terraform fork)
    terraform                   # IaC
    ansible                     # Configuration management
    packer                      # Machine image builder
    vault-bin                   # Secrets management (binary)
    consul                      # Service discovery
    dive                        # Docker layer explorer
    act                         # Run GitHub Actions locally
    checkov                     # IaC security scanner
    tflint                      # Terraform linter
    hadolint                    # Dockerfile linter
    shellcheck                  # Shell script analyzer
    shfmt                       # Shell script formatter
    lazydocker                  # Docker TUI
    docker-compose              # Container orchestration
  ];

  # Cloud Provider CLIs (all pre-built binaries)
  cloudCLIs = with pkgs; [
    google-cloud-sdk            # GCP CLI (gcloud, gsutil, bq)
    awscli2                     # AWS CLI v2
    doctl                       # DigitalOcean CLI
  ] ++ linuxOnly oci-cli;       # Oracle Cloud CLI (Linux only)

  # QA / Testing / Load Testing
  qaTools = with pkgs; [
    k6                          # Modern load testing (JS scripted)
    vegeta                      # HTTP load testing
    hey                         # HTTP load generator (ab replacement)
    xh                          # Fast HTTP requests (curl alternative)
    wrk2                        # HTTP benchmark
  ];

  # Data Engineering (CLI tools, pre-built)
  dataEngineering = with pkgs; [
    duckdb                      # Fast analytical DB
    visidata                    # Data exploration TUI
  ];

  # AI / ML Engineering (CLI agents & tools, pre-built)
  aiML = with pkgs; [
    gemini-cli-bin              # Google Gemini CLI (binary)
    aider-chat                  # AI pair programming in terminal
    opencode                    # AI coding agent built for the terminal
    crush                       # Glamourous AI coding agent for your terminal
    goose-cli                   # Open-source, extensible AI agent
  ] ++ linuxOnly ollama;        # Local LLM runner (Linux only)

  # Language Servers / Linters (pre-built — removed those that compile from source)
  languageServers = with pkgs; [
    lua-language-server                     # Lua LSP
    stylua                                  # Lua formatter
    gopls                                   # Go LSP
    pyright                                 # Python LSP (pre-built)
    ruff                                    # Python fast linter / formatter
    nixd                                    # Nix LSP
    yaml-language-server                    # YAML LSP
    vscode-langservers-extracted            # HTML/CSS/JSON LSPs
    nodePackages.typescript-language-server  # TS/JS LSP
    sqls                                    # SQL LSP
    dart-bin                                # Dart SDK (binary, includes LSP)
    kotlin-language-server                  # Kotlin LSP
    tree-sitter                             # Multi-lang parser
  ];

  # Daily CLI Productivity (Modern Replacements — all pre-built Go/Rust binaries)
  cliProductivity = with pkgs; [
    bat                         # cat with syntax highlighting
    eza                         # Modern ls replacement
    zoxide                      # Smart cd with memory
    fd                          # Fast find replacement
    ripgrep                     # Fast recursive grep (rg)
    fzf                         # Interactive fuzzy finder
    delta                       # Better git diffs
    dust                        # du visualization
    duf                         # df replacement
    procs                       # Modern ps replacement
    bottom                      # htop alternative (btm)
    tokei                       # Count lines of code
    glow                        # Render markdown in terminal
    hyperfine                   # CLI benchmarking
    tldr                        # Simplified man pages
    difftastic                  # Syntax-aware diff
    ncdu                        # Disk usage analyzer (TUI)
    watchexec                   # File watcher + command runner
    yq                          # YAML/XML processor
  ];

  # Git & Version Control
  gitTools = with pkgs; [
    git
    git-lfs
    gh                          # GitHub CLI
    lazygit                     # Git TUI
    gittuf                      # Git trust framework
  ];

  # Networking Tools
  networkingTools = with pkgs; [
    curl
    wget
    aria2                       # Download accelerator
    mosh                        # Persistent SSH
    nmap
  ] ++ linuxOnlyList (with pkgs; [
    sshfs                       # SSHFS (Linux only)
    fuse3                       # FUSE3 (Linux only)
    tcpdump                     # Traffic analyzer
    ethtool
    iftop                       # Network bandwidth monitor
    iotop                       # I/O monitor
    dig
    termshark
    tshark
  ]);

  # Security — CLI Tools (pre-built)
  securityCLI = with pkgs; [
    uv                          # Python package manager (Rust binary)
    lynis                       # System audit
    sqlmap                      # SQL injection tool
    nikto                       # Web server scanner
    gobuster                    # Directory brute-forcer
    wireguard-tools             # VPN
    nuclei                      # Template-based vulnerability scanner
    osv-scanner                 # Open Source vulnerability scanner
    secretscanner               # Secret detection
    dockle                      # Container security linter
  ] ++ linuxOnlyList (with pkgs; [
    hashcat                     # Password recovery (Linux)
    thc-hydra                   # Login cracker (Linux)
    aircrack-ng                 # WiFi security (Linux)
    hcxtools                    # WiFi capture tools (Linux)
    apktool                     # Android reverse engineering
    radare2                     # Binary analysis
    ghidra-bin                  # Reverse engineering suite (binary)
  ]);

  # System Utilities (all pre-built)
  systemUtils = with pkgs; [
    fastfetch                   # System info (neofetch replacement)
    htop                        # Process monitor
    tree                        # Directory tree
    lsof                        # List open files
    nix-index                   # Nix package file search
    bc                          # Calculator
    file                        # File type detection
    jq                          # JSON processor
    just                        # Command runner
    pay-respects                # Correct previous command
    direnv                      # Per-directory env vars
    openssl
    zip
    unzip
    xz
  ] ++ linuxOnlyList (with pkgs; [
    psmisc                      # Provides fuser, killall, pstree (Linux)
    inxi                        # System info — detailed (Linux)
  ]);

  # Multimedia (CLI only, pre-built)
  multimediaCLI = with pkgs; [
    ffmpeg                      # Video/audio converter
  ];

  # ────────────────────────────────────────────────────────────────────────────
  # Shell hook — banner + environment setup
  # ────────────────────────────────────────────────────────────────────────────

  devShellHook = ''
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  🚀 Dev Environment Ready!  [${system}]                  ║"
    echo "║                                                         ║"
    echo "║  Languages: Go, Rust, Python, Elixir, Ruby, TS/JS       ║"
    echo "║  DBs:       PostgreSQL, MySQL, SQLite, Redis, DuckDB    ║"
    echo "║  DevOps:    Docker, K8s, Terraform, Ansible, Helm       ║"
    echo "║  Cloud:     GCP, AWS, DigitalOcean                      ║"
    echo "║  AI/ML:     Gemini, Aider, Ollama, Goose                ║"
    echo "║  Tools:     bat, eza, fzf, ripgrep, lazygit, delta      ║"
    echo "║                                                         ║"
    echo "║  Run 'type <cmd>' to check any tool's availability      ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""

    # Auto-setup direnv if available
    if command -v direnv &>/dev/null; then
      eval "$(direnv hook bash 2>/dev/null || direnv hook zsh 2>/dev/null || true)"
    fi

    # Zoxide init
    if command -v zoxide &>/dev/null; then
      eval "$(zoxide init bash 2>/dev/null || zoxide init zsh 2>/dev/null || true)"
    fi
  '';

  # ────────────────────────────────────────────────────────────────────────────
  # Composable profiles — use `nix-shell dev-env.nix -A <profile>`
  # ────────────────────────────────────────────────────────────────────────────

  mkShell = name: packages: pkgs.mkShell {
    inherit name;
    buildInputs = packages;
    shellHook = devShellHook;
  };

in {

  # ── Individual profiles ─────────────────────────────────────────────────────

  backend = mkShell "backend-dev" (
    editors ++ terminals ++ backendDev ++ gitTools ++ cliProductivity ++ systemUtils
  );

  frontend = mkShell "frontend-dev" (
    editors ++ terminals ++ frontendDev ++ gitTools ++ cliProductivity ++ systemUtils
  );

  devops = mkShell "devops-env" (
    editors ++ terminals ++ devops ++ cloudCLIs ++ gitTools
    ++ networkingTools ++ cliProductivity ++ systemUtils
  );

  data = mkShell "data-env" (
    editors ++ terminals ++ dataEngineering
    ++ gitTools ++ cliProductivity ++ systemUtils
  );

  ai = mkShell "ai-ml-env" (
    editors ++ terminals ++ aiML
    ++ gitTools ++ cliProductivity ++ systemUtils
  );

  security = mkShell "security-env" (
    editors ++ terminals ++ securityCLI ++ networkingTools
    ++ gitTools ++ cliProductivity ++ systemUtils
  );

  qa = mkShell "qa-env" (
    editors ++ terminals ++ qaTools ++ networkingTools
    ++ gitTools ++ cliProductivity ++ systemUtils
  );

  tools = mkShell "tools-env" (
    editors ++ terminals ++ cliProductivity ++ gitTools
    ++ systemUtils ++ networkingTools
  );

  # ── Full environment (default) ──────────────────────────────────────────────
  # Usage: nix-shell dev-env.nix

  default = mkShell "full-dev-env" (
    editors
    ++ terminals
    ++ backendDev
    ++ frontendDev
    ++ devops
    ++ cloudCLIs
    ++ qaTools
    ++ dataEngineering
    ++ aiML
    ++ languageServers
    ++ cliProductivity
    ++ gitTools
    ++ networkingTools
    ++ securityCLI
    ++ systemUtils
    ++ multimediaCLI
  );
}
