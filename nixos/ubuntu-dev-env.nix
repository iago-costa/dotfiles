# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Ubuntu Dev Environment — Nix Shell (Single File)                          ║
# ║                                                                            ║
# ║  Replicates all development packages from configuration.nix for use on     ║
# ║  Ubuntu (or any Linux distro with Nix installed).                          ║
# ║                                                                            ║
# ║  SETUP (one-time):                                                         ║
# ║    1. Install Nix:                                                         ║
# ║       sh <(curl -L https://nixos.org/nix/install) --daemon                 ║
# ║                                                                            ║
# ║    2. Enable flakes (add to ~/.config/nix/nix.conf):                       ║
# ║       experimental-features = nix-command flakes                           ║
# ║                                                                            ║
# ║  USAGE:                                                                    ║
# ║    • Full environment:   nix-shell ubuntu-dev-env.nix                      ║
# ║    • Specific profile:   nix-shell ubuntu-dev-env.nix -A backend           ║
# ║    • Available profiles: backend, frontend, devops, data, ai, security,    ║
# ║                          qa, tools, all (default)                          ║
# ║                                                                            ║
# ║  TIP: Add alias to your .bashrc/.zshrc:                                    ║
# ║    alias devenv='nix-shell ~/ubuntu-dev-env.nix'                           ║
# ║    alias devenv-back='nix-shell ~/ubuntu-dev-env.nix -A backend'           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

