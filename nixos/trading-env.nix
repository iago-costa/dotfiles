# Financial Trading Development Environment
# Usage: nix-shell /etc/nixos/trading-env.nix
#
# This shell provides everything needed for financial market development
# targeting B3 (Brazil) and USA markets.
#
# Includes:
#   - System-level C libraries (ta-lib, quantlib, boost)
#   - Python 3.12 with all available nixpkgs trading libraries
#   - A virtualenv for pip-installing packages NOT in nixpkgs:
#       pip install MetaTrader5 ib_insync backtrader vectorbt ccxt
#       pip install TA-Lib  (Python wrapper — C lib provided by nix)
#       pip install alpaca-trade-api fredapi alpha_vantage
#       pip install python-binance  (crypto on Binance)
#       pip install investpy  (B3 / investing.com data)
#
# MT5 Note: The MetaTrader5 Python package only works on Windows.
#   For Linux, use MT5 via Wine/Bottles and connect through MQL5 scripts,
#   or use a Windows VM with the MT5 Python API.

{ pkgs ? import <nixos-25.11> { config.allowUnfree = true; } }:

let
  pythonEnv = pkgs.python312.withPackages (ps: with ps; [
    # ── Market Data ──────────────────────────────────
    yfinance              # Yahoo Finance (stocks, ETFs, options, futures)
    mplfinance            # OHLCV / candlestick charting
    beautifulsoup4        # Web scraping (B3 announcements, SEC filings)
    lxml                  # Fast HTML/XML parser
    selenium              # Browser automation for broker portals
    tweepy                # Twitter/X API (sentiment analysis)
    arrow                 # Human-friendly datetime

    # ── Core Data Science ────────────────────────────
    pandas                # DataFrames
    numpy                 # Numerical computing
    scipy                 # Scientific computing (optimization, stats)
    scikit-learn          # Machine learning
    statsmodels           # Time-series, econometrics, ARIMA
    polars                # Fast DataFrames (Rust-based)

    # ── Visualization ────────────────────────────────
    matplotlib            # Plotting
    seaborn               # Statistical visualization
    plotly                # Interactive charts
    bokeh                 # Interactive web plots

    # ── Async / Real-Time ────────────────────────────
    websockets            # WebSocket protocol
    websocket-client      # WebSocket client
    aiohttp               # Async HTTP
    httpx                 # Modern HTTP client

    # ── Scheduling & Alerts ──────────────────────────
    schedule              # Lightweight job scheduler
    apscheduler           # Advanced scheduler (cron-like)
    python-telegram-bot   # Telegram trade alerts / bot
    pytz                  # Timezone handling

    # ── Data Export / Config ─────────────────────────
    openpyxl              # Excel read/write
    xlsxwriter            # Excel report generation
    pyyaml                # YAML config files
    requests              # HTTP client
    sqlalchemy            # Database ORM (trade logs)

    # ── ML / Prediction ──────────────────────────────
    # (already in system: jupyter, ipython)
    rich                  # Beautiful terminal output
    pydantic              # Data validation
    fastapi               # API framework
    uvicorn               # ASGI server

    # ── Dev Tools ────────────────────────────────────
    pip
    setuptools
    wheel
    virtualenv
  ]);
in
pkgs.mkShell {
  name = "trading-env";

  packages = [
    pythonEnv

    # System-level C/C++ libraries needed by pip packages
    pkgs.ta-lib               # TA-Lib C library (for: pip install TA-Lib)
    pkgs.quantlib             # QuantLib C++ lib
    pkgs.boost                # Boost (QuantLib dependency)

    # Build tools (for compiling C extensions)
    pkgs.gcc
    pkgs.cmake
    pkgs.pkg-config

    # Networking
    pkgs.curl
    pkgs.openssl
  ];

  shellHook = ''
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  💹 Financial Trading Dev Environment                   ║"
    echo "║  Markets: B3 (Brazil) • NYSE/NASDAQ (USA)              ║"
    echo "╠══════════════════════════════════════════════════════════╣"
    echo "║  Python: $(python --version 2>&1 | cut -d' ' -f2)                                        ║"
    echo "║  TA-Lib: ${pkgs.ta-lib.version}                                          ║"
    echo "║  QuantLib: ${pkgs.quantlib.version}                                        ║"
    echo "╠══════════════════════════════════════════════════════════╣"
    echo "║  pip packages NOT in nixpkgs (install in venv):        ║"
    echo "║    pip install TA-Lib backtrader vectorbt ccxt          ║"
    echo "║    pip install alpaca-trade-api investpy alpha_vantage  ║"
    echo "║    pip install ib_insync  (Interactive Brokers)         ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""

    # Create a venv if not exists (for pip-installing missing packages)
    if [ ! -d .venv ]; then
      echo "📦 Creating Python venv for pip packages..."
      python -m venv .venv --system-site-packages
    fi
    source .venv/bin/activate

    # Expose TA-Lib headers for pip install TA-Lib
    export TA_INCLUDE_PATH="${pkgs.ta-lib}/include"
    export TA_LIBRARY_PATH="${pkgs.ta-lib}/lib"
    export LD_LIBRARY_PATH="${pkgs.ta-lib}/lib:${pkgs.quantlib}/lib:$LD_LIBRARY_PATH"
  '';
}