let
  # Pin nixpkgs for reproducibility — update hash to bump versions
  nixpkgs = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
  };

  pkgs = import nixpkgs {
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [ ];
    };
  };

  # ────────────────────────────────────────────────────────────────────────────
  # Package Groups — Mirrored from configuration.nix systemPackages
  # ────────────────────────────────────────────────────────────────────────────

  # Editors / IDEs (CLI only — GUI editors like VSCode/Cursor install via apt/snap)
  editors = with pkgs; [
    vim
    neovim
    emacs
  ];

  # Terminal / Multiplexers
  terminals = with pkgs; [
    alacritty
    tmux
    zellij
  ];

  # Backend Development (Languages & DB)
  backendDev = with pkgs; [
    go
    rustc
    cargo
    rust-analyzer
    python312
    elixir
    ruby
    # Database clients
    mycli                       # Smart MySQL CLI
    pgcli                       # Smart PostgreSQL CLI
    litecli                     # Smart SQLite CLI
    dbeaver-bin                 # Universal visual DB client
    mongodb-compass             # MongoDB GUI
    redis                       # In-memory data store
    postman                     # API testing GUI
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
    vault-bin                   # Secrets management
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

  # Cloud Provider CLIs
  cloudCLIs = with pkgs; [
    google-cloud-sdk            # GCP CLI (gcloud, gsutil, bq)
    awscli2                     # AWS CLI v2
    oci-cli                     # Oracle Cloud CLI
    doctl                       # DigitalOcean CLI
    python312Packages.ovh       # OVHCloud Python SDK/CLI
  ];

  # QA / Testing / Load Testing
  qaTools = with pkgs; [
    k6                          # Modern load testing (JS scripted)
    vegeta                      # HTTP load testing
    hey                         # HTTP load generator (ab replacement)
    xh                          # Fast HTTP requests (curl alternative)
    jmeter                      # Java-based load testing GUI
    wrk2                        # HTTP benchmark
    gatling                     # HTTP load testing
  ];

  # Data Analytics (Python)
  dataAnalytics = with pkgs; [
    python312Packages.pandas          # Data manipulation
    python312Packages.numpy           # Numerical computing
    python312Packages.matplotlib      # Plotting / visualization
    python312Packages.scikit-learn    # Machine learning
    python312Packages.jupyter         # Notebooks
    python312Packages.ipython         # Enhanced Python REPL
    python312Packages.requests        # HTTP for Python
    python312Packages.sqlalchemy      # Python ORM
    python312Packages.polars          # Fast DataFrames
    python312Packages.duckdb          # DuckDB Python bindings
    python312Packages.dask            # Parallel computing
    python312Packages.plotly          # Interactive visualization
    python312Packages.bokeh           # Interactive web plotting
  ];

  # Data Engineering / Big Data
  dataEngineering = with pkgs; [
    duckdb                      # Fast analytical DB
    spark                       # Big data processing
    visidata                    # Data exploration TUI
  ];

  # AI / ML Engineering
  aiML = with pkgs; [
    ollama                      # Local LLM runner
    gemini-cli-bin              # Google Gemini CLI
    aider-chat                  # AI pair programming in terminal
    opencode                    # AI coding agent built for the terminal
    crush                       # Glamourous AI coding agent for your terminal
    goose-cli                   # Open-source, extensible AI agent
    python312Packages.fastapi   # ML API framework
    python312Packages.uvicorn   # ASGI server
    python312Packages.pydantic  # Data validation
    python312Packages.httpx     # Async HTTP client
    python312Packages.boto3     # AWS SDK for Python
    python312Packages.rich      # Beautiful terminal output
  ];

  # Language Servers / Linters (Neovim / IDE support)
  languageServers = with pkgs; [
    lua-language-server                     # Lua LSP
    stylua                                  # Lua formatter
    gopls                                   # Go LSP
    pyright                                 # Python LSP
    ruff                                    # Python fast linter / formatter
    nixd                                    # Nix LSP
    yaml-language-server                    # YAML LSP
    vscode-langservers-extracted            # HTML/CSS/JSON LSPs
    nodePackages.typescript-language-server  # TS/JS LSP
    clang-tools                             # C/C++ LSP (clangd)
    jdt-language-server                     # Java LSP (jdtls)
    omnisharp-roslyn                        # C# LSP
    sqls                                    # SQL LSP
    metals                                  # Scala LSP
    dart-bin                                # Dart SDK (includes LSP)
    kotlin-language-server                  # Kotlin LSP
    clojure-lsp                             # Clojure LSP
    haskell-language-server                 # Haskell LSP
    tree-sitter                             # Multi-lang parser
  ];

  # Daily CLI Productivity (Modern Replacements)
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
    meld                        # Visual diff / merge tool
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
    sshfs
    fuse3
    nmap
    tcpdump                     # Traffic analyzer
    ethtool
    iftop                       # Network bandwidth monitor
    iotop                       # I/O monitor
    dig
    mitmproxy                   # HTTP/HTTPS proxy
    cifs-utils
    tshark
    termshark
  ];

  # Security — CLI Tools
  securityCLI = with pkgs; [
    uv                          # Python package manager
    lynis                       # System audit
    sqlmap                      # SQL injection tool
    nikto                       # Web server scanner
    hcxtools                    # WiFi capture tools
    hashcat                     # Password recovery
    thc-hydra                   # Login cracker
    gobuster                    # Directory brute-forcer
    wireguard-tools             # VPN
    metasploit                  # Exploitation framework
    aircrack-ng                 # WiFi security
    dockle                      # Container security linter
    tracee                      # Runtime security
    apktool                     # Android reverse engineering
    radare2                     # Binary analysis
    ghidra-bin                  # Reverse engineering suite
    zap                         # OWASP ZAP proxy
    wapiti                      # Web vulnerability scanner
    nuclei                      # Template-based vulnerability scanner
    osv-scanner                 # Open Source vulnerability scanner
    secretscanner               # Secret detection
  ];

  # System Utilities / Libraries
  systemUtils = with pkgs; [
    fastfetch                   # System info (neofetch replacement)
    htop                        # Process monitor
    tree                        # Directory tree
    psmisc                      # Provides fuser, killall, pstree
    lsof                        # List open files
    inxi                        # System info (detailed)
    libnotify
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
    zlib
  ];

  # Browsers (for Antigravity browser subagent on auto-generated VMs)
  browsers = with pkgs; [
    google-chrome               # Google Chrome (used by Antigravity)
  ];

  # Multimedia (CLI tools only)
  multimediaCLI = with pkgs; [
    ffmpeg                      # Video/audio converter
  ];

  # Specialized Tools
  specializedTools = with pkgs; [
    android-tools               # Android development tools
    texlive.combined.scheme-medium  # LaTeX compiler
    tectonic                    # Modern LaTeX compiler
  ];

  # ────────────────────────────────────────────────────────────────────────────
  # Shell hook — banner + environment setup
  # ────────────────────────────────────────────────────────────────────────────

  devShellHook = ''
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  🚀 Dev Environment Ready!                              ║"
    echo "║                                                         ║"
    echo "║  Languages: Go, Rust, Python, Elixir, Ruby, TS/JS       ║"
    echo "║  DBs:       PostgreSQL, MySQL, SQLite, Redis, DuckDB    ║"
    echo "║  DevOps:    Docker, K8s, Terraform, Ansible, Helm       ║"
    echo "║  Cloud:     GCP, AWS, Oracle, DigitalOcean              ║"
    echo "║  AI/ML:     Ollama, Gemini, Aider, FastAPI              ║"
    echo "║  Tools:     bat, eza, fzf, ripgrep, lazygit, delta      ║"
    echo "║                                                         ║"
    echo "║  Run 'type <cmd>' to check any tool's availability      ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""

    # Antigravity — use Google Chrome for browser subagent interactions
    export BROWSER="google-chrome-stable"
    export CHROME_PATH="${pkgs.google-chrome}/bin/google-chrome-stable"
    export ANTIGRAVITY_BROWSER="$CHROME_PATH"

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
  # Composable profiles — use `nix-shell ubuntu-dev-env.nix -A <profile>`
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
    editors ++ terminals ++ dataAnalytics ++ dataEngineering
    ++ gitTools ++ cliProductivity ++ systemUtils
  );

  ai = mkShell "ai-ml-env" (
    editors ++ terminals ++ aiML ++ dataAnalytics
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
  # Usage: nix-shell ubuntu-dev-env.nix

  default = mkShell "full-dev-env" (
    editors
    ++ terminals
    ++ backendDev
    ++ frontendDev
    ++ devops
    ++ cloudCLIs
    ++ qaTools
    ++ dataAnalytics
    ++ dataEngineering
    ++ aiML
    ++ languageServers
    ++ cliProductivity
    ++ gitTools
    ++ networkingTools
    ++ securityCLI
    ++ systemUtils
    ++ browsers
    ++ multimediaCLI
    ++ specializedTools
  );
}
